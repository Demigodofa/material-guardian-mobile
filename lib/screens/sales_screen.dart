import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../app/brand_assets.dart';
import '../app/material_guardian_state.dart';
import '../app/routes.dart';
import '../services/backend_api_service.dart';
import '../util/formatting.dart';

class SalesScreen extends StatefulWidget {
  const SalesScreen({required this.appState, super.key});

  final MaterialGuardianAppState appState;

  @override
  State<SalesScreen> createState() => _SalesScreenState();
}

class _SalesScreenState extends State<SalesScreen> {
  final _emailController = TextEditingController();
  final _displayNameController = TextEditingController();
  final _codeController = TextEditingController();
  var _showPlanOptionsForActiveSubscription = false;

  MaterialGuardianAppState get appState => widget.appState;

  @override
  void initState() {
    super.initState();
    if (appState.backendPlans.isEmpty && !appState.isLoadingPurchaseCatalog) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        appState.loadPurchaseCatalog();
      });
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _displayNameController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: appState,
      builder: (context, _) {
        final pendingAuth = appState.pendingBackendAuthStart;
        final conflict = appState.pendingSessionConflict;
        final entitlement =
            appState.effectiveBackendEntitlement ??
            appState.backendMe?.activeEntitlement;
        final isSignedIn = appState.isSignedIn;
        final baseListPadding = screenListPadding(context);
        final listPadding = baseListPadding.copyWith(
          bottom: baseListPadding.bottom + 96,
        );

        return Scaffold(
          appBar: AppBar(title: const Text('Plans')),
          body: SafeArea(
            child: centeredContent(
              child: ListView(
                padding: listPadding,
                children: [
                  const SizedBox(height: 4),
                  const _SalesLogo(),
                  const SizedBox(height: 12),
                  _HeroCard(
                    isSignedIn: isSignedIn,
                    trialRemaining: entitlement?.trialRemaining ?? 6,
                    accessState: entitlement?.accessState,
                  ),
                  if (appState.backendAccountError != null &&
                      appState.backendAccountError!.trim().isNotEmpty) ...[
                    const SizedBox(height: 16),
                    _ErrorText(message: appState.backendAccountError!),
                  ],
                  if (!isSignedIn) ...[
                    const SizedBox(height: 16),
                    _StartTrialCard(
                      emailController: _emailController,
                      displayNameController: _displayNameController,
                      isBusy: appState.isAuthenticatingBackend,
                      onStart: () async {
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
                    ),
                    if (pendingAuth != null) ...[
                      const SizedBox(height: 16),
                      _VerifyCodeCard(
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
                      _ReplaceSessionCard(
                        conflict: conflict,
                        isBusy: appState.isAuthenticatingBackend,
                        onReplace: () =>
                            appState.replacePendingBackendSession(),
                      ),
                    ],
                  ] else ...[
                    const SizedBox(height: 16),
                    _SignedInStatusCard(
                      appState: appState,
                      onOpenJobs: () {
                        Navigator.popUntil(context, (route) => route.isFirst);
                      },
                      onOpenAccount: () {
                        Navigator.pushNamed(context, AppRoutes.account);
                      },
                    ),
                  ],
                  const SizedBox(height: 16),
                  const _HowPlansWorkCard(),
                  const SizedBox(height: 16),
                  _PlansCard(
                    appState: appState,
                    showPlanOptionsForActiveSubscription:
                        _showPlanOptionsForActiveSubscription,
                    onTogglePlanOptions: () {
                      setState(() {
                        _showPlanOptionsForActiveSubscription =
                            !_showPlanOptionsForActiveSubscription;
                      });
                    },
                  ),
                  if (!isSignedIn) ...[
                    const SizedBox(height: 16),
                    const _ReturningUserCard(),
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

class _SalesLogo extends StatelessWidget {
  const _SalesLogo();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Image.asset(
        BrandAssets.materialGuardianLogo512,
        width: 96,
        height: 96,
        fit: BoxFit.contain,
      ),
    );
  }
}

class _HeroCard extends StatelessWidget {
  const _HeroCard({
    required this.isSignedIn,
    required this.trialRemaining,
    required this.accessState,
  });

  final bool isSignedIn;
  final int trialRemaining;
  final String? accessState;

  @override
  Widget build(BuildContext context) {
    final title = isSignedIn
        ? 'Your plan and workspace access'
        : 'Start free with 6 jobs';
    final subtitle = isSignedIn
        ? 'Check what this account already has, then go back to work or upgrade only if you need more access.'
        : 'Verify your email once, use 6 jobs free, and upgrade only if the app earns a place in your workflow.';
    final trialLine = isSignedIn && accessState == 'trial'
        ? 'You still have $trialRemaining free jobs remaining on this account.'
        : 'Plans control account access, company ownership, and report seats. Your receiving workflow stays the same.';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(subtitle),
            const SizedBox(height: 8),
            Text(
              trialLine,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}

class _HowPlansWorkCard extends StatelessWidget {
  const _HowPlansWorkCard();

  @override
  Widget build(BuildContext context) {
    const bullets = [
      'Individual is for one person running the app and reports under a single account.',
      'Business adds a company workspace with shared branding, defaults, and assignable report seats.',
      'Owners and admins manage the company. Seats are only for people who need to create receiving reports.',
      'You can upgrade later if you need more seats or a different billing option.',
    ];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'How It Works',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            for (final bullet in bullets) ...[
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(top: 2),
                    child: Text('- '),
                  ),
                  Expanded(child: Text(bullet)),
                ],
              ),
              const SizedBox(height: 6),
            ],
          ],
        ),
      ),
    );
  }
}

class _StartTrialCard extends StatelessWidget {
  const _StartTrialCard({
    required this.emailController,
    required this.displayNameController,
    required this.isBusy,
    required this.onStart,
  });

  final TextEditingController emailController;
  final TextEditingController displayNameController;
  final bool isBusy;
  final Future<void> Function() onStart;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Start Free Trial',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            const Text(
              'Enter the email you want tied to this account. The email code is the verification step, so there is no password to remember.',
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
              decoration: const InputDecoration(labelText: 'Name (optional)'),
            ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: isBusy ? null : onStart,
              child: const Text('Send Email Code'),
            ),
          ],
        ),
      ),
    );
  }
}

