import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class StoredBackendAuthSession {
  const StoredBackendAuthSession({
    required this.accessToken,
    required this.refreshToken,
  });

  final String accessToken;
  final String refreshToken;

  Map<String, dynamic> toJson() {
    return {'accessToken': accessToken, 'refreshToken': refreshToken};
  }

  factory StoredBackendAuthSession.fromJson(Map<String, dynamic> json) {
    return StoredBackendAuthSession(
      accessToken: json['accessToken'] as String? ?? '',
      refreshToken: json['refreshToken'] as String? ?? '',
    );
  }
}

abstract class BackendAuthSessionStore {
  Future<StoredBackendAuthSession?> load();
  Future<void> save(StoredBackendAuthSession session);
  Future<void> clear();
}

class SharedPreferencesBackendAuthSessionStore
    implements BackendAuthSessionStore {
  @override
  Future<StoredBackendAuthSession?> load() async {
    final preferences = await SharedPreferences.getInstance();
    final raw = preferences.getString(_backendAuthSessionKey);
    if (raw == null || raw.trim().isEmpty) {
      return null;
    }

    final decoded = jsonDecode(raw);
    if (decoded is! Map<String, dynamic>) {
      return null;
    }

    final session = StoredBackendAuthSession.fromJson(decoded);
    if (session.accessToken.isEmpty || session.refreshToken.isEmpty) {
      return null;
    }
    return session;
  }

  @override
  Future<void> save(StoredBackendAuthSession session) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(
      _backendAuthSessionKey,
      jsonEncode(session.toJson()),
    );
  }

  @override
  Future<void> clear() async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.remove(_backendAuthSessionKey);
  }
}

class InMemoryBackendAuthSessionStore implements BackendAuthSessionStore {
  StoredBackendAuthSession? _session;

  @override
  Future<void> clear() async {
    _session = null;
  }

  @override
  Future<StoredBackendAuthSession?> load() async {
    return _session;
  }

  @override
  Future<void> save(StoredBackendAuthSession session) async {
    _session = session;
  }
}

const _backendAuthSessionKey = 'backend_auth_session_v1';
