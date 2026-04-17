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

enum _SignedOutIntent { trial, login }

enum _AudienceFocus { all, individual, business }

class _SalesScreenState extends State<SalesScreen> {
  final _emailController = TextEditingController();
  final _displayNameController = TextEditingController();
  final _codeController = TextEditingController();
  final _authCardKey = GlobalKey();
  final _plansCardKey = GlobalKey();
  final _scrollController = ScrollController();

  _SignedOutIntent _signedOutIntent = _SignedOutIntent.trial;
  _AudienceFocus _audienceFocus = _AudienceFocus.all;
  bool _showAuthCard = false;

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
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToKey(GlobalKey key, {double? fallbackOffset}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      final targetContext = key.currentContext;
      if (targetContext != null) {
        Scrollable.ensureVisible(
          targetContext,
          duration: const Duration(milliseconds: 280),
          curve: Curves.easeOutCubic,
          alignment: 0.08,
        );
        return;
      }
      if (!_scrollController.hasClients || fallbackOffset == null) {
        return;
      }
      final targetOffset = fallbackOffset.clamp(
        0.0,
        _scrollController.position.maxScrollExtent,
      );
      _scrollController.animateTo(
        targetOffset,
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOutCubic,
      );
    });
  }

  void _focusAudience(_AudienceFocus focus) {
    setState(() {
      _audienceFocus = focus;
    });
    _scrollToKey(_plansCardKey, fallbackOffset: 980);
  }

  void _focusAuth(_SignedOutIntent intent) {
    setState(() {
      _signedOutIntent = intent;
      _showAuthCard = true;
    });
    _scrollToKey(_authCardKey, fallbackOffset: 620);
  }

  Future<void> _startAuth() async {
    await appState.startBackendSignIn(
      email: _emailController.text,
      displayName: _displayNameController.text,
    );
    if (!mounted) {
      return;
    }
    final challenge = appState.pendingBackendAuthStart;
    if (challenge != null) {
      final isDevBackend =
          appState.backendBaseUrl.contains('backend-dev') ||
          appState.backendBaseUrl.contains('-dev-');
      final messenger = ScaffoldMessenger.of(context);
      if (isDevBackend && challenge.demoCode.trim().isNotEmpty) {
        messenger.showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xFFDCF5E4),
            content: Text(
              'Dev backend fallback active. Use code ${challenge.demoCode}.',
              style: const TextStyle(color: Color(0xFF163822)),
            ),
          ),
        );
      } else {
        messenger.showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xFFDCF5E4),
            content: Text(
              'Code sent to ${challenge.deliveryTarget}.',
              style: const TextStyle(color: Color(0xFF163822)),
            ),
          ),
        );
      }
    }
    if (!kReleaseMode && challenge != null) {
      _codeController.text = challenge.demoCode;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: appState,
      builder: (context, _) {
        final media = MediaQuery.sizeOf(context);
        final isCompactLandscape =
            media.width > media.height && media.height < 560;
        final salesMaxWidth = media.width >= 1100 ? 1160.0 : 860.0;
        final pendingAuth = appState.pendingBackendAuthStart;
        final conflict = appState.pendingSessionConflict;
        final entitlement =
            appState.effectiveBackendEntitlement ??
            appState.backendMe?.activeEntitlement;
        final isSignedIn = appState.isSignedIn;
        final showAuthCard =
            !isSignedIn &&
            (_showAuthCard ||
                pendingAuth != null ||
                (appState.shouldSurfaceSalesAuthError &&
                    appState.backendAccountError != null &&
                    appState.backendAccountError!.trim().isNotEmpty));
        final appBarTitle = isSignedIn ? 'Plans' : 'Material Guardian';
        final baseListPadding = screenListPadding(context);
        final listPadding = baseListPadding.copyWith(
          bottom: baseListPadding.bottom + 96,
        );

        return Scaffold(
          appBar: AppBar(title: Text(appBarTitle)),
          body: SafeArea(
            child: centeredContent(
              maxWidth: salesMaxWidth,
              child: ListView(
                controller: _scrollController,
                padding: listPadding,
                children: [
                  const SizedBox(height: 4),
                  if (!isCompactLandscape) ...[
                    _SalesLogo(compact: media.width < 420),
                    const SizedBox(height: 12),
                  ],
                  _HeroCard(
                    isSignedIn: isSignedIn,
                    trialRemaining: entitlement?.trialRemaining ?? 6,
                    accessState: entitlement?.accessState,
                    onStartTrial: !isSignedIn
                        ? () => _focusAuth(_SignedOutIntent.trial)
                        : null,
                    onLogIn: !isSignedIn
                        ? () => _focusAuth(_SignedOutIntent.login)
                        : null,
                  ),
                  if (!isSignedIn) ...[
                    const SizedBox(height: 16),
                    if (appState.shouldSurfaceSalesAuthError &&
                        appState.backendAccountError != null &&
                        appState.backendAccountError!.trim().isNotEmpty) ...[
                      _ErrorText(message: appState.backendAccountError!),
                      const SizedBox(height: 16),
                    ],
                    if (showAuthCard)
                      _SalesAuthCard(
                        key: _authCardKey,
                        authIntent: _signedOutIntent,
                        audienceFocus: _audienceFocus,
                        emailController: _emailController,
                        displayNameController: _displayNameController,
                        isBusy: appState.isAuthenticatingBackend,
                        onStart: _startAuth,
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
                    const SizedBox(height: 16),
                    _LaneChooserCard(
                      audienceFocus: _audienceFocus,
                      onFocusAudience: _focusAudience,
                    ),
                    if (_audienceFocus == _AudienceFocus.business) ...[
                      const SizedBox(height: 16),
                      const _BusinessFlowCard(),
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
                  _PlansCard(
                    key: _plansCardKey,
                    appState: appState,
                    audienceFocus: _audienceFocus,
                    onRequireAuth: () => _focusAuth(_SignedOutIntent.trial),
                  ),
                  const SizedBox(height: 16),
                  const _SalesFaqCard(),
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
  const _SalesLogo({this.compact = false});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Image.asset(
        BrandAssets.materialGuardianLogo512,
        width: compact ? 84 : 96,
        height: compact ? 84 : 96,
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
    required this.onStartTrial,
    required this.onLogIn,
  });

  final bool isSignedIn;
  final int trialRemaining;
  final String? accessState;
  final VoidCallback? onStartTrial;
  final VoidCallback? onLogIn;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final isNarrow = width < 410;
    final isCompactLandscape =
        MediaQuery.orientationOf(context) == Orientation.landscape &&
        MediaQuery.sizeOf(context).height < 560;
    final scheme = Theme.of(context).colorScheme;
    final title = isSignedIn
        ? 'Choose the plan that fits the way your shop actually receives material'
        : 'Try your first 6 free jobs now';
    final subtitle = isSignedIn
        ? 'Keep the same phone-first material receiving workflow, then decide whether this stays a solo account or becomes a managed company workspace.'
        : isCompactLandscape
        ? 'Run receiving reports, capture MTRs, and export clean packets from one phone-first workflow.'
        : 'Run material receiving reports, capture MTRs, and export clean packets from one phone-first workflow.';
    final trialLine = isSignedIn && accessState == 'trial'
        ? 'You still have $trialRemaining free material receiving jobs remaining on this account.'
        : 'No credit card to begin. Start with the same email you want tied to your material receiving account.';
    final badgeLabels = isNarrow || isCompactLandscape
        ? const ['6 free jobs', 'Material receiving', 'Packet exports']
        : const [
            '6 free jobs',
            'Material receiving',
            'MTR capture',
            'Packet exports',
          ];
    final supportingLine = isNarrow
        ? 'Built for the receiving dock, shop floor, and worksite.'
        : isCompactLandscape
        ? ''
        : 'Built for the receiving dock, the shop floor, and the worksite instead of a desktop back office.';

    return Card(
      color: scheme.primaryContainer,
      child: Padding(
        padding: EdgeInsets.all(isCompactLandscape ? 16 : 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final label in badgeLabels) _HeroBadge(label: label),
              ],
            ),
            SizedBox(
              height: isCompactLandscape
                  ? 8
                  : isNarrow
                  ? 10
                  : 12,
            ),
            Text(
              title,
              style:
                  (isNarrow
                          ? Theme.of(context).textTheme.headlineMedium
                          : Theme.of(context).textTheme.headlineSmall)
                      ?.copyWith(color: scheme.onPrimaryContainer),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: scheme.onPrimaryContainer,
                fontSize: isCompactLandscape ? 17 : null,
              ),
            ),
            SizedBox(height: isCompactLandscape ? 6 : 8),
            Text(
              trialLine,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: scheme.onPrimaryContainer,
                fontWeight: FontWeight.w700,
              ),
            ),
            if (supportingLine.isNotEmpty) ...[
              SizedBox(height: isCompactLandscape ? 6 : 10),
              Text(
                supportingLine,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: scheme.onPrimaryContainer.withAlpha(214),
                ),
              ),
            ],
            if (!isSignedIn) ...[
              SizedBox(height: isCompactLandscape ? 12 : 16),
              if (isNarrow)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    FilledButton(
                      onPressed: onStartTrial,
                      child: const Text('Start Free Trial'),
                    ),
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: OutlinedButton(
                        onPressed: onLogIn,
                        child: const Text('Log In'),
                      ),
                    ),
                  ],
                )
              else
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    FilledButton(
                      onPressed: onStartTrial,
                      child: const Text('Start Free Trial'),
                    ),
                    OutlinedButton(
                      onPressed: onLogIn,
                      child: const Text('Log In'),
                    ),
                  ],
                ),
            ],
          ],
        ),
      ),
    );
  }
}

