import 'package:flutter/material.dart';

import '../screens/customization_screen.dart';
import '../screens/drafts_screen.dart';
import '../screens/job_detail_screen.dart';
import '../screens/jobs_screen.dart';
import '../screens/material_form_screen.dart';
import '../screens/privacy_policy_screen.dart';
import 'material_guardian_state.dart';
import 'routes.dart';
import 'theme.dart';

class MaterialGuardianApp extends StatelessWidget {
  const MaterialGuardianApp({required this.appState, super.key});

  final MaterialGuardianAppState appState;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: appState,
      builder: (context, _) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Material Guardian',
          theme: buildMaterialGuardianTheme(),
          onGenerateRoute: (settings) {
            switch (settings.name) {
              case AppRoutes.jobs:
                return MaterialPageRoute<void>(
                  builder: (_) => JobsScreen(appState: appState),
                  settings: settings,
                );
              case AppRoutes.jobDetail:
                final args = settings.arguments! as JobDetailRouteArgs;
                return MaterialPageRoute<void>(
                  builder: (_) =>
                      JobDetailScreen(appState: appState, jobId: args.jobId),
                  settings: settings,
                );
              case AppRoutes.materialForm:
                final args = settings.arguments! as MaterialFormRouteArgs;
                return MaterialPageRoute<void>(
                  builder: (_) => MaterialFormScreen(
                    appState: appState,
                    jobId: args.jobId,
                    draftId: args.draftId,
                  ),
                  settings: settings,
                );
              case AppRoutes.drafts:
                final args =
                    settings.arguments as DraftsRouteArgs? ??
                    const DraftsRouteArgs();
                return MaterialPageRoute<void>(
                  builder: (_) =>
                      DraftsScreen(appState: appState, jobId: args.jobId),
                  settings: settings,
                );
              case AppRoutes.customization:
                return MaterialPageRoute<void>(
                  builder: (_) => CustomizationScreen(appState: appState),
                  settings: settings,
                );
              case AppRoutes.privacyPolicy:
                return MaterialPageRoute<void>(
                  builder: (_) => const PrivacyPolicyScreen(),
                  settings: settings,
                );
            }

            return MaterialPageRoute<void>(
              builder: (_) => JobsScreen(appState: appState),
              settings: settings,
            );
          },
        );
      },
    );
  }
}
