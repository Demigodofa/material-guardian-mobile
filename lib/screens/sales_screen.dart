import 'package:flutter/foundation.dart';
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
                  if (appState.shouldSurfaceSalesAuthError &&
                      appState.backendAccountError != null &&
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
                        if (!kReleaseMode && challenge != null) {
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
                  if (appState.backendOrganization == null) ...[
                    const SizedBox(height: 16),
                    _BusinessSetupCard(
                      onOpenAccount: () {
                        Navigator.of(context).pushNamed(AppRoutes.account);
                      },
                    ),
                  ],
                ],
                  const SizedBox(height: 16),
                  const _PlanFitCard(),
                  const SizedBox(height: 16),
                  const _SalesFaqCard(),
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
        ? 'Choose the plan that fits the way your shop actually works'
        : 'Start free with 6 real jobs';
    final subtitle = isSignedIn
        ? 'Keep the same phone workflow, then decide whether this stays a solo account or becomes a managed company workspace.'
        : 'Verify your email once, run real receiving reports in the field, and only pay when it proves it saves time.';
    final trialLine = isSignedIn && accessState == 'trial'
        ? 'You still have $trialRemaining free jobs remaining on this account.'
        : 'The workflow stays phone-first. Paid access adds durable account, organization, and purchase-backed access without changing how reports are created.';

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

class _PlanFitCard extends StatelessWidget {
  const _PlanFitCard();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final emphasisStyle = Theme.of(context).textTheme.bodyMedium?.copyWith(
      color: scheme.onSecondaryContainer,
      fontWeight: FontWeight.w700,
    );

    return Card(
      color: scheme.secondaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Pick the right lane',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: scheme.onSecondaryContainer,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Start with the real phone workflow first. Upgrade when the workflow is saving time and you want durable account recovery, store-backed access, and cleaner team setup.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: scheme.onSecondaryContainer,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Individual fits one accountable owner. Business adds one shared company workspace, managed branding, and up to 5 report seats without forcing every admin into a seat.',
              style: emphasisStyle,
            ),
            const SizedBox(height: 10),
            Text(
              'Yearly is the cleanest value when Material Guardian is part of the weekly receiving routine.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: scheme.onSecondaryContainer,
              ),
            ),
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
              'Enter the email you want tied to this account. The email code is the verification step, so there is no password to remember. Your personal name is optional here. Company naming only matters later if you choose Business.',
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
                labelText: 'Personal Name (optional)',
              ),
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
    final planLabel = _friendlyPlanLabel(entitlement.planCode);
    final organizationName =
        appState.backendOrganization?.name ??
        me.memberships.cast<BackendMembershipSummary?>().firstWhere(
              (membership) => membership?.isAccepted == true,
              orElse: () => null,
            )?.organizationName;
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
            Text('Access status: ${_friendlyAccessLabel(entitlement.accessState)}'),
            Text('Current plan: $planLabel'),
            if (organizationName != null && organizationName.trim().isNotEmpty)
              Text('Workspace: $organizationName'),
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
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Plans', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            const Text(
              'Choose the plan based on how many people actually need report creation access.',
            ),
            const SizedBox(height: 8),
            Text(
              'Subscriptions renew automatically until canceled in ${_friendlyStorePlatformLabel(appState.currentStorePlatform)}. Canceling normally keeps access through the paid period.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 12),
            if (hasActivePaidPlan) ...[
              _CurrentPlanCard(plan: activePlan),
              const SizedBox(height: 12),
            ],
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
            else if (hasActivePaidPlan)
              const Text(
                'This account already has an active subscription. Use Restore Purchases if the store and backend ever need to be re-linked on this device.',
              )
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
  const _CurrentPlanCard({required this.plan});

  final BackendPlanSnapshot plan;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final savingsLine =
        plan.savingsCopy ??
        (plan.annualSavingsDisplay == null
            ? null
            : 'Save ${plan.annualSavingsDisplay} per year, basically 2 free months.');
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: scheme.primaryContainer,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: scheme.primary.withAlpha(31)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Active subscription',
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: scheme.onPrimaryContainer,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '${_titleCase(plan.audienceType)} ${_titleCase(plan.billingInterval)}',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: scheme.onPrimaryContainer,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            plan.displayPrice,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: scheme.onPrimaryContainer,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (savingsLine != null && savingsLine.trim().isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              savingsLine,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: scheme.onPrimaryContainer,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _BusinessSetupCard extends StatelessWidget {
  const _BusinessSetupCard({required this.onOpenAccount});

  final VoidCallback onOpenAccount;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      color: scheme.secondaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Business Setup Comes First',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: scheme.onSecondaryContainer,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Individual can be purchased immediately. Business should create the company workspace first so the subscription, invites, and shared branding all attach to the right company name.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: scheme.onSecondaryContainer,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Next step: open Account, enter the company or workspace name you want people to see, save it, then come back here and buy Business.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: scheme.onSecondaryContainer,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: onOpenAccount,
              child: const Text('Open Company Setup'),
            ),
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
    final storeProduct =
        appState.storeProductsById[plan.storeProductIdForPlatform(
              appState.currentStorePlatform,
            ) ??
            ''];
    final priceLabel = storeProduct?.price ?? plan.displayPrice;
    final needsOrganization = plan.isBusiness;
    final hasOrganization = appState.backendOrganization != null;
    final needsCompanySetup =
        appState.isSignedIn && needsOrganization && !hasOrganization;
    final canPurchase =
        appState.isSignedIn &&
        storeProduct != null &&
        !needsCompanySetup &&
        !appState.isPurchasing;
    final savingsLine =
        plan.savingsCopy ??
        (plan.annualSavingsDisplay == null
            ? null
            : 'Save ${plan.annualSavingsDisplay} per year, basically 2 free months.');
    final helperLine = !appState.isSignedIn
        ? 'Verify your email first to start the 6-job trial or buy a plan.'
        : needsCompanySetup
        ? 'Set up the company workspace in Account first so the subscription, invites, and branding attach to the right company name.'
        : storeProduct == null
        ? 'Store pricing has not loaded for this plan yet.'
        : null;
    final highlights = _planHighlights(plan);
    final platformLabel = _friendlyStorePlatformLabel(
      appState.currentStorePlatform,
    );
    final badges = <String>[
      if (plan.isBusiness) 'Shared team' else 'Solo owner',
      if (plan.billingInterval == 'yearly') 'Yearly',
      if (plan.annualSavingsDisplay != null &&
          plan.annualSavingsDisplay!.trim().isNotEmpty)
        'Save ${plan.annualSavingsDisplay}/yr',
    ];
    final buttonLabel = !appState.isSignedIn
        ? 'Sign In First'
        : needsCompanySetup
        ? 'Set Up Company Workspace'
        : plan.isBusiness
        ? 'Buy Business in $platformLabel'
        : 'Buy Individual in $platformLabel';
    final VoidCallback? onPressed = canPurchase
        ? () => appState.purchasePlan(planCode: plan.planCode)
        : needsCompanySetup
        ? () => Navigator.of(context).pushNamed(AppRoutes.account)
        : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final badge in badges)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.secondaryContainer,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  badge,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSecondaryContainer,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 10),
        Text(
          '${_titleCase(plan.audienceType)} ${_titleCase(plan.billingInterval)}',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 4),
        Text(
          priceLabel,
        ),
        if (storeProduct != null)
          Text(
            'Billed through ${_friendlyStorePlatformLabel(appState.currentStorePlatform)}.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        if (!kReleaseMode && storeProduct == null)
          Text(
            'Dev note: store pricing has not loaded yet. Backend reference price is ${plan.displayPrice}.',
            style: Theme.of(context).textTheme.bodySmall,
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
        if (storeProduct != null) ...[
          const SizedBox(height: 6),
          Text(
            'Auto-renews until canceled in ${_friendlyStorePlatformLabel(appState.currentStorePlatform)}.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
        const SizedBox(height: 10),
        FilledButton(
          onPressed: onPressed,
          child: Text(buttonLabel),
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

class _SalesFaqCard extends StatelessWidget {
  const _SalesFaqCard();

  @override
  Widget build(BuildContext context) {
    final questions = <({String question, String answer})>[
      (
        question: 'Do I need a company workspace before I subscribe?',
        answer:
            'Only for business. Individual can be bought right after sign-in. Business should create the company workspace first in Account so the subscription attaches to the right organization.',
      ),
      (
        question: 'How do seat invites work?',
        answer:
            'Invite the person from Account, have them download Material Guardian from Google Play if needed, sign in with the same email, then redeem the organization ID and access code from the invite email.',
      ),
      (
        question: 'What happens if I change phones later?',
        answer:
            'Sign in again with the same email and restore purchases if needed. The saved device session does not survive uninstall, reset, or cleared app data.',
      ),
      (
        question: 'What happens when I cancel a subscription?',
        answer:
            'Cancel it in Google Play or the App Store. Access normally stays active until the current paid period ends unless the store later revokes or refunds it.',
      ),
    ];

    return Card(
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        title: Text(
          'Questions Before You Buy',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        children: [
          for (final item in questions) ...[
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                item.question,
                style: Theme.of(context).textTheme.titleSmall,
              ),
            ),
            const SizedBox(height: 4),
            Text(item.answer),
            if (item != questions.last) const SizedBox(height: 12),
          ],
        ],
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

String _friendlyStorePlatformLabel(String platform) {
  switch (platform) {
    case 'google':
      return 'Google Play';
    case 'apple':
      return 'the App Store';
    default:
      return _titleCase(platform);
  }
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