class _HeroBadge extends StatelessWidget {
  const _HeroBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: scheme.surface.withAlpha(196),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: scheme.primary.withAlpha(24)),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
          color: scheme.onPrimaryContainer,
          fontWeight: FontWeight.w700,
          fontSize: 12,
        ),
      ),
    );
  }
}

class _LaneChooserCard extends StatelessWidget {
  const _LaneChooserCard({
    required this.audienceFocus,
    required this.onFocusAudience,
  });

  final _AudienceFocus audienceFocus;
  final ValueChanged<_AudienceFocus> onFocusAudience;

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
              'Choose how material receiving is managed',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: scheme.onSecondaryContainer,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Start with the path that matches how receiving work is owned today. The phone workflow stays the same even if you later move from solo use into a company workspace.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: scheme.onSecondaryContainer,
              ),
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _AudienceLaneCard(
                  title: 'Individual',
                  description:
                      'One accountable owner, one account, and the full material receiving workflow on one phone-first setup.',
                  emphasis:
                      'Best when one person owns the receiving reports end to end.',
                  selected: audienceFocus == _AudienceFocus.individual,
                  onPressed: () => onFocusAudience(_AudienceFocus.individual),
                ),
                _AudienceLaneCard(
                  title: 'Business',
                  description:
                      'One company workspace with 5 report users included, admin controls, and teammate invites after setup.',
                  emphasis:
                      'Best when multiple people need the same receiving workflow under one company.',
                  selected: audienceFocus == _AudienceFocus.business,
                  onPressed: () => onFocusAudience(_AudienceFocus.business),
                ),
              ],
            ),
            if (audienceFocus != _AudienceFocus.all) ...[
              const SizedBox(height: 10),
              TextButton(
                onPressed: () => onFocusAudience(_AudienceFocus.all),
                child: const Text('View All Plans'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _AudienceLaneCard extends StatelessWidget {
  const _AudienceLaneCard({
    required this.title,
    required this.description,
    required this.emphasis,
    required this.selected,
    required this.onPressed,
  });

  final String title;
  final String description;
  final String emphasis;
  final bool selected;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final icon = switch (title) {
      'Business' => Icons.groups_rounded,
      _ => Icons.person_outline_rounded,
    };
    return ConstrainedBox(
      constraints: const BoxConstraints(minWidth: 250, maxWidth: 360),
      child: Container(
        decoration: BoxDecoration(
          color: selected ? scheme.surface : Colors.white.withAlpha(122),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? scheme.primary : scheme.outlineVariant,
            width: selected ? 1.4 : 1,
          ),
        ),
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              icon,
              color: selected ? scheme.primary : scheme.onSurfaceVariant,
            ),
            const SizedBox(height: 10),
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(description),
            const SizedBox(height: 10),
            Text(
              emphasis,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            FilledButton(onPressed: onPressed, child: Text('Show $title')),
          ],
        ),
      ),
    );
  }
}

