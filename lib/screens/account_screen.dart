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
                tooltip: 'Refresh status',
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
                        if (challenge != null) {
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
                                    ? 'Invite sent to ${result.member.email}.'
                                    : 'Invite created for ${result.member.email}. Demo code: ${result.accessGrant.demoAccessCode}',
                              ),
                            ),
                          );
                        },
                        onResend: (membershipId) =>
                            appState.resendOrganizationMemberAccess(
                              organizationId: organization.id,
                              membershipId: membershipId,
                            ),
                        onOpenPlans: () {
                          Navigator.pushNamed(context, AppRoutes.sales);
                        },
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
            if (authStart.demoCode.isNotEmpty) ...[
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
    required this.isRefreshing,
    required this.onRefresh,
    required this.onLogout,
    required this.onOpenPlans,
  });

  final BackendMeSnapshot me;
  final BackendEntitlementSnapshot? entitlement;
  final bool isRefreshing;
  final Future<void> Function() onRefresh;
  final Future<void> Function() onLogout;
  final VoidCallback onOpenPlans;

  @override
  Widget build(BuildContext context) {
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
            Text(
              'Access: ${_humanizeValue(entitlement?.accessState ?? me.activeEntitlement.accessState)}',
            ),
            Text(
              'Plan: ${_humanizePlanCode(entitlement?.planCode ?? me.activeEntitlement.planCode)}',
            ),
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
                  child: const Text('Plans and Billing'),
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
            Text(
              'Recovery',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            const Text(
              'If this phone is replaced, reset, or loses app data, sign in again with the same email. Business workspaces should keep at least one owner or admin active.',
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
        ? 'Create Another Workspace'
        : 'Create Workspace';
    final createOrganizationHelp = hasMemberships
        ? 'Use another organization if you need a separate company workspace or a different business subscription.'
        : 'Create the company workspace here before buying a business plan.';
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
                children: [const Text('No company workspaces yet.')],
              )
            else
              for (final membership in memberships) ...[
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(membership.organizationName),
                  subtitle: Text(
                    '${_humanizeMembershipRole(membership.role)} · ${membership.isAccepted ? 'Joined' : 'Invite pending'} · ${_humanizeSeatStatus(membership.seatStatus)}',
                  ),
                ),
                if (membership != memberships.last) const Divider(),
              ],
            const SizedBox(height: 12),
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
                decoration: const InputDecoration(labelText: 'Workspace Name'),
              ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: isBusy ? null : onCreateOrganization,
              child: Text(createOrganizationHeading),
            ),
            if (pendingMemberships.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                'Join Workspace from Invite',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 4),
              Text(
                'Use the workspace ID and invite code from the email.',
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
                decoration: const InputDecoration(labelText: 'Invite Code'),
              ),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: isBusy ? null : onRedeem,
                child: const Text('Join Workspace'),
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
    required this.onOpenPlans,
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
  final VoidCallback onOpenPlans;
  final Future<void> Function(String membershipId) onResend;
  final Future<void> Function(BackendOrganizationMemberSnapshot member)
  onToggleSeat;
  final Future<void> Function(String membershipId) onRemove;

  @override
  Widget build(BuildContext context) {
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
            Text(
              'Current plan: ${_humanizePlanCode(organization.planCode)}',
            ),
            Text(
              'Seats: ${organization.seatsAssigned}/${organization.seatLimit} assigned · Members: ${organization.userCount}',
            ),
            Text('Open seats: ${organization.seatsRemaining}'),
            const SizedBox(height: 8),
            const Text(
              'Owners and admins manage the company. Only give a report seat to someone who needs to create receiving reports.',
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: isBusy ? null : onOpenPlans,
              child: const Text('Upgrade or Change Plan'),
            ),
            const SizedBox(height: 16),
            Text(
              'Invite to Workspace',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 4),
            const Text(
              'Invite owners or admins only when they need to manage company settings. Report seats are assigned separately below.',
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
              child: const Text('Send Invite'),
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
                  '${_humanizeMembershipRole(member.role)} · ${member.acceptedAt == null ? 'Invite pending' : 'Joined'} · ${member.seatAssigned ? 'Report seat assigned' : 'No report seat'}',
                ),
              ),
              if ((member.activeDeviceSummary ?? '').trim().isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    'Last active device: ${member.activeDeviceSummary}',
                    style: Theme.of(context).textTheme.bodySmall,
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
                    child: const Text('Resend Invite'),
                  ),
                  OutlinedButton(
                    onPressed: isBusy ? null : () => onToggleSeat(member),
                    child: Text(
                      member.seatAssigned
                          ? 'Remove Report Seat'
                          : 'Give Report Seat',
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

String _humanizeValue(String value) {
  if (value.trim().isEmpty) {
    return 'None';
  }
  return value
      .split('_')
      .map(_titleCase)
      .join(' ');
}

String _humanizePlanCode(String? value) {
  if (value == null || value.trim().isEmpty) {
    return 'None';
  }
  return value
      .split('_')
      .where((part) => part.isNotEmpty && part != 'material' && part != 'guardian')
      .map(_titleCase)
      .join(' ');
}

String _humanizeMembershipRole(String value) {
  if (value == 'owner') {
    return 'Owner';
  }
  if (value == 'admin') {
    return 'Admin';
  }
  return 'Member';
}

String _humanizeSeatStatus(String value) {
  return switch (value) {
    'assigned' => 'Report seat assigned',
    'unassigned' => 'No report seat',
    'pending' => 'Seat pending',
    _ => _humanizeValue(value),
  };
}
