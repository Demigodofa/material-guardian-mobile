import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../app/material_guardian_state.dart';
import '../app/routes.dart';
import '../services/backend_api_service.dart';
import '../util/formatting.dart';

class AccountScreen extends StatefulWidget {
  const AccountScreen({required this.appState, super.key});

  final MaterialGuardianAppState appState;

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  final _emailController = TextEditingController();
  final _displayNameController = TextEditingController();
  final _codeController = TextEditingController();
  final _organizationNameController = TextEditingController();
  final _redeemOrganizationIdController = TextEditingController();
  final _redeemCodeController = TextEditingController();
  final _inviteEmailController = TextEditingController();
  final _inviteDisplayNameController = TextEditingController();

  String _inviteRole = 'member';

  MaterialGuardianAppState get appState => widget.appState;

  @override
  void dispose() {
    _emailController.dispose();
    _displayNameController.dispose();
    _codeController.dispose();
    _organizationNameController.dispose();
    _redeemOrganizationIdController.dispose();
    _redeemCodeController.dispose();
    _inviteEmailController.dispose();
    _inviteDisplayNameController.dispose();
    super.dispose();
  }

  Future<void> _confirmDeleteAccount() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Delete Account'),
          content: const Text(
            'This removes your Material Guardian account access on the backend and signs this device out. If Google Play or the App Store still shows an active subscription, cancel it there too. Workspace owners must first remove accepted teammates.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Keep Account'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Delete Account'),
            ),
          ],
        );
      },
    );
    if (confirmed != true) {
      return;
    }

    final result = await appState.deleteBackendAccount();
    if (!mounted || result == null) {
      return;
    }

    final message =
        result.storeSubscriptionActionMessage ??
        'Your account was deleted from Material Guardian.';
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: appState,
      builder: (context, _) {
        final me = appState.backendMe;
        final entitlement = appState.backendEntitlement;
        final organization = appState.backendOrganization;
        final pendingAuth = appState.pendingBackendAuthStart;
        final conflict = appState.pendingSessionConflict;

        return Scaffold(
          appBar: AppBar(
            title: const Text('Account'),
            actions: [
              IconButton(
                tooltip: 'Refresh backend health',
                onPressed: appState.isCheckingBackendHealth
                    ? null
                    : () => appState.refreshBackendHealth(),
                icon: const Icon(Icons.cloud_sync_outlined),
              ),
            ],
          ),
          body: SafeArea(
            top: false,
            minimum: const EdgeInsets.only(bottom: 12),
            child: centeredContent(
              child: ListView(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
                children: [
                  if (!kReleaseMode) ...[
                    _BackendStatusCard(appState: appState),
                    const SizedBox(height: 16),
                  ],
                  if (appState.backendAccountError != null &&
                      appState.backendAccountError!.trim().isNotEmpty) ...[
                    _ErrorCard(message: appState.backendAccountError!),
                    const SizedBox(height: 16),
                  ],
                  if (!appState.isSignedIn) ...[
                    _SignInCard(
                      emailController: _emailController,
                      displayNameController: _displayNameController,
                      onStartSignIn: () async {
                        await appState.startBackendSignIn(
                          email: _emailController.text,
                          displayName: _displayNameController.text,
                        );
                        if (!context.mounted) {
                          return;
                        }
                        final challenge = appState.pendingBackendAuthStart;
                        if (!kReleaseMode && challenge != null) {
                          _codeController.text = challenge.demoCode;
                        }
                      },
                      isBusy: appState.isAuthenticatingBackend,
                    ),
                    if (pendingAuth != null) ...[
                      const SizedBox(height: 16),
                      _CodeVerificationCard(
                        authStart: pendingAuth,
                        codeController: _codeController,
                        isBusy: appState.isAuthenticatingBackend,
                        onComplete: () async {
                          await appState.completeBackendSignIn(
                            code: _codeController.text,
                          );
                        },
                      ),
                    ],
                    if (conflict != null &&
                        appState.hasPendingSessionReplacement) ...[
                      const SizedBox(height: 16),
                      _SessionReplacementCard(
                        conflict: conflict,
                        isBusy: appState.isAuthenticatingBackend,
                        onReplace: () =>
                            appState.replacePendingBackendSession(),
                      ),
                    ],
                  ] else ...[
                    _AccountSummaryCard(
                      me: me!,
                      entitlement: entitlement,
                      activeOrganization: organization,
                      isRefreshing: appState.isRefreshingBackendAccount,
                      onRefresh: () => appState.refreshBackendAccount(),
                      onLogout: () => appState.logoutBackend(),
                      onOpenPlans: () {
                        Navigator.pushNamed(context, AppRoutes.sales);
                      },
                    ),
                    const SizedBox(height: 16),
                    const _RecoveryHelpCard(),
                    const SizedBox(height: 16),
                    _MembershipsCard(
                      memberships: me.memberships,
                      activeOrganization: organization,
                      organizationNameController: _organizationNameController,
                      organizationIdController: _redeemOrganizationIdController,
                      codeController: _redeemCodeController,
                      isBusy: appState.isAuthenticatingBackend,
                      onCreateOrganization: () async {
                        await appState.createOrganization(
                          name: _organizationNameController.text,
                        );
                        if (!context.mounted ||
                            appState.backendAccountError != null) {
                          return;
                        }
                        _organizationNameController.clear();
                      },
                      onRedeem: () async {
                        await appState.redeemOrganizationAccess(
                          organizationId: _redeemOrganizationIdController.text,
                          code: _redeemCodeController.text,
                        );
                        if (!context.mounted ||
                            appState.backendAccountError != null) {
                          return;
                        }
                        _redeemOrganizationIdController.clear();
                        _redeemCodeController.clear();
                      },
                    ),
                    if (organization != null) ...[
                      const SizedBox(height: 16),
                      _OrganizationCard(
                        organization: organization,
                        inviteEmailController: _inviteEmailController,
                        inviteDisplayNameController:
                            _inviteDisplayNameController,
                        inviteRole: _inviteRole,
                        isBusy: appState.isAuthenticatingBackend,
                        onInviteRoleChanged: (value) {
                          setState(() {
                            _inviteRole = value;
                          });
                        },
                        onInvite: () async {
                          final result = await appState
                              .inviteOrganizationMember(
                                organizationId: organization.id,
                                email: _inviteEmailController.text,
                                displayName: _inviteDisplayNameController.text,
                                role: _inviteRole,
                              );
                          if (!context.mounted || result == null) {
                            return;
                          }
                          _inviteEmailController.clear();
                          _inviteDisplayNameController.clear();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                result.accessGrant.demoAccessCode == null ||
                                        result
                                            .accessGrant
                                            .demoAccessCode!
                                            .isEmpty
                                    ? 'Invite sent to ${result.member.email}. Ask them to install Material Guardian from Google Play if needed, sign in with the same email, then redeem the organization access code.'
                                    : 'Invite created for ${result.member.email}. Demo code: ${result.accessGrant.demoAccessCode}. Ask them to install Material Guardian from Google Play if needed, sign in with the same email, then redeem the organization access code.',
                              ),
                            ),
                          );
                        },
                        onResend: (membershipId) =>
                            appState.resendOrganizationMemberAccess(
                              organizationId: organization.id,
                              membershipId: membershipId,
                            ),
                        onToggleSeat: (membership) =>
                            appState.updateOrganizationMemberSeat(
                              organizationId: organization.id,
                              membershipId: membership.membershipId,
                              assignSeat: !membership.seatAssigned,
                            ),
                        onRemove: (membershipId) =>
                            appState.removeOrganizationMember(
                              organizationId: organization.id,
                              membershipId: membershipId,
                            ),
                      ),
                    ],
                    const SizedBox(height: 16),
                    _DangerZoneCard(
                      isBusy: appState.isAuthenticatingBackend,
                      onDeleteAccount: _confirmDeleteAccount,
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _BackendStatusCard extends StatelessWidget {
  const _BackendStatusCard({required this.appState});

  final MaterialGuardianAppState appState;

  @override
  Widget build(BuildContext context) {
    final health = appState.backendHealth;
    final error = appState.backendHealthError;
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Backend', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            SelectableText(
              appState.backendBaseUrl,
              style: theme.textTheme.bodySmall,
            ),
            const SizedBox(height: 10),
            if (health != null)
              Text(
                'Status: ${health.status} | Mode: ${health.mode} | Service: ${health.service}',
              )
            else if (error != null)
              Text(error, style: TextStyle(color: theme.colorScheme.error))
            else
              const Text('Backend health has not been checked yet.'),
          ],
        ),
      ),
    );
  }
}

