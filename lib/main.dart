import 'package:flutter/material.dart';

import 'app/material_guardian_app.dart';
import 'app/material_guardian_state.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final appState = await MaterialGuardianAppState.create();
  runApp(MaterialGuardianApp(appState: appState));
}