class _BusinessFlowCard extends StatelessWidget {
  const _BusinessFlowCard();

  @override
  Widget build(BuildContext context) {
    final steps = <String>[
      'Start with your own email so the billing owner and company workspace stay tied to the same account.',
      'Create the company workspace in Account before you buy Business.',
      'Buy Business only after the workspace name looks right.',
      'Invite teammates, then assign report users to the people who actually create receiving reports.',
      'Company admins keep membership and report access under one workspace.',
    ];

    return Card(
      child: ExpansionTile(
        initiallyExpanded: true,
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        title: Text(
          'How Business Works',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        subtitle: const Text(
          'Business stays simple at launch: one company workspace and 5 included report users.',
        ),
        children: [
          for (var index = 0; index < steps.length; index++) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 24,
                  height: 24,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.secondaryContainer,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    '${index + 1}',
                    style: Theme.of(context).textTheme.labelMedium,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(child: Text(steps[index])),
              ],
            ),
            if (index != steps.length - 1) const SizedBox(height: 10),
          ],
          const SizedBox(height: 12),
          Text(
            'The free trial is 6 jobs on the starting account. It is not 3 jobs per included report user.',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

class _SalesAuthCard extends StatelessWidget {
  const _SalesAuthCard({
    required this.authIntent,
    required this.audienceFocus,
    required this.emailController,
    required this.displayNameController,
    required this.isBusy,
    required this.onStart,
    super.key,
  });

  final _SignedOutIntent authIntent;
  final _AudienceFocus audienceFocus;
  final TextEditingController emailController;
  final TextEditingController displayNameController;
  final bool isBusy;
  final Future<void> Function() onStart;

  @override
  Widget build(BuildContext context) {
    final title = authIntent == _SignedOutIntent.login
        ? 'Log In With Email Code'
        : 'Start Your Free Trial';
    final description = authIntent == _SignedOutIntent.login
        ? 'Enter the same email you already use with Material Guardian. We will send a one-time code so you can get back to your material receiving account on this phone.'
        : audienceFocus == _AudienceFocus.business
        ? 'Start with the email that should own the company workspace. New accounts begin with 6 free material receiving jobs, then you can create the workspace and move into Business when you are ready.'
        : 'Enter the email you want tied to this account. New accounts begin with 6 free material receiving jobs. There is no password to remember because the email code is the sign-in step.';
    final buttonLabel = authIntent == _SignedOutIntent.login
        ? 'Send Login Code'
        : 'Send Trial Code';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(description),
            const SizedBox(height: 12),
            TextField(
              controller: emailController,
              keyboardType: TextInputType.emailAddress,
              autocorrect: false,
              enableSuggestions: false,
              textInputAction: authIntent == _SignedOutIntent.login
                  ? TextInputAction.done
                  : TextInputAction.next,
              inputFormatters: [LengthLimitingTextInputFormatter(120)],
              decoration: const InputDecoration(labelText: 'Email'),
            ),
            if (authIntent == _SignedOutIntent.trial) ...[
              const SizedBox(height: 12),
              TextField(
                controller: displayNameController,
                textInputAction: TextInputAction.done,
                inputFormatters: [LengthLimitingTextInputFormatter(40)],
                decoration: const InputDecoration(
                  labelText: 'Personal Name (optional)',
                ),
              ),
            ],
            const SizedBox(height: 12),
            FilledButton(
              onPressed: isBusy ? null : onStart,
              child: Text(buttonLabel),
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
                'Dev fallback code: ${authStart.demoCode}',
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
        me.memberships
            .cast<BackendMembershipSummary?>()
            .firstWhere(
              (membership) => membership?.isAccepted == true,
              orElse: () => null,
            )
            ?.organizationName;
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
            Text(
              'Access status: ${_friendlyAccessLabel(entitlement.accessState)}',
            ),
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
  const _PlansCard({
    required this.appState,
    required this.audienceFocus,
    required this.onRequireAuth,
    super.key,
  });

  final MaterialGuardianAppState appState;
  final _AudienceFocus audienceFocus;
  final VoidCallback onRequireAuth;

  @override
  Widget build(BuildContext context) {
    final plans = switch (audienceFocus) {
      _AudienceFocus.individual =>
        appState.backendPlans
            .where((plan) => plan.isIndividual)
            .toList(growable: false),
      _AudienceFocus.business =>
        appState.backendPlans
            .where((plan) => plan.isBusiness)
            .toList(growable: false),
      _AudienceFocus.all => appState.backendPlans,
    };
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
    final title = switch (audienceFocus) {
      _AudienceFocus.individual => 'Individual Plans',
      _AudienceFocus.business => 'Business Plans',
      _AudienceFocus.all => 'Plans',
    };
    final intro = switch (audienceFocus) {
      _AudienceFocus.individual =>
        'Built for one accountable owner running material receiving from one account.',
      _AudienceFocus.business =>
        'Built for one company workspace with 5 report users included.',
      _AudienceFocus.all =>
        'Choose the plan based on how many people actually need to create material receiving reports.',
    };
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(intro),
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
                if (appState.canManageBillingActions)
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
              Text(
                appState.canManageBillingActions
                    ? 'This account already has an active subscription. Use Restore Purchases if the store and backend ever need to be re-linked on this device.'
                    : 'This account already has an active subscription. Billing restore and purchase relinking stay with the workspace owner or admin.',
              )
            else
              for (final plan in plans) ...[
                _SalesPlanTile(
                  appState: appState,
                  plan: plan,
                  onRequireAuth: onRequireAuth,
                ),
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
              'Individual can be purchased immediately. Business should create the company workspace first so the subscription, invites, and report access attach to the right organization.',
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
  const _SalesPlanTile({
    required this.appState,
    required this.plan,
    required this.onRequireAuth,
  });

  final MaterialGuardianAppState appState;
  final BackendPlanSnapshot plan;
  final VoidCallback onRequireAuth;

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
        ? plan.isBusiness
              ? 'Start with your own email first, then create the company workspace before you buy Business.'
              : 'Try the 6-job material receiving workflow first, then subscribe when it proves it saves time.'
        : needsCompanySetup
        ? 'Set up the company workspace in Account first so the subscription and invites attach to the right company name.'
        : storeProduct == null
        ? 'Store pricing has not loaded for this plan yet.'
        : null;
    final highlights = _planHighlights(plan);
    final platformLabel = _friendlyStorePlatformLabel(
      appState.currentStorePlatform,
    );
    final badges = <String>[
      if (plan.isBusiness) '5 report users' else 'Solo owner',
      if (plan.billingInterval == 'yearly') 'Yearly',
      if (plan.annualSavingsDisplay != null &&
          plan.annualSavingsDisplay!.trim().isNotEmpty)
        'Save ${plan.annualSavingsDisplay}/yr',
    ];
    final buttonLabel = !appState.isSignedIn
        ? 'Start Trial to Continue'
        : needsCompanySetup
        ? 'Set Up Company Workspace'
        : plan.isBusiness
        ? 'Buy Business in $platformLabel'
        : 'Buy Individual in $platformLabel';
    final VoidCallback? onPressed = canPurchase
        ? () => appState.purchasePlan(planCode: plan.planCode)
        : needsCompanySetup
        ? () => Navigator.of(context).pushNamed(AppRoutes.account)
        : !appState.isSignedIn
        ? onRequireAuth
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
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
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
        Text(priceLabel),
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
              ? '${plan.seatLimit} report users included'
              : '1 accountable owner workspace',
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
        FilledButton(onPressed: onPressed, child: Text(buttonLabel)),
      ],
    );
  }
}

class _SalesFaqCard extends StatelessWidget {
  const _SalesFaqCard();

  @override
  Widget build(BuildContext context) {
    final questions = <({String question, String answer})>[
      (
        question: 'What does the 6-job trial include?',
        answer:
            'A new account can complete 6 full material receiving jobs before paid access is required. The trial belongs to that starting account. It is not split across 5 report users.',
      ),
      (
        question: 'How does Business work?',
        answer:
            'Start with your own email, create the company workspace in Account, buy Business, invite teammates, then assign report users to the people who actually create receiving reports.',
      ),
      (
        question: 'If I start free first, do I lose setup later?',
        answer:
            'No. Your account and any company workspace name you create stay tied to the same email. Device-local assets, such as imported logo files or saved signatures, may still need to be re-imported on a different phone.',
      ),
      (
        question: 'What happens if I change phones later?',
        answer:
            'Log in again with the same email and restore purchases if needed. The saved device session does not survive uninstall, reset, or cleared app data.',
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
      return 'Business 5 Users Monthly';
    case 'material_guardian_business_5_yearly':
      return 'Business 5 Users Yearly';
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
    case 'android':
      return 'Google Play';
    case 'apple':
    case 'ios':
      return 'the App Store';
    default:
      return _titleCase(platform);
  }
}

List<String> _planHighlights(BackendPlanSnapshot plan) {
  if (plan.isBusiness) {
    final adminLimit = plan.adminPolicy?.includedAdminLimit;
    final adminLine = adminLimit == null
        ? 'Company admins manage membership, report access, and the business workflow.'
        : 'Up to $adminLimit admins can manage membership and report access.';
    return [
      'Includes up to ${plan.seatLimit} report users who can create receiving reports.',
      adminLine,
      'Invite teammates after the company workspace exists, then assign report users to the right people.',
      'Best when multiple people need the same material receiving workflow under one company.',
      'MTR capture and receiving reports stay phone-first instead of becoming a separate scanner process.',
    ];
  }

  return [
    'One accountable owner on one workspace.',
    'Best when one person runs the material receiving workflow end to end.',
    'Use the same phone-first flow for MTR capture, receiving reports, and exports without team setup.',
  ];
}