class _SignInCard extends StatelessWidget {
  const _SignInCard({
    required this.emailController,
    required this.displayNameController,
    required this.onStartSignIn,
    required this.isBusy,
  });

  final TextEditingController emailController;
  final TextEditingController displayNameController;
  final Future<void> Function() onStartSignIn;
  final bool isBusy;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Sign In', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            const Text(
              'Use the same email on every device. A new device or cleared app data just means you request a fresh email code.',
            ),
            const SizedBox(height: 12),
            TextField(
              controller: emailController,
              keyboardType: TextInputType.emailAddress,
              autocorrect: false,
              enableSuggestions: false,
              textInputAction: TextInputAction.next,
              inputFormatters: [LengthLimitingTextInputFormatter(120)],
              decoration: const InputDecoration(labelText: 'Email'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: displayNameController,
              textInputAction: TextInputAction.done,
              inputFormatters: [LengthLimitingTextInputFormatter(40)],
              decoration: const InputDecoration(
                labelText: 'Display Name (optional)',
              ),
            ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: isBusy ? null : onStartSignIn,
              child: const Text('Send Sign-In Code'),
            ),
          ],
        ),
      ),
    );
  }
}

class _CodeVerificationCard extends StatelessWidget {
  const _CodeVerificationCard({
    required this.authStart,
    required this.codeController,
    required this.isBusy,
    required this.onComplete,
  });

