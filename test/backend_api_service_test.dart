import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:material_guardian_mobile/services/backend_api_service.dart';

void main() {
  test('backend service uses one base URL source and bearer auth for account APIs', () async {
    final requests = <http.Request>[];
    final service = BackendApiService(
      baseUrl:
          'https://app-platforms-backend-dev-293518443128.us-east4.run.app',
      client: MockClient((request) async {
        requests.add(request);

        if (request.url.path.endsWith('/plans')) {
          return http.Response(
            '{"plans":[]}',
            200,
            headers: {'content-type': 'application/json'},
          );
        }

        if (request.url.path.endsWith('/auth/start')) {
          return http.Response(
            '{"flowId":"flow_1","deliveryTarget":"shop-admin@materialguardian.test","expiresAt":"2026-04-02T18:30:00.000Z","demoCode":"246810"}',
            200,
            headers: {'content-type': 'application/json'},
          );
        }

        if (request.url.path.endsWith('/auth/complete')) {
          return http.Response(
            '{"status":"authenticated","accessToken":"access-123","refreshToken":"refresh-123","user":{"id":"user_owner","email":"shop-admin@materialguardian.test","displayName":"Shop Admin","status":"active","createdAt":"2026-04-02T12:00:00.000Z","lastLoginAt":"2026-04-02T12:05:00.000Z"},"memberships":[],"activeEntitlement":{"productCode":"material_guardian","planCode":"material_guardian_individual_monthly","accessState":"paid","seatAvailability":"not_applicable","subscriptionState":"active","trialRemaining":0,"organizationId":null,"startsAt":"2026-04-02T12:00:00.000Z","endsAt":null},"session":{"id":"session_1","deviceLabel":"Kevin PowerShell","platform":"web","status":"active","issuedAt":"2026-04-02T12:05:00.000Z","lastSeenAt":"2026-04-02T12:05:00.000Z","revokedAt":null}}',
            200,
            headers: {'content-type': 'application/json'},
          );
        }

        if (request.url.path.endsWith('/auth/logout')) {
          return http.Response(
            '{"revokedSessionId":"session_1","revokedAt":"2026-04-02T12:06:00.000Z"}',
            200,
            headers: {'content-type': 'application/json'},
          );
        }

        if (request.url.path.endsWith('/organizations/org_acme')) {
          return http.Response(
            '{"id":"org_acme","name":"Acme Fabrication","status":"active","planCode":"material_guardian_business_monthly","seatLimit":5,"seatsAssigned":2,"seatsRemaining":3,"userCount":3,"members":[]}',
            200,
            headers: {'content-type': 'application/json'},
          );
        }

        if (request.url.path.endsWith('/entitlements/current')) {
          return http.Response(
            '{"productCode":"material_guardian","planCode":"material_guardian_individual_monthly","accessState":"paid","seatAvailability":"not_applicable","subscriptionState":"active","trialRemaining":0,"organizationId":null,"startsAt":"2026-04-02T12:00:00.000Z","endsAt":null}',
            200,
            headers: {'content-type': 'application/json'},
          );
        }

        if (request.url.path.endsWith('/me')) {
          return http.Response(
            '{"user":{"id":"user_owner","email":"shop-admin@materialguardian.test","displayName":"Shop Admin","status":"active","createdAt":"2026-04-02T12:00:00.000Z","lastLoginAt":"2026-04-02T12:05:00.000Z"},"memberships":[],"currentSeatAssignment":{"organizationId":null,"status":"not_applicable"},"trialState":null,"activeEntitlement":{"productCode":"material_guardian","planCode":"material_guardian_individual_monthly","accessState":"paid","seatAvailability":"not_applicable","subscriptionState":"active","trialRemaining":0,"organizationId":null,"startsAt":"2026-04-02T12:00:00.000Z","endsAt":null},"activeSession":{"id":"session_1","deviceLabel":"Kevin PowerShell","platform":"web","status":"active","issuedAt":"2026-04-02T12:05:00.000Z","lastSeenAt":"2026-04-02T12:05:00.000Z","revokedAt":null}}',
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
    final authStart = await service.startAuth(
      email: 'shop-admin@materialguardian.test',
      displayName: 'Shop Admin',
    );
    final auth = await service.completeAuth(
      flowId: authStart.flowId,
      email: authStart.deliveryTarget,
      code: authStart.demoCode,
      deviceLabel: 'Kevin PowerShell',
      platform: 'web',
    );
    await service.fetchPlans();
    await service.fetchMe(accessToken: auth.accessToken!);
    await service.fetchCurrentEntitlement(accessToken: auth.accessToken!);
    await service.fetchOrganizationSummary(
      organizationId: 'org_acme',
      accessToken: auth.accessToken!,
    );
    await service.logout(accessToken: auth.accessToken!);

    expect(health.mode, 'postgres');
    expect(auth.isAuthenticated, isTrue);
    expect(
      requests
          .map(
            (request) =>
                '${request.url.scheme}://${request.url.host}${request.url.path}',
          )
          .toSet(),
      equals({
        'https://app-platforms-backend-dev-293518443128.us-east4.run.app/health',
        'https://app-platforms-backend-dev-293518443128.us-east4.run.app/auth/start',
        'https://app-platforms-backend-dev-293518443128.us-east4.run.app/auth/complete',
        'https://app-platforms-backend-dev-293518443128.us-east4.run.app/plans',
        'https://app-platforms-backend-dev-293518443128.us-east4.run.app/me',
        'https://app-platforms-backend-dev-293518443128.us-east4.run.app/entitlements/current',
        'https://app-platforms-backend-dev-293518443128.us-east4.run.app/organizations/org_acme',
        'https://app-platforms-backend-dev-293518443128.us-east4.run.app/auth/logout',
      }),
    );

    final authedPaths = requests
        .where(
          (request) =>
              request.url.path != '/health' &&
              request.url.path != '/plans' &&
              request.url.path != '/auth/start' &&
              request.url.path != '/auth/complete',
        )
        .toList(growable: false);
    for (final request in authedPaths) {
      expect(request.headers['authorization'], 'Bearer access-123');
    }
  });
}
