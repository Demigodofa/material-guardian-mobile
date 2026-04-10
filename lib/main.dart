import 'package:flutter/material.dart';

import 'app/material_guardian_app.dart';
import 'app/material_guardian_state.dart';
import 'data/backend_auth_session_store.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  const useDebugSeededSignedInState = bool.fromEnvironment(
    'MG_DEBUG_SEEDED_SIGNED_IN',
    defaultValue: false,
  );
  const debugAccessToken = String.fromEnvironment(
    'MG_DEBUG_BACKEND_ACCESS_TOKEN',
    defaultValue: '',
  );
  const debugRefreshToken = String.fromEnvironment(
    'MG_DEBUG_BACKEND_REFRESH_TOKEN',
    defaultValue: '',
  );
  final debugBootstrapSession =
      debugAccessToken.isNotEmpty && debugRefreshToken.isNotEmpty
      ? const StoredBackendAuthSession(
          accessToken: debugAccessToken,
          refreshToken: debugRefreshToken,
        )
      : null;
  final appState = useDebugSeededSignedInState
      ? MaterialGuardianAppState.seededSignedIn()
      : await MaterialGuardianAppState.create(
          debugBootstrapSession: debugBootstrapSession,
        );
  runApp(MaterialGuardianApp(appState: appState));
}