  final BackendAuthStartSnapshot authStart;
  final TextEditingController codeController;
  final bool isBusy;
  final Future<void> Function() onComplete;

  @override
  Widget build(BuildContext context) {
    final expiresAt = authStart.expiresAt?.toLocal().toString() ?? 'unknown';
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Enter Sign-In Code',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text('Delivery target: ${authStart.deliveryTarget}'),
            Text('Expires: $expiresAt'),
            if (!kReleaseMode && authStart.demoCode.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                'Dev code: ${authStart.demoCode}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
            const SizedBox(height: 12),
            TextField(
              controller: codeController,
              keyboardType: TextInputType.number,
              textInputAction: TextInputAction.done,
              inputFormatters: [LengthLimitingTextInputFormatter(12)],
              decoration: const InputDecoration(labelText: 'Code'),
            ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: isBusy ? null : onComplete,
              child: const Text('Complete Sign-In'),
            ),
          ],
        ),
      ),
    );
  }
}

class _SessionReplacementCard extends StatelessWidget {
  const _SessionReplacementCard({
    required this.conflict,
    required this.isBusy,
    required this.onReplace,
  });

  final BackendSessionConflictSnapshot conflict;
  final bool isBusy;
  final Future<void> Function() onReplace;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Replace Existing Session',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Active device: ${conflict.activeDeviceLabel} (${conflict.activePlatform})',
            ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: isBusy ? null : onReplace,
              child: const Text('Replace Other Session'),
            ),
          ],
        ),
      ),
    );
  }
}

