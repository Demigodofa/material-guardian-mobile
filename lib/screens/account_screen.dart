import 'package:flutter/material.dart';

import '../app/material_guardian_state.dart';
import '../services/backend_api_service.dart';
import '../services/store_purchase_service.dart';

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
        final plans = appState.backendPlans;
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
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _BackendStatusCard(appState: appState),
              const SizedBox(height: 16),
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
                    onReplace: () => appState.replacePendingBackendSession(),
                  ),
                ],
              ] else ...[
                _AccountSummaryCard(
                  me: me!,
                  entitlement: entitlement,
                  isRefreshing: appState.isRefreshingBackendAccount,
                  onRefresh: () => appState.refreshBackendAccount(),
                  onLogout: () => appState.logoutBackend(),
                ),
                const SizedBox(height: 16),
                _MembershipsCard(
                  memberships: me.memberships,
                  activeOrganization: organization,
                  organizationNameController: _organizationNameController,
                  organizationIdController: _redeemOrganizationIdController,
                  codeController: _redeemCodeController,
                  isBusy: appState.isAuthenticatingBackend,
                  onCreateOrganization: () =>
                      appState.createOrganization(
                        name: _organizationNameController.text,
                      ),
                  onRedeem: () => appState.redeemOrganizationAccess(
                    organizationId: _redeemOrganizationIdController.text,
                    code: _redeemCodeController.text,
                  ),
                ),
                const SizedBox(height: 16),
                _BillingCard(
                  plans: plans,
                  storeProductsById: appState.storeProductsById,
                  activeEntitlement: entitlement ?? me.activeEntitlement,
                  activeOrganization: organization,
                  isLoadingCatalog: appState.isLoadingPurchaseCatalog,
                  isPurchasing: appState.isPurchasing,
                  isStoreAvailable: appState.isStoreAvailable,
                  purchaseStatusMessage: appState.purchaseStatusMessage,
                  purchaseError: appState.purchaseError,
                  onLoadCatalog: () => appState.loadPurchaseCatalog(),
                  onRestorePurchases: () => appState.restorePurchases(),
                  onPurchasePlan: (planCode) =>
                      appState.purchasePlan(planCode: planCode),
                ),
                if (organization != null) ...[
                  const SizedBox(height: 16),
                  _OrganizationCard(
                    organization: organization,
                    inviteEmailController: _inviteEmailController,
                    inviteDisplayNameController: _inviteDisplayNameController,
                    inviteRole: _inviteRole,
                    isBusy: appState.isAuthenticatingBackend,
                    onInviteRoleChanged: (value) {
                      setState(() {
                        _inviteRole = value;
                      });
                    },
                    onInvite: () async {
                      final result = await appState.inviteOrganizationMember(
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
                                    result.accessGrant.demoAccessCode!.isEmpty
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
            TextField(
              controller: emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(labelText: 'Email'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: displayNameController,
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
  });

  final BackendMeSnapshot me;
  final BackendEntitlementSnapshot? entitlement;
  final bool isRefreshing;
  final Future<void> Function() onRefresh;
  final Future<void> Function() onLogout;

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
              'Access: ${entitlement?.accessState ?? me.activeEntitlement.accessState}',
            ),
            Text(
              'Plan: ${entitlement?.planCode ?? me.activeEntitlement.planCode ?? 'None'}',
            ),
            Text(
              'Session: ${me.activeSession?.deviceLabel ?? 'Unknown'} / ${me.activeSession?.platform ?? 'unknown'}',
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
              ],
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
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Memberships', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            if (memberships.isEmpty)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('No organization memberships yet.'),
                  const SizedBox(height: 12),
                  Text(
                    'Create an organization before buying a business plan.',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: organizationNameController,
                    decoration: const InputDecoration(
                      labelText: 'Organization Name',
                    ),
                  ),
                  const SizedBox(height: 12),
                  FilledButton(
                    onPressed: isBusy ? null : onCreateOrganization,
                    child: const Text('Create Organization'),
                  ),
                ],
              )
            else
              for (final membership in memberships) ...[
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(membership.organizationName),
                  subtitle: Text(
                    '${membership.role} | seat: ${membership.seatStatus} | ${membership.isAccepted ? 'accepted' : 'pending'}',
                  ),
                ),
                if (membership != memberships.last) const Divider(),
              ],
            if (activeOrganization != null) ...[
              const SizedBox(height: 12),
              Text(
                'Active organization: ${activeOrganization!.name} (${activeOrganization!.id})',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
            if (pendingMemberships.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                'Redeem Organization Access Code',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 8),
              TextField(
                controller: organizationIdController,
                decoration: const InputDecoration(labelText: 'Organization ID'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: codeController,
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

class _BillingCard extends StatelessWidget {
  const _BillingCard({
    required this.plans,
    required this.storeProductsById,
    required this.activeEntitlement,
    required this.activeOrganization,
    required this.isLoadingCatalog,
    required this.isPurchasing,
    required this.isStoreAvailable,
    required this.purchaseStatusMessage,
    required this.purchaseError,
    required this.onLoadCatalog,
    required this.onRestorePurchases,
    required this.onPurchasePlan,
  });

  final List<BackendPlanSnapshot> plans;
  final Map<String, StoreProductSnapshot> storeProductsById;
  final BackendEntitlementSnapshot activeEntitlement;
  final BackendOrganizationSummary? activeOrganization;
  final bool isLoadingCatalog;
  final bool isPurchasing;
  final bool isStoreAvailable;
  final String? purchaseStatusMessage;
  final String? purchaseError;
  final Future<void> Function() onLoadCatalog;
  final Future<void> Function() onRestorePurchases;
  final Future<void> Function(String planCode) onPurchasePlan;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Plans & Billing', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(
              'Current access: ${activeEntitlement.accessState} | Plan: ${activeEntitlement.planCode ?? 'None'}',
            ),
            if (activeEntitlement.accessState == 'trial')
              Text('Free jobs remaining: ${activeEntitlement.trialRemaining}'),
            if (activeOrganization != null)
              Text(
                'Business org: ${activeOrganization!.name} | Seats: ${activeOrganization!.seatsAssigned}/${activeOrganization!.seatLimit}',
              ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                FilledButton(
                  onPressed: isLoadingCatalog ? null : onLoadCatalog,
                  child: const Text('Load Plans'),
                ),
                OutlinedButton(
                  onPressed: (!isStoreAvailable || isPurchasing)
                      ? null
                      : onRestorePurchases,
                  child: const Text('Restore Purchases'),
                ),
              ],
            ),
            if (purchaseStatusMessage != null &&
                purchaseStatusMessage!.trim().isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(purchaseStatusMessage!),
            ],
            if (purchaseError != null && purchaseError!.trim().isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(
                purchaseError!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
            const SizedBox(height: 12),
            if (plans.isEmpty)
              const Text('Load the billing catalog to see available plans.')
            else
              for (final plan in plans) ...[
                _PlanTile(
                  plan: plan,
                  storeProduct: storeProductsById[
                    Theme.of(context).platform == TargetPlatform.iOS
                        ? (plan.appleStoreProductId ?? '')
                        : (plan.googleStoreProductId ?? '')
                  ],
                  isBusy: isPurchasing,
                  activeOrganization: activeOrganization,
                  onPurchase: () => onPurchasePlan(plan.planCode),
                ),
                if (plan != plans.last) const Divider(),
              ],
          ],
        ),
      ),
    );
  }
}

