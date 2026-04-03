import 'package:flutter/material.dart';

import 'app/material_guardian_app.dart';
import 'app/material_guardian_state.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  const useDebugSeededSignedInState = bool.fromEnvironment(
    'MG_DEBUG_SEEDED_SIGNED_IN',
    defaultValue: false,
  );
  final appState = useDebugSeededSignedInState
      ? MaterialGuardianAppState.seededSignedIn()
      : await MaterialGuardianAppState.create();
  runApp(MaterialGuardianApp(appState: appState));
}