class _AccountSummaryCard extends StatelessWidget {
  const _AccountSummaryCard({
    required this.me,
    required this.entitlement,
    required this.activeOrganization,
    required this.isRefreshing,
    required this.onRefresh,
    required this.onLogout,
    required this.onOpenPlans,
  });

  final BackendMeSnapshot me;
  final BackendEntitlementSnapshot? entitlement;
  final BackendOrganizationSummary? activeOrganization;
  final bool isRefreshing;
  final Future<void> Function() onRefresh;
  final Future<void> Function() onLogout;
  final VoidCallback onOpenPlans;

  @override
  Widget build(BuildContext context) {
    final accessLabel = _friendlyAccessLabel(
      entitlement?.accessState ?? me.activeEntitlement.accessState,
    );
    final planLabel = _friendlyPlanLabel(
      entitlement?.planCode ?? me.activeEntitlement.planCode,
    );
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Account', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(me.user.email),
            if (me.user.displayName.trim().isNotEmpty)
              Text(me.user.displayName),
            const SizedBox(height: 8),
            Text('Access status: $accessLabel'),
            Text('Current plan: $planLabel'),
            if (activeOrganization != null) ...[
              const SizedBox(height: 4),
              Text('Workspace: ${activeOrganization!.name}'),
            ] else ...[
              const SizedBox(height: 4),
              const Text(
                'Solo access stays tied to this personal account until you create a company workspace.',
              ),
            ],
            const SizedBox(height: 4),
            Text(
              'This device stays signed in until you sign out or clear app data.',
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                FilledButton(
                  onPressed: isRefreshing ? null : onRefresh,
                  child: const Text('Refresh Account'),
                ),
                OutlinedButton(
                  onPressed: isRefreshing ? null : onLogout,
                  child: const Text('Sign Out'),
                ),
                OutlinedButton(
                  onPressed: isRefreshing ? null : onOpenPlans,
                  child: const Text('Plans'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _RecoveryHelpCard extends StatelessWidget {
  const _RecoveryHelpCard();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Recovery', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            const Text(
              'If this phone is replaced, reset, or loses app data, sign back in with the same email and a fresh code. Business teams should keep at least one trusted admin active.',
            ),
          ],
        ),
      ),
    );
  }
}

class _MembershipsCard extends StatelessWidget {
  const _MembershipsCard({
    required this.memberships,
    required this.activeOrganization,
    required this.organizationNameController,
    required this.organizationIdController,
    required this.codeController,
    required this.isBusy,
    required this.onCreateOrganization,
    required this.onRedeem,
  });

  final List<BackendMembershipSummary> memberships;
  final BackendOrganizationSummary? activeOrganization;
  final TextEditingController organizationNameController;
  final TextEditingController organizationIdController;
  final TextEditingController codeController;
  final bool isBusy;
  final Future<void> Function() onCreateOrganization;
  final Future<void> Function() onRedeem;