class _VerifyCodeCard extends StatelessWidget {
  const _VerifyCodeCard({
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
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Enter Your Code',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text('Sent to: ${authStart.deliveryTarget}'),
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
              child: const Text('Finish Sign-In'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReplaceSessionCard extends StatelessWidget {
  const _ReplaceSessionCard({
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

class _SignedInStatusCard extends StatelessWidget {
  const _SignedInStatusCard({
    required this.appState,
    required this.onOpenJobs,
    required this.onOpenAccount,
  });

  final MaterialGuardianAppState appState;
  final VoidCallback onOpenJobs;
  final VoidCallback onOpenAccount;

  @override
  Widget build(BuildContext context) {
    final me = appState.backendMe!;
    final entitlement =
        appState.effectiveBackendEntitlement ?? me.activeEntitlement;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Signed In', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(me.user.email),
            if (me.user.displayName.trim().isNotEmpty)
              Text(me.user.displayName),
            const SizedBox(height: 8),
            Text('Access: ${entitlement.accessState}'),
            Text('Plan: ${entitlement.planCode ?? 'None'}'),
            if (entitlement.accessState == 'trial')
              Text('Free jobs remaining: ${entitlement.trialRemaining}'),
            const SizedBox(height: 12),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                FilledButton(
                  onPressed: onOpenJobs,
                  child: const Text('Back to Jobs'),
                ),
                if (appState.hasAdminLikeWorkspaceAccess)
                  OutlinedButton(
                    onPressed: onOpenAccount,
                    child: Text(
                      appState.hasBusinessMembership
                          ? 'Manage Seats and Invites'
                          : 'Open Account',
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _PlansCard extends StatelessWidget {
  const _PlansCard({
    required this.appState,
    required this.showPlanOptionsForActiveSubscription,
    required this.onTogglePlanOptions,
  });

  final MaterialGuardianAppState appState;
  final bool showPlanOptionsForActiveSubscription;
  final VoidCallback onTogglePlanOptions;

  @override
  Widget build(BuildContext context) {
    final plans = appState.backendPlans;
    final activeEntitlement =
        appState.effectiveBackendEntitlement ??
        appState.backendMe?.activeEntitlement;
    BackendPlanSnapshot? activePlan;
    for (final plan in plans) {
      if (plan.planCode == activeEntitlement?.planCode) {
        activePlan = plan;
        break;
      }
    }
    final hasActivePaidPlan =
        activeEntitlement?.accessState == 'paid' && activePlan != null;
    final activeOrganization = appState.backendOrganization;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Plans', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            const Text(
              'Choose based on who needs to create reports. Owners and admins can still manage the workspace without handing everyone a seat.',
            ),
            const SizedBox(height: 12),
            if (hasActivePaidPlan) ...[
              _CurrentPlanCard(
                plan: activePlan,
                organization: activeOrganization,
              ),
              const SizedBox(height: 12),
            ],
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                OutlinedButton(
                  onPressed: appState.isLoadingPurchaseCatalog
                      ? null
                      : () => appState.loadPurchaseCatalog(),
                  child: const Text('Reload Pricing'),
                ),
                if (appState.isSignedIn)
                  OutlinedButton(
                    onPressed:
                        (!appState.isStoreAvailable ||
                            appState.isPurchasing ||
                            appState.isRestoringPurchases)
                        ? null
                        : () => appState.restorePurchases(),
                    child: Text(
                      appState.isRestoringPurchases
                          ? 'Checking Store Purchases...'
                          : 'Restore App Store Purchases',
                    ),
                  ),
                if (hasActivePaidPlan)
                  FilledButton(
                    onPressed: onTogglePlanOptions,
                    child: Text(
                      showPlanOptionsForActiveSubscription
                          ? 'Hide Plan Options'
                          : 'Upgrade or Change Plan',
                    ),
                  ),
              ],
            ),
            if (appState.isSignedIn) ...[
              const SizedBox(height: 10),
              Text(
                'Use restore only if this device was replaced, the app was reinstalled, or your paid access did not show up yet.',
              ),
            ],
            if (appState.purchaseStatusMessage != null &&
                appState.purchaseStatusMessage!.trim().isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(appState.purchaseStatusMessage!),
            ],
            if (appState.purchaseError != null &&
                appState.purchaseError!.trim().isNotEmpty) ...[
              const SizedBox(height: 12),
              _ErrorText(message: appState.purchaseError!),
            ],
            const SizedBox(height: 12),
            if (plans.isEmpty)
              const Text('Plan catalog is still loading.')
            else if (hasActivePaidPlan)
              if (!showPlanOptionsForActiveSubscription)
                const Text(
                  'This account already has an active plan. Use the button above only if you want to upgrade, change billing, or compare options.',
                )
              else
                for (final plan in plans) ...[
                  _SalesPlanTile(appState: appState, plan: plan),
                  if (plan != plans.last) const Divider(height: 24),
                ]
            else
              for (final plan in plans) ...[
                _SalesPlanTile(appState: appState, plan: plan),
                if (plan != plans.last) const Divider(height: 24),
              ],
          ],
        ),
      ),
    );
  }
}

class _CurrentPlanCard extends StatelessWidget {
  const _CurrentPlanCard({required this.plan, required this.organization});

  final BackendPlanSnapshot plan;
  final BackendOrganizationSummary? organization;

  @override
  Widget build(BuildContext context) {
    final savingsLine =
        plan.savingsCopy ??
        (plan.annualSavingsDisplay == null
            ? null
            : 'Save ${plan.annualSavingsDisplay} per year, basically 2 free months.');
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Active subscription',
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '${_titleCase(plan.audienceType)} ${_titleCase(plan.billingInterval)}',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(plan.displayPrice),
          if (plan.isBusiness && organization != null) ...[
            const SizedBox(height: 6),
            Text(
              'Seats in use: ${organization!.seatsAssigned}/${organization!.seatLimit}',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            Text('Open seats: ${organization!.seatsRemaining}'),
          ],
          if (savingsLine != null && savingsLine.trim().isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              savingsLine,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _SalesPlanTile extends StatelessWidget {
  const _SalesPlanTile({required this.appState, required this.plan});

  final MaterialGuardianAppState appState;
  final BackendPlanSnapshot plan;

  @override
  Widget build(BuildContext context) {
    final storeProduct = appState
        .storeProductsById[(plan.storeProductIdForPlatform('android') ?? '')];
    final needsOrganization = plan.isBusiness;
    final hasOrganization = appState.backendOrganization != null;
    final canPurchase =
        appState.isSignedIn &&
        storeProduct != null &&
        (!needsOrganization || hasOrganization) &&
        !appState.isPurchasing;
    final savingsLine =
        plan.savingsCopy ??
        (plan.annualSavingsDisplay == null
            ? null
            : 'Save ${plan.annualSavingsDisplay} per year, basically 2 free months.');
    final helperLine = !appState.isSignedIn
        ? 'Verify your email first to start the 6-job trial or buy a plan.'
        : needsOrganization && !hasOrganization
        ? 'Create the company in Account first, then buy the business plan for that workspace.'
        : storeProduct == null
        ? 'Store pricing has not loaded for this plan yet.'
        : null;
    final highlights = _planHighlights(plan);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${_titleCase(plan.audienceType)} ${_titleCase(plan.billingInterval)}',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 4),
        Text(
          storeProduct != null
              ? 'Backend: ${plan.displayPrice} | Store: ${storeProduct.price}'
              : plan.displayPrice,
        ),
        Text(
          plan.isBusiness
              ? '${plan.seatLimit} report seats included'
              : '1 full workspace',
        ),
        const SizedBox(height: 8),
        for (final highlight in highlights) ...[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.only(top: 2),
                child: Text('- '),
              ),
              Expanded(child: Text(highlight)),
            ],
          ),
          const SizedBox(height: 4),
        ],
        if (savingsLine != null && savingsLine.trim().isNotEmpty) ...[
          const SizedBox(height: 6),
          Text(
            savingsLine,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
        ],
        if (helperLine != null) ...[
          const SizedBox(height: 4),
          Text(helperLine),
        ],
        const SizedBox(height: 10),
        FilledButton(
          onPressed: canPurchase
              ? () => appState.purchasePlan(planCode: plan.planCode)
              : null,
          child: Text(
            appState.isSignedIn ? 'Select Plan' : 'Sign In First',
          ),
        ),
      ],
    );
  }
}

class _ReturningUserCard extends StatelessWidget {
  const _ReturningUserCard();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text(
              'Already signed up?',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
            SizedBox(height: 8),
            Text(
              'Use the same email again. If this phone was reset, replaced, or had app data cleared, the app needs a fresh email-code sign-in because the saved local session is gone.',
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorText extends StatelessWidget {
  const _ErrorText({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Text(
      message,
      style: TextStyle(color: Theme.of(context).colorScheme.error),
    );
  }
}

String _titleCase(String value) {
  if (value.isEmpty) {
    return value;
  }
  return '${value[0].toUpperCase()}${value.substring(1)}';
}

List<String> _planHighlights(BackendPlanSnapshot plan) {
  if (plan.isBusiness) {
    final adminLimit = plan.adminPolicy?.includedAdminLimit;
    final adminLine = adminLimit == null
        ? 'Company admins can manage seats, branding, and report defaults.'
        : 'Up to $adminLimit admins can manage seats, branding, and report defaults.';
    return [
      'Includes up to ${plan.seatLimit} report seats.',
      adminLine,
      'Assign seats only to the people who need to create reports.',
      'Shared logo, report defaults, and invites stay under admin control.',
      'Owners or admins can still create reports themselves by taking a seat when needed.',
    ];
  }

  return [
    'One full workspace for one person.',
    'Logo, report defaults, and saved signatures stay with that account.',
    'Use the same phone workflow for scans, photos, and receiving reports without shared seats.',
  ];
}
