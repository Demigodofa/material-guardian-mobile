import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../app/brand_assets.dart';
import '../app/material_guardian_state.dart';
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

        return Scaffold(
          appBar: AppBar(title: const Text('Plans')),
          body: SafeArea(
            child: centeredContent(
              child: ListView(
                padding: screenListPadding(context),
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
                    ),
                  ],
                  const SizedBox(height: 16),
                  const _HowPlansWorkCard(),
                  const SizedBox(height: 16),
                  _PlansCard(appState: appState),
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
        ? 'Pick the right plan for your shop'
        : 'Start free with 6 jobs';
    final subtitle = isSignedIn
        ? 'Your account is already in the system. Choose the plan that matches how your shop actually runs.'
        : 'Verify your email once, use 6 jobs free, and upgrade only if the app earns a place in your workflow.';
    final trialLine = isSignedIn && accessState == 'trial'
        ? 'You still have $trialRemaining free jobs remaining on this account.'
        : 'Local-first stays the default today. Cloud-backed access can be added later without changing how the core workflow feels.';

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
      'Individual gives one shop the full workspace: logo, B16, surface-finish defaults, signatures, and local report exports.',
      'Business adds a shared company workspace with managed branding, report defaults, and up to 5 assignable report seats.',
      'Admins can run the company without taking a report seat. Assign a seat only when that person needs to create receiving reports.',
      'MTR capture, photos, scans, and receiving reports all happen natively on the phone instead of through a separate scanner workflow.',
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
  const _SignedInStatusCard({required this.appState, required this.onOpenJobs});

  final MaterialGuardianAppState appState;
  final VoidCallback onOpenJobs;

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
            FilledButton(onPressed: onOpenJobs, child: const Text('Open Jobs')),
          ],
        ),
      ),
    );
  }
}

class _PlansCard extends StatelessWidget {
  const _PlansCard({required this.appState});

  final MaterialGuardianAppState appState;

  @override
  Widget build(BuildContext context) {
    final plans = appState.backendPlans;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Plans', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            const Text(
              'Choose the plan that fits how many people need report access, not just how many people work at the company.',
            ),
            const SizedBox(height: 8),
            const Text(
              'Yearly plans should read as the better value. Business admins can invite people later, keep branding consistent, and assign seats only to the people who actually need report creation.',
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                FilledButton(
                  onPressed: appState.isLoadingPurchaseCatalog
                      ? null
                      : () => appState.loadPurchaseCatalog(),
                  child: const Text('Refresh Plans'),
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
                          ? 'Checking Purchases...'
                          : 'Restore Purchases',
                    ),
                  ),
              ],
            ),
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
        ? 'Create the company organization in Account first, then this purchase becomes that company workspace.'
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
            appState.isSignedIn ? 'Choose This Plan' : 'Sign In First',
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
      'Includes up to ${plan.seatLimit} assignable seats for report creators.',
      adminLine,
      'Admins can also occupy a seat when they need to create receiving reports themselves.',
      'Shared logo, B16, and surface-finish defaults stay under admin control.',
      'MTRs and receiving reports are captured natively on the phone, not through a separate scanner workflow.',
    ];
  }

  return [
    'One full workspace for one shop or owner-operator.',
    'Logo, B16, surface-finish defaults, and saved signatures stay available to the person paying for the plan.',
    'Use the same phone workflow for MTR scans and receiving reports without needing shared seats.',
  ];
}