class _PlanTile extends StatelessWidget {
  const _PlanTile({
    required this.plan,
    required this.storeProduct,
    required this.isBusy,
    required this.activeOrganization,
    required this.onPurchase,
  });

  final BackendPlanSnapshot plan;
  final StoreProductSnapshot? storeProduct;
  final bool isBusy;
  final BackendOrganizationSummary? activeOrganization;
  final Future<void> Function() onPurchase;

  @override
  Widget build(BuildContext context) {
    final requiresOrganization = plan.isBusiness;
    final canPurchase =
        storeProduct != null &&
        (!requiresOrganization || activeOrganization != null) &&
        !isBusy;

    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text('${plan.audienceType} ${plan.billingInterval}'),
      subtitle: Text(
        [
          'Backend: ${plan.displayPrice}',
          if (storeProduct != null) 'Store: ${storeProduct!.price}',
          'Seats: ${plan.seatLimit}',
          if (requiresOrganization && activeOrganization == null)
            'Create an organization first for business checkout',
        ].join(' | '),
      ),
      trailing: FilledButton(
        onPressed: canPurchase ? onPurchase : null,
        child: const Text('Buy'),
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
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Organization Admin',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(organization.name),
            Text(
              'Plan: ${organization.planCode ?? 'None'} | Seats: ${organization.seatsAssigned}/${organization.seatLimit} assigned',
            ),
            Text('Members: ${organization.userCount}'),
            const SizedBox(height: 16),
            Text(
              'Invite Member',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            TextField(
              controller: inviteEmailController,
              decoration: const InputDecoration(labelText: 'Invite Email'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: inviteDisplayNameController,
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
                  '${member.role} | seat: ${member.seatAssigned ? 'assigned' : 'unassigned'} | ${member.acceptedAt == null ? 'pending' : 'accepted'}',
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