  @override
  Widget build(BuildContext context) {
    final pendingMemberships = memberships.where((item) => !item.isAccepted);
    final hasMemberships = memberships.isNotEmpty;
    final createOrganizationHeading = hasMemberships
        ? 'Need another company workspace?'
        : 'Set Up Company Workspace';
    final createOrganizationHelp = hasMemberships
        ? 'Most owners only need one. Create another only when it should have separate billing, seats, or a separate company identity.'
        : 'Business plans attach to a company workspace. Set the company name here before buying Business. Solo plans do not require this step.';
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Company Workspaces',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            if (!hasMemberships)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text('No company workspaces yet.'),
                  SizedBox(height: 4),
                  Text(
                    'Individual access already works on this personal account. Create a company workspace only if you want the Business plan.',
                  ),
                ],
              )
            else
              for (final membership in memberships) ...[
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(membership.organizationName),
                  subtitle: Text(
                    '${_titleCase(membership.role)} - ${_titleCase(membership.seatStatus)} seat - ${membership.isAccepted ? 'Accepted' : 'Pending'}',
                  ),
                  trailing: activeOrganization != null &&
                          membership.organizationId == activeOrganization!.id
                      ? const Icon(Icons.check_circle_outline)
                      : null,
                ),
                if (membership != memberships.last) const Divider(),
              ],
            const SizedBox(height: 12),
            if (!hasMemberships) ...[
              Text(
                createOrganizationHeading,
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 8),
              Text(
                createOrganizationHelp,
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 8),
              TextField(
                controller: organizationNameController,
                textInputAction: TextInputAction.done,
                inputFormatters: [LengthLimitingTextInputFormatter(60)],
                decoration: const InputDecoration(
                  labelText: 'Company Workspace Name',
                ),
              ),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: isBusy ? null : onCreateOrganization,
                child: Text(createOrganizationHeading),
              ),
            ] else ...[
              ExpansionTile(
                tilePadding: EdgeInsets.zero,
                childrenPadding: const EdgeInsets.only(top: 8),
                title: Text(
                  createOrganizationHeading,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                children: [
                  Text(
                    createOrganizationHelp,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: organizationNameController,
                    textInputAction: TextInputAction.done,
                    inputFormatters: [LengthLimitingTextInputFormatter(60)],
                    decoration: const InputDecoration(
                      labelText: 'New Company Workspace Name',
                    ),
                  ),
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: FilledButton(
                      onPressed: isBusy ? null : onCreateOrganization,
                      child: const Text('Create New Workspace'),
                    ),
                  ),
                ],
              ),
            ],
            if (pendingMemberships.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                'Join a Company Workspace',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 4),
              Text(
                'Use the organization ID and access code from the invite email. If this phone does not have Material Guardian yet, download it from Google Play first.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 8),
              TextField(
                controller: organizationIdController,
                textInputAction: TextInputAction.next,
                inputFormatters: [LengthLimitingTextInputFormatter(64)],
                decoration: const InputDecoration(labelText: 'Workspace ID'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: codeController,
                textInputAction: TextInputAction.done,
                inputFormatters: [LengthLimitingTextInputFormatter(24)],
                decoration: const InputDecoration(labelText: 'Access Code'),
              ),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: isBusy ? null : onRedeem,
                child: const Text('Redeem Access Code'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _OrganizationCard extends StatelessWidget {
  const _OrganizationCard({
    required this.organization,
    required this.inviteEmailController,
    required this.inviteDisplayNameController,
    required this.inviteRole,
    required this.isBusy,
    required this.onInviteRoleChanged,
    required this.onInvite,
    required this.onResend,
    required this.onToggleSeat,
    required this.onRemove,
  });

  final BackendOrganizationSummary organization;
  final TextEditingController inviteEmailController;
  final TextEditingController inviteDisplayNameController;
  final String inviteRole;
  final bool isBusy;
  final ValueChanged<String> onInviteRoleChanged;
  final Future<void> Function() onInvite;
  final Future<void> Function(String membershipId) onResend;
  final Future<void> Function(BackendOrganizationMemberSnapshot member)
  onToggleSeat;
  final Future<void> Function(String membershipId) onRemove;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              organization.name,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: scheme.secondaryContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Plan: ${_friendlyPlanLabel(organization.planCode)}',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: scheme.onSecondaryContainer,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Seats: ${organization.seatsAssigned}/${organization.seatLimit} assigned - Members: ${organization.userCount}',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: scheme.onSecondaryContainer,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Admins can manage the company without using a report seat. Assign seats only to people who should create receiving reports.',
            ),
            const SizedBox(height: 16),
            Text(
              'Invite Member',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            TextField(
              controller: inviteEmailController,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              inputFormatters: [LengthLimitingTextInputFormatter(120)],
              decoration: const InputDecoration(labelText: 'Invite Email'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: inviteDisplayNameController,
              textInputAction: TextInputAction.next,
              inputFormatters: [LengthLimitingTextInputFormatter(40)],
              decoration: const InputDecoration(
                labelText: 'Display Name (optional)',
              ),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              initialValue: inviteRole,
              items: const [
                DropdownMenuItem(value: 'member', child: Text('Member')),
                DropdownMenuItem(value: 'admin', child: Text('Admin')),
              ],
              onChanged: isBusy
                  ? null
                  : (value) {
                      if (value != null) {
                        onInviteRoleChanged(value);
                      }
                    },
              decoration: const InputDecoration(labelText: 'Role'),
            ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: isBusy ? null : onInvite,
              child: const Text('Invite Member'),
            ),
            const SizedBox(height: 8),
            const Text(
              'Invite emails should send people into the same email sign-in flow first. If they do not have the app yet, have them download Material Guardian from Google Play before redeeming the organization code.',
            ),
            const SizedBox(height: 16),
            Text(
              'Current Members',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            for (final member in organization.members) ...[
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(member.name.isEmpty ? member.email : member.name),
                subtitle: Text(
                  '${_titleCase(member.role)} - ${member.seatAssigned ? 'Seat assigned' : 'No seat'} - ${member.acceptedAt == null ? 'Pending' : 'Accepted'}',
                ),
              ),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  OutlinedButton(
                    onPressed: isBusy
                        ? null
                        : () => onResend(member.membershipId),
                    child: const Text('Resend'),
                  ),
                  OutlinedButton(
                    onPressed: isBusy ? null : () => onToggleSeat(member),
                    child: Text(
                      member.seatAssigned ? 'Remove Seat' : 'Assign Seat',
                    ),
                  ),
                  OutlinedButton(
                    onPressed: isBusy
                        ? null
                        : () => onRemove(member.membershipId),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Theme.of(context).colorScheme.error,
                    ),
                    child: const Text('Remove'),
                  ),
                ],
              ),
              if (member != organization.members.last)
                const Divider(height: 24),
            ],
          ],
        ),
      ),
    );
  }
}

