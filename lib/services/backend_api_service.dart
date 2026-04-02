import 'dart:convert';

import 'package:http/http.dart' as http;

const String _defaultBackendBaseUrl = String.fromEnvironment(
  'MG_BACKEND_BASE_URL',
  defaultValue:
      'https://app-platforms-backend-dev-293518443128.us-east4.run.app',
);

class BackendHealthSnapshot {
  const BackendHealthSnapshot({
    required this.status,
    required this.service,
    required this.mode,
  });

  final String status;
  final String service;
  final String mode;

  factory BackendHealthSnapshot.fromJson(Map<String, dynamic> json) {
    return BackendHealthSnapshot(
      status: json['status'] as String? ?? 'unknown',
      service: json['service'] as String? ?? '',
      mode: json['mode'] as String? ?? 'unknown',
    );
  }
}

class BackendApiService {
  BackendApiService({
    http.Client? client,
    String? baseUrl,
  }) : _client = client ?? http.Client(),
       _baseUri = _normalizedBaseUri(baseUrl ?? _defaultBackendBaseUrl);

  final http.Client _client;
  final Uri _baseUri;

  String get baseUrl => _baseUri.toString().replaceFirst(RegExp(r'/$'), '');

  Future<BackendHealthSnapshot> fetchHealth() async {
    final response = await _client.get(_buildUri('health'));
    return BackendHealthSnapshot.fromJson(
      _decodeJsonObject(response, endpoint: '/health'),
    );
  }

  Future<List<dynamic>> fetchPlans() async {
    final response = await _client.get(_buildUri('plans'));
    final payload = _decodeJsonObject(response, endpoint: '/plans');
    final plans = payload['plans'];
    if (plans is! List<dynamic>) {
      throw BackendApiException(
        'Backend response for /plans did not include a plan list.',
      );
    }
    return plans;
  }

  Future<Map<String, dynamic>> fetchMe({required String userId}) async {
    final response = await _client.get(_buildUri('me', queryParameters: {
      'userId': userId,
    }));
    return _decodeJsonObject(response, endpoint: '/me');
  }

  Future<Map<String, dynamic>> fetchCurrentEntitlement({
    required String userId,
  }) async {
    final response = await _client.get(
      _buildUri('entitlements/current', queryParameters: {'userId': userId}),
    );
    return _decodeJsonObject(response, endpoint: '/entitlements/current');
  }

  Future<Map<String, dynamic>> fetchOrganizationSummary({
    required String organizationId,
    required String userId,
  }) async {
    final response = await _client.get(
      _buildUri('organizations/$organizationId', queryParameters: {
        'userId': userId,
      }),
    );
    return _decodeJsonObject(
      response,
      endpoint: '/organizations/$organizationId',
    );
  }

  Future<Map<String, dynamic>> inviteOrganizationMember({
    required String organizationId,
    required String userId,
    required String email,
    String? displayName,
    String role = 'member',
  }) async {
    final response = await _client.post(
      _buildUri('organizations/$organizationId/members/invite', queryParameters: {
        'userId': userId,
      }),
      headers: _jsonHeaders,
      body: jsonEncode({
        'email': email,
        'displayName': displayName,
        'role': role,
      }),
    );
    return _decodeJsonObject(
      response,
      endpoint: '/organizations/$organizationId/members/invite',
    );
  }

  Future<Map<String, dynamic>> resendOrganizationMemberAccess({
    required String organizationId,
    required String membershipId,
    required String userId,
  }) async {
    final response = await _client.post(
      _buildUri(
        'organizations/$organizationId/members/$membershipId/resend-access',
        queryParameters: {'userId': userId},
      ),
    );
    return _decodeJsonObject(
      response,
      endpoint:
          '/organizations/$organizationId/members/$membershipId/resend-access',
    );
  }

  Future<Map<String, dynamic>> updateOrganizationMemberSeat({
    required String organizationId,
    required String membershipId,
    required String userId,
    required bool assignSeat,
  }) async {
    final response = await _client.post(
      _buildUri(
        'organizations/$organizationId/members/$membershipId/seat',
        queryParameters: {'userId': userId},
      ),
      headers: _jsonHeaders,
      body: jsonEncode({'assignSeat': assignSeat}),
    );
    return _decodeJsonObject(
      response,
      endpoint: '/organizations/$organizationId/members/$membershipId/seat',
    );
  }

  Future<Map<String, dynamic>> removeOrganizationMember({
    required String organizationId,
    required String membershipId,
    required String userId,
  }) async {
    final response = await _client.delete(
      _buildUri(
        'organizations/$organizationId/members/$membershipId',
        queryParameters: {'userId': userId},
      ),
    );
    return _decodeJsonObject(
      response,
      endpoint: '/organizations/$organizationId/members/$membershipId',
    );
  }

  Uri _buildUri(
    String path, {
    Map<String, String>? queryParameters,
  }) {
    final resolved = _baseUri.resolve(path);
    if (queryParameters == null || queryParameters.isEmpty) {
      return resolved;
    }
    return resolved.replace(queryParameters: queryParameters);
  }

  Map<String, dynamic> _decodeJsonObject(
    http.Response response, {
    required String endpoint,
  }) {
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw BackendApiException(
        'Backend request to $endpoint failed with '
        '${response.statusCode}: ${response.body}',
      );
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw BackendApiException(
        'Backend response for $endpoint was not a JSON object.',
      );
    }
    return decoded;
  }

  static Uri _normalizedBaseUri(String baseUrl) {
    final trimmed = baseUrl.trim();
    if (trimmed.isEmpty) {
      throw BackendApiException('Backend base URL cannot be empty.');
    }
    final normalized = trimmed.endsWith('/') ? trimmed : '$trimmed/';
    return Uri.parse(normalized);
  }
}

class BackendApiException implements Exception {
  const BackendApiException(this.message);

  final String message;

  @override
  String toString() => message;
}

const Map<String, String> _jsonHeaders = <String, String>{
  'Content-Type': 'application/json',
};
