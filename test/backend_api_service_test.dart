import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:material_guardian_mobile/services/backend_api_service.dart';

void main() {
  test('backend service uses one base URL source for health and future APIs', () async {
    final requests = <Uri>[];
    final service = BackendApiService(
      baseUrl: 'https://app-platforms-backend-dev-293518443128.us-east4.run.app',
      client: MockClient((request) async {
        requests.add(request.url);
        if (request.url.path.endsWith('/plans')) {
          return http.Response(
            '{"plans":[]}',
            200,
            headers: {'content-type': 'application/json'},
          );
        }
        return http.Response(
          '{"status":"ok","service":"app-platforms-backend","mode":"postgres"}',
          200,
          headers: {'content-type': 'application/json'},
        );
      }),
    );

    final health = await service.fetchHealth();
    await service.fetchPlans();
    await service.fetchMe(userId: 'user_owner');
    await service.fetchCurrentEntitlement(userId: 'user_owner');
    await service.fetchOrganizationSummary(
      organizationId: 'org_acme',
      userId: 'user_owner',
    );

    expect(health.mode, 'postgres');
    expect(
      requests.map((uri) => '${uri.scheme}://${uri.host}${uri.path}').toSet(),
      equals({
        'https://app-platforms-backend-dev-293518443128.us-east4.run.app/health',
        'https://app-platforms-backend-dev-293518443128.us-east4.run.app/plans',
        'https://app-platforms-backend-dev-293518443128.us-east4.run.app/me',
        'https://app-platforms-backend-dev-293518443128.us-east4.run.app/entitlements/current',
        'https://app-platforms-backend-dev-293518443128.us-east4.run.app/organizations/org_acme',
      }),
    );
  });
}