class _DangerZoneCard extends StatelessWidget {
  const _DangerZoneCard({required this.isBusy, required this.onDeleteAccount});

  final bool isBusy;
  final Future<void> Function() onDeleteAccount;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Card(
      color: colorScheme.errorContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Danger Zone',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: colorScheme.onErrorContainer,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Delete your account only when you want to remove this login from Material Guardian. If store billing is still active, cancel it in Google Play or the App Store too. Workspace owners may need to transfer ownership or cancel the active business subscription first.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: colorScheme.onErrorContainer,
              ),
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: isBusy ? null : onDeleteAccount,
              style: OutlinedButton.styleFrom(
                backgroundColor: Colors.transparent,
                foregroundColor: colorScheme.onErrorContainer,
                side: BorderSide(color: colorScheme.onErrorContainer),
              ),
              child: const Text('Delete Account'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  const _ErrorCard({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Card(
      color: colorScheme.errorContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Text(
          message,
          style: TextStyle(color: colorScheme.onErrorContainer),
        ),
      ),
    );
  }
}

String _titleCase(String value) {
  if (value.isEmpty) {
    return value;
  }
  return '${value[0].toUpperCase()}${value.substring(1)}';
}

String _friendlyAccessLabel(String accessState) {
  switch (accessState) {
    case 'paid':
      return 'Paid';
    case 'trial':
      return 'Trial';
    case 'locked':
      return 'Locked';
    default:
      return _titleCase(accessState);
  }
}

String _friendlyPlanLabel(String? planCode) {
  switch (planCode) {
    case 'material_guardian_individual_monthly':
      return 'Individual Monthly';
    case 'material_guardian_individual_yearly':
      return 'Individual Yearly';
    case 'material_guardian_business_5_monthly':
      return 'Business 5 Seats Monthly';
    case 'material_guardian_business_5_yearly':
      return 'Business 5 Seats Yearly';
    case null:
    case '':
      return 'None yet';
    default:
      return planCode;
  }
}
