import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:image/image.dart' as img;
import 'package:material_guardian_mobile/app/material_guardian_app.dart';
import 'package:material_guardian_mobile/app/models.dart';
import 'package:material_guardian_mobile/app/material_guardian_state.dart';
import 'package:material_guardian_mobile/app/routes.dart';
import 'package:material_guardian_mobile/data/backend_auth_session_store.dart';
import 'package:material_guardian_mobile/screens/account_screen.dart';
import 'package:material_guardian_mobile/screens/customization_screen.dart';
import 'package:material_guardian_mobile/screens/job_detail_screen.dart';
import 'package:material_guardian_mobile/screens/jobs_screen.dart';
import 'package:material_guardian_mobile/screens/material_form_screen.dart';
import 'package:material_guardian_mobile/screens/privacy_policy_screen.dart';
import 'package:material_guardian_mobile/screens/sales_screen.dart';
import 'package:material_guardian_mobile/services/backend_api_service.dart';
import 'package:material_guardian_mobile/services/storage_utils.dart';
import 'package:material_guardian_mobile/services/store_purchase_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

const MethodChannel _pathProviderChannel = MethodChannel(
  'plugins.flutter.io/path_provider',
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    final testDirectory = Directory(
      '${Directory.systemTemp.path}/material_guardian_mobile_test',
    );
    await testDirectory.create(recursive: true);

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_pathProviderChannel, (call) async {
          if (call.method == 'getApplicationSupportDirectory') {
            return testDirectory.path;
          }
          return null;
        });
  });

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  tearDownAll(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_pathProviderChannel, null);
  });

  testWidgets('jobs shell opens donor-style draft flow from job detail', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: JobsScreen(appState: MaterialGuardianAppState.seeded()),
        onGenerateRoute: (settings) {
          if (settings.name == AppRoutes.jobDetail) {
            final args = settings.arguments! as JobDetailRouteArgs;
            return MaterialPageRoute<void>(
              builder: (_) => JobDetailScreen(
                appState: MaterialGuardianAppState.seeded(),
                jobId: args.jobId,
              ),
              settings: settings,
            );
          }
          return null;
        },
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Create Job'), findsOneWidget);
    expect(find.text('Current Jobs'), findsOneWidget);
    expect(find.text('Drafts (1)'), findsNothing);

    final firstJob = find.text('Job# MG-24031');
    await tester.ensureVisible(firstJob);
    await tester.tap(firstJob);
    await tester.pumpAndSettle();

    expect(find.text('MG-24031'), findsOneWidget);
    expect(find.text('Resume Draft'), findsOneWidget);
  });

  testWidgets('signed-out launch gate lands on sales instead of jobs', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialGuardianApp(appState: MaterialGuardianAppState.seeded()),
    );
    await tester.pump(const Duration(seconds: 4));
    await tester.pumpAndSettle();

    expect(find.text('Material Guardian'), findsOneWidget);
    expect(find.text('Try your first 6 free jobs now'), findsOneWidget);
    expect(find.text('Create Job'), findsNothing);
  });

  testWidgets('sales screen clamps long email, name, and code input', (
    tester,
  ) async {
    final service = BackendApiService(
      baseUrl:
          'https://app-platforms-backend-dev-293518443128.us-east4.run.app',
      client: MockClient((request) async {
        if (request.url.path.endsWith('/auth/start')) {
          return http.Response(
            '{"flowId":"flow_sales","deliveryTarget":"trial@materialguardian.test","expiresAt":"2026-04-03T18:30:00.000Z","demoCode":"246810"}',
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
    final appState = MaterialGuardianAppState.seeded(
      backendApiService: service,
      authSessionStore: InMemoryBackendAuthSessionStore(),
    );

    await tester.pumpWidget(MaterialApp(home: SalesScreen(appState: appState)));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Start Free Trial'));
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.text('Start Your Free Trial'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    Finder textFieldByLabel(String label) {
      return find.byWidgetPredicate(
        (widget) =>
            widget is TextField && widget.decoration?.labelText == label,
      );
    }

    final emailField = textFieldByLabel('Email');
    final nameField = textFieldByLabel('Personal Name (optional)');

    await tester.enterText(emailField, 'a' * 150);
    await tester.enterText(nameField, 'b' * 60);
    await tester.pump();

    expect(tester.widget<TextField>(emailField).controller?.text.length, 120);
    expect(tester.widget<TextField>(nameField).controller?.text.length, 40);

    await tester.enterText(emailField, 'trial@materialguardian.test');
    await tester.enterText(nameField, 'Trial User');
    await tester.pump();

    await appState.startBackendSignIn(
      email: 'trial@materialguardian.test',
      displayName: 'Trial User',
    );
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.text('Enter Your Code'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    final codeField = textFieldByLabel('Code');
    await tester.enterText(codeField, '12345678901234567890');
    await tester.pump();

    expect(tester.widget<TextField>(codeField).controller?.text.length, 12);
  });

  testWidgets('account screen stays stable on tablet width for a signed-in admin', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1600, 2560);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final sessionStore = InMemoryBackendAuthSessionStore();
    final service = BackendApiService(
      baseUrl:
          'https://app-platforms-backend-dev-293518443128.us-east4.run.app',
      client: MockClient((request) async {
        if (request.url.path.endsWith('/auth/start')) {
          return http.Response(
            '{"flowId":"flow_1","deliveryTarget":"shop-admin@materialguardian.test","expiresAt":"2026-04-02T18:30:00.000Z","demoCode":"246810"}',
            200,
            headers: {'content-type': 'application/json'},
          );
        }
        if (request.url.path.endsWith('/auth/complete')) {
          return http.Response(
            '{"status":"authenticated","accessToken":"access-123","refreshToken":"refresh-123","user":{"id":"user_owner","email":"shop-admin@materialguardian.test","displayName":"Shop Admin","status":"active","createdAt":"2026-04-02T12:00:00.000Z","lastLoginAt":"2026-04-02T12:05:00.000Z"},"memberships":[{"id":"membership_owner","organizationId":"org_acme","organizationName":"Acme Fabrication","role":"owner","seatStatus":"assigned","invitedAt":"2026-04-02T12:00:00.000Z","acceptedAt":"2026-04-02T12:01:00.000Z"}],"activeEntitlement":{"productCode":"material_guardian","planCode":"material_guardian_business_monthly","accessState":"paid","seatAvailability":"assigned","subscriptionState":"active","trialRemaining":0,"organizationId":"org_acme","startsAt":"2026-04-02T12:00:00.000Z","endsAt":null},"session":{"id":"session_1","deviceLabel":"Kevin PowerShell","platform":"web","status":"active","issuedAt":"2026-04-02T12:05:00.000Z","lastSeenAt":"2026-04-02T12:05:00.000Z","revokedAt":null}}',
            200,
            headers: {'content-type': 'application/json'},
          );
        }
        if (request.url.path.endsWith('/me')) {
          return http.Response(
            '{"user":{"id":"user_owner","email":"shop-admin@materialguardian.test","displayName":"Shop Admin","status":"active","createdAt":"2026-04-02T12:00:00.000Z","lastLoginAt":"2026-04-02T12:05:00.000Z"},"memberships":[{"id":"membership_owner","organizationId":"org_acme","organizationName":"Acme Fabrication","role":"owner","seatStatus":"assigned","invitedAt":"2026-04-02T12:00:00.000Z","acceptedAt":"2026-04-02T12:01:00.000Z"}],"currentSeatAssignment":{"organizationId":"org_acme","status":"assigned"},"trialState":null,"activeEntitlement":{"productCode":"material_guardian","planCode":"material_guardian_business_monthly","accessState":"paid","seatAvailability":"assigned","subscriptionState":"active","trialRemaining":0,"organizationId":"org_acme","startsAt":"2026-04-02T12:00:00.000Z","endsAt":null},"activeSession":{"id":"session_1","deviceLabel":"Kevin PowerShell","platform":"web","status":"active","issuedAt":"2026-04-02T12:05:00.000Z","lastSeenAt":"2026-04-02T12:05:00.000Z","revokedAt":null}}',
            200,
            headers: {'content-type': 'application/json'},
          );
        }
        if (request.url.path.endsWith('/entitlements/current')) {
          return http.Response(
            '{"productCode":"material_guardian","planCode":"material_guardian_business_monthly","accessState":"paid","seatAvailability":"assigned","subscriptionState":"active","trialRemaining":0,"organizationId":"org_acme","startsAt":"2026-04-02T12:00:00.000Z","endsAt":null}',
            200,
            headers: {'content-type': 'application/json'},
          );
        }
        if (request.url.path.endsWith('/organizations/org_acme')) {
          return http.Response(
            '{"id":"org_acme","name":"Acme Fabrication","status":"active","planCode":"material_guardian_business_monthly","seatLimit":5,"seatsAssigned":2,"seatsRemaining":3,"userCount":3,"members":[{"membershipId":"membership_owner","userId":"user_owner","name":"Shop Admin","email":"shop-admin@materialguardian.test","userStatus":"active","role":"owner","seatStatus":"assigned","seatAssigned":true,"invitedAt":"2026-04-02T12:00:00.000Z","acceptedAt":"2026-04-02T12:01:00.000Z","lastActive":"2026-04-02T12:05:00.000Z","activeDeviceSummary":"Kevin PowerShell"}]}',
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
    final appState = MaterialGuardianAppState.seeded(
      backendApiService: service,
      authSessionStore: sessionStore,
    );

    await appState.startBackendSignIn(
      email: 'shop-admin@materialguardian.test',
      displayName: 'Shop Admin',
    );
    await appState.completeBackendSignIn(code: '246810');

    await tester.pumpWidget(
      MaterialApp(home: AccountScreen(appState: appState)),
    );
    await tester.pumpAndSettle();

    expect(find.text('Recovery'), findsOneWidget);
    expect(find.text('Acme Fabrication'), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('create job dialog clamps long text input', (tester) async {
    final sessionStore = InMemoryBackendAuthSessionStore();
    final service = BackendApiService(
      baseUrl:
          'https://app-platforms-backend-dev-293518443128.us-east4.run.app',
      client: MockClient((request) async {
        if (request.url.path.endsWith('/auth/start')) {
          return http.Response(
            '{"flowId":"flow_jobs","deliveryTarget":"jobs@materialguardian.test","expiresAt":"2026-04-02T18:30:00.000Z","demoCode":"246810"}',
            200,
            headers: {'content-type': 'application/json'},
          );
        }
        if (request.url.path.endsWith('/auth/complete')) {
          return http.Response(
            '{"status":"authenticated","accessToken":"access-jobs","refreshToken":"refresh-jobs","user":{"id":"user_jobs","email":"jobs@materialguardian.test","displayName":"Jobs User","status":"active","createdAt":"2026-04-02T12:00:00.000Z","lastLoginAt":"2026-04-02T12:05:00.000Z"},"memberships":[],"activeEntitlement":{"productCode":"material_guardian","planCode":null,"accessState":"trial","seatAvailability":"not_applicable","subscriptionState":"trial","trialRemaining":6,"organizationId":null,"startsAt":"2026-04-02T12:00:00.000Z","endsAt":null},"session":{"id":"session_jobs","deviceLabel":"Kevin PowerShell","platform":"web","status":"active","issuedAt":"2026-04-02T12:05:00.000Z","lastSeenAt":"2026-04-02T12:05:00.000Z","revokedAt":null}}',
            200,
            headers: {'content-type': 'application/json'},
          );
        }
        if (request.url.path.endsWith('/me')) {
          return http.Response(
            '{"user":{"id":"user_jobs","email":"jobs@materialguardian.test","displayName":"Jobs User","status":"active","createdAt":"2026-04-02T12:00:00.000Z","lastLoginAt":"2026-04-02T12:05:00.000Z"},"memberships":[],"currentSeatAssignment":{"organizationId":null,"status":"not_applicable"},"trialState":{"productCode":"material_guardian","jobsAllowed":6,"jobsUsed":0,"jobsRemaining":6,"status":"active"},"activeEntitlement":{"productCode":"material_guardian","planCode":null,"accessState":"trial","seatAvailability":"not_applicable","subscriptionState":"trial","trialRemaining":6,"organizationId":null,"startsAt":"2026-04-02T12:00:00.000Z","endsAt":null},"activeSession":{"id":"session_jobs","deviceLabel":"Kevin PowerShell","platform":"web","status":"active","issuedAt":"2026-04-02T12:05:00.000Z","lastSeenAt":"2026-04-02T12:05:00.000Z","revokedAt":null}}',
            200,
            headers: {'content-type': 'application/json'},
          );
        }
        if (request.url.path.endsWith('/entitlements/current')) {
          return http.Response(
            '{"productCode":"material_guardian","planCode":null,"accessState":"trial","seatAvailability":"not_applicable","subscriptionState":"trial","trialRemaining":6,"organizationId":null,"startsAt":"2026-04-02T12:00:00.000Z","endsAt":null}',
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
    final appState = MaterialGuardianAppState.seeded(
      backendApiService: service,
      authSessionStore: sessionStore,
    );
    await appState.startBackendSignIn(
      email: 'jobs@materialguardian.test',
      displayName: 'Jobs User',
    );
    await appState.completeBackendSignIn(code: '246810');

    await tester.pumpWidget(MaterialApp(home: JobsScreen(appState: appState)));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Create Job'));
    await tester.pumpAndSettle();

    final jobNumberField = find.byType(TextField).at(0);
    final descriptionField = find.byType(TextField).at(1);
    final notesField = find.byType(TextField).at(2);

    await tester.enterText(jobNumberField, 'J' * 40);
    await tester.enterText(descriptionField, 'D' * 80);
    await tester.enterText(notesField, 'N' * 200);
    await tester.pump();

    expect(
      tester
          .widget<EditableText>(find.byType(EditableText).at(0))
          .controller
          .text
          .length,
      24,
    );
    expect(
      tester
          .widget<EditableText>(find.byType(EditableText).at(1))
          .controller
          .text
          .length,
      60,
    );
    expect(
      tester
          .widget<EditableText>(find.byType(EditableText).at(2))
          .controller
          .text
          .length,
      120,
    );
  });

  testWidgets('create job dialog can save a job without throwing', (
    tester,
  ) async {
    final sessionStore = InMemoryBackendAuthSessionStore();
    final service = BackendApiService(
      baseUrl:
          'https://app-platforms-backend-dev-293518443128.us-east4.run.app',
      client: MockClient((request) async {
        if (request.url.path.endsWith('/auth/start')) {
          return http.Response(
            '{"flowId":"flow_jobs_create","deliveryTarget":"create@materialguardian.test","expiresAt":"2026-04-02T18:30:00.000Z","demoCode":"246810"}',
            200,
            headers: {'content-type': 'application/json'},
          );
        }
        if (request.url.path.endsWith('/auth/complete')) {
          return http.Response(
            '{"status":"authenticated","accessToken":"access-create","refreshToken":"refresh-create","user":{"id":"user_create","email":"create@materialguardian.test","displayName":"Create User","status":"active","createdAt":"2026-04-02T12:00:00.000Z","lastLoginAt":"2026-04-02T12:05:00.000Z"},"memberships":[],"activeEntitlement":{"productCode":"material_guardian","planCode":null,"accessState":"trial","seatAvailability":"not_applicable","subscriptionState":"trial","trialRemaining":6,"organizationId":null,"startsAt":"2026-04-02T12:00:00.000Z","endsAt":null},"session":{"id":"session_create","deviceLabel":"Kevin PowerShell","platform":"web","status":"active","issuedAt":"2026-04-02T12:05:00.000Z","lastSeenAt":"2026-04-02T12:05:00.000Z","revokedAt":null}}',
            200,
            headers: {'content-type': 'application/json'},
          );
        }
        if (request.url.path.endsWith('/me')) {
          return http.Response(
            '{"user":{"id":"user_create","email":"create@materialguardian.test","displayName":"Create User","status":"active","createdAt":"2026-04-02T12:00:00.000Z","lastLoginAt":"2026-04-02T12:05:00.000Z"},"memberships":[],"currentSeatAssignment":{"organizationId":null,"status":"not_applicable"},"trialState":{"productCode":"material_guardian","jobsAllowed":6,"jobsUsed":0,"jobsRemaining":6,"status":"active"},"activeEntitlement":{"productCode":"material_guardian","planCode":null,"accessState":"trial","seatAvailability":"not_applicable","subscriptionState":"trial","trialRemaining":6,"organizationId":null,"startsAt":"2026-04-02T12:00:00.000Z","endsAt":null},"activeSession":{"id":"session_create","deviceLabel":"Kevin PowerShell","platform":"web","status":"active","issuedAt":"2026-04-02T12:05:00.000Z","lastSeenAt":"2026-04-02T12:05:00.000Z","revokedAt":null}}',
            200,
            headers: {'content-type': 'application/json'},
          );
        }
        if (request.url.path.endsWith('/entitlements/current')) {
          return http.Response(
            '{"productCode":"material_guardian","planCode":null,"accessState":"trial","seatAvailability":"not_applicable","subscriptionState":"trial","trialRemaining":6,"organizationId":null,"startsAt":"2026-04-02T12:00:00.000Z","endsAt":null}',
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
    final appState = MaterialGuardianAppState.seeded(
      backendApiService: service,
      authSessionStore: sessionStore,
    );
    await appState.startBackendSignIn(
      email: 'create@materialguardian.test',
      displayName: 'Create User',
    );
    await appState.completeBackendSignIn(code: '246810');

    await tester.pumpWidget(MaterialApp(home: JobsScreen(appState: appState)));
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(FilledButton, 'Create Job'));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byWidgetPredicate(
        (widget) =>
            widget is TextField && widget.decoration?.labelText == 'Job Number',
      ),
      'STRESS01',
    );
    await tester.enterText(
      find.byWidgetPredicate(
        (widget) =>
            widget is TextField &&
            widget.decoration?.labelText == 'Description',
      ),
      'PhoneFlow',
    );
    await tester.enterText(
      find.byWidgetPredicate(
        (widget) =>
            widget is TextField && widget.decoration?.labelText == 'Notes',
      ),
      'Stress',
    );

    await tester.tap(find.widgetWithText(FilledButton, 'Create'));
    await tester.pumpAndSettle();

    expect(appState.jobs.any((job) => job.jobNumber == 'STRESS01'), isTrue);
    expect(tester.takeException(), isNull);
  });

  test('creating a new trial job consumes one backend free job', () async {
    final sessionStore = InMemoryBackendAuthSessionStore();
    var jobsUsed = 0;
    final service = BackendApiService(
      baseUrl:
          'https://app-platforms-backend-dev-293518443128.us-east4.run.app',
      client: MockClient((request) async {
        if (request.url.path.endsWith('/auth/start')) {
          return http.Response(
            '{"flowId":"flow_consume","deliveryTarget":"consume@materialguardian.test","expiresAt":"2026-04-02T18:30:00.000Z","demoCode":"246810"}',
            200,
            headers: {'content-type': 'application/json'},
          );
        }
        if (request.url.path.endsWith('/auth/complete')) {
          return http.Response(
            '{"status":"authenticated","accessToken":"access-consume","refreshToken":"refresh-consume","user":{"id":"user_consume","email":"consume@materialguardian.test","displayName":"Consume User","status":"active","createdAt":"2026-04-02T12:00:00.000Z","lastLoginAt":"2026-04-02T12:05:00.000Z"},"memberships":[],"activeEntitlement":{"productCode":"material_guardian","planCode":null,"accessState":"trial","seatAvailability":"not_applicable","subscriptionState":"trial","trialRemaining":6,"organizationId":null,"startsAt":"2026-04-02T12:00:00.000Z","endsAt":null},"session":{"id":"session_consume","deviceLabel":"Kevin PowerShell","platform":"web","status":"active","issuedAt":"2026-04-02T12:05:00.000Z","lastSeenAt":"2026-04-02T12:05:00.000Z","revokedAt":null}}',
            200,
            headers: {'content-type': 'application/json'},
          );
        }
        if (request.url.path.endsWith('/me')) {
          return http.Response(
            '{"user":{"id":"user_consume","email":"consume@materialguardian.test","displayName":"Consume User","status":"active","createdAt":"2026-04-02T12:00:00.000Z","lastLoginAt":"2026-04-02T12:05:00.000Z"},"memberships":[],"currentSeatAssignment":{"organizationId":null,"status":"not_applicable"},"trialState":{"productCode":"material_guardian","jobsAllowed":6,"jobsUsed":$jobsUsed,"jobsRemaining":${6 - jobsUsed},"status":"${jobsUsed >= 6 ? 'exhausted' : 'active'}"},"activeEntitlement":{"productCode":"material_guardian","planCode":null,"accessState":"${jobsUsed >= 6 ? 'locked' : 'trial'}","seatAvailability":"not_applicable","subscriptionState":"${jobsUsed >= 6 ? 'inactive' : 'trial'}","trialRemaining":${jobsUsed >= 6 ? 0 : 6 - jobsUsed},"organizationId":null,"startsAt":"2026-04-02T12:00:00.000Z","endsAt":null},"activeSession":{"id":"session_consume","deviceLabel":"Kevin PowerShell","platform":"web","status":"active","issuedAt":"2026-04-02T12:05:00.000Z","lastSeenAt":"2026-04-02T12:05:00.000Z","revokedAt":null}}',
            200,
            headers: {'content-type': 'application/json'},
          );
        }
        if (request.url.path.endsWith('/entitlements/current')) {
          return http.Response(
            '{"productCode":"material_guardian","planCode":null,"accessState":"${jobsUsed >= 6 ? 'locked' : 'trial'}","seatAvailability":"not_applicable","subscriptionState":"${jobsUsed >= 6 ? 'inactive' : 'trial'}","trialRemaining":${jobsUsed >= 6 ? 0 : 6 - jobsUsed},"organizationId":null,"startsAt":"2026-04-02T12:00:00.000Z","endsAt":null}',
            200,
            headers: {'content-type': 'application/json'},
          );
        }
        if (request.url.path.endsWith('/trials/consume-job')) {
          jobsUsed += 1;
          return http.Response(
            '{"trialState":{"productCode":"material_guardian","jobsAllowed":6,"jobsUsed":$jobsUsed,"jobsRemaining":${6 - jobsUsed},"status":"${jobsUsed >= 6 ? 'exhausted' : 'active'}"},"activeEntitlement":{"productCode":"material_guardian","planCode":null,"accessState":"${jobsUsed >= 6 ? 'locked' : 'trial'}","seatAvailability":"not_applicable","subscriptionState":"${jobsUsed >= 6 ? 'inactive' : 'trial'}","trialRemaining":${jobsUsed >= 6 ? 0 : 6 - jobsUsed},"organizationId":null,"startsAt":"2026-04-02T12:00:00.000Z","endsAt":null}}',
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
    final appState = MaterialGuardianAppState.seeded(
      backendApiService: service,
      authSessionStore: sessionStore,
    );
    await appState.startBackendSignIn(
      email: 'consume@materialguardian.test',
      displayName: 'Consume User',
    );
    await appState.completeBackendSignIn(code: '246810');

    await appState.saveJob(
      jobNumber: 'TRIAL-001',
      description: 'Trial job one',
      notes: '',
    );

    expect(jobsUsed, 1);
    expect(appState.jobs.any((job) => job.jobNumber == 'TRIAL-001'), isTrue);
    expect(appState.effectiveBackendEntitlement?.trialRemaining, 5);
    expect(appState.backendMe?.trialState?.jobsRemaining, 5);
  });

  test('deleteJob removes job support folders and export zip', () async {
    final appState = MaterialGuardianAppState.seeded();
    final safeJobNumber = safeBaseName('MG-24031', fallback: 'job');
    final exportDirectory = await appSupportSubdirectory([
      'exports',
      safeJobNumber,
    ]);
    await exportDirectory.create(recursive: true);
    final exportPacket = File('${exportDirectory.path}\\$safeJobNumber.pdf');
    await exportPacket.writeAsString('packet');
    final exportZip = File('${exportDirectory.path}\\$safeJobNumber.zip');
    await exportZip.writeAsString('zip');

    final mediaDirectory = await appSupportSubdirectory([
      'job_media',
      safeJobNumber,
      'photos',
    ]);
    await mediaDirectory.create(recursive: true);
    final mediaFile = File('${mediaDirectory.path}\\v_101_photo_1.jpg');
    await mediaFile.writeAsString('photo');

    await appState.deleteJob('job-1001');

    expect(await exportDirectory.exists(), isFalse);
    expect(await exportZip.exists(), isFalse);
    expect(await mediaDirectory.parent.exists(), isFalse);
    expect(appState.jobs.where((job) => job.id == 'job-1001'), isEmpty);
  });

  test(
    'deleteDraft removes job media but keeps shared customization assets',
    () async {
      final appState = MaterialGuardianAppState.seeded();
      final safeJobNumber = safeBaseName('MG-24031', fallback: 'job');
      final photoDirectory = await appSupportSubdirectory([
        'job_media',
        safeJobNumber,
        'photos',
      ]);
      await photoDirectory.create(recursive: true);
      final photoFile = File('${photoDirectory.path}\\draft_photo_1.jpg');
      final photoImage = img.Image(width: 12, height: 12);
      img.fill(photoImage, color: img.ColorRgb8(210, 210, 210));
      await photoFile.writeAsBytes(
        img.encodeJpg(photoImage, quality: 90),
        flush: true,
      );

      final customizationDirectory = await appSupportSubdirectory([
        'customization',
      ]);
      await customizationDirectory.create(recursive: true);
      final sharedSignature = File(
        '${customizationDirectory.path}\\default_qc_inspector_signature.png',
      );
      await sharedSignature.writeAsString('signature');

      final draft = await appState.createBlankDraft(jobId: 'job-1001');
      await appState.saveDraft(
        draft.copyWith(
          photoPaths: [photoFile.path],
          qcSignaturePath: sharedSignature.path,
        ),
      );

      await appState.deleteDraft(draft.id);

      expect(await photoFile.exists(), isFalse);
      expect(await photoDirectory.exists(), isFalse);
      expect(await sharedSignature.exists(), isTrue);
      expect(appState.drafts.where((item) => item.id == draft.id), isEmpty);
    },
  );

  test(
    'deleteJob does not delete the shared customization signature root',
    () async {
      final appState = MaterialGuardianAppState.seeded();
      final customizationDirectory = await appSupportSubdirectory([
        'customization',
      ]);
      await customizationDirectory.create(recursive: true);
      final sharedSignature = File(
        '${customizationDirectory.path}\\default_qc_inspector_signature.png',
      );
      await sharedSignature.writeAsString('signature');
      final sentinel = File('${customizationDirectory.path}\\keep.txt');
      await sentinel.writeAsString('keep');

      final editDraft = await appState.createEditDraft(
        jobId: 'job-1001',
        materialId: 'mat-001',
      );
      await appState.saveDraft(
        editDraft.copyWith(qcSignaturePath: sharedSignature.path),
      );
      await appState.completeDraft(appState.draftById(editDraft.id));

      await appState.deleteJob('job-1001');

      expect(await customizationDirectory.exists(), isTrue);
      expect(await sentinel.exists(), isTrue);
    },
  );

  test(
    'deleteMaterial removes media folders and stale export artifacts',
    () async {
      final appState = MaterialGuardianAppState.seeded();
      final safeJobNumber = safeBaseName('MG-24031', fallback: 'job');
      final photoDirectory = await appSupportSubdirectory([
        'job_media',
        safeJobNumber,
        'photos',
      ]);
      await photoDirectory.create(recursive: true);
      final photoFile = File('${photoDirectory.path}\\mat_001_photo_1.jpg');
      final photoImage = img.Image(width: 12, height: 12);
      img.fill(photoImage, color: img.ColorRgb8(230, 230, 230));
      await photoFile.writeAsBytes(
        img.encodeJpg(photoImage, quality: 90),
        flush: true,
      );

      final editDraft = await appState.createEditDraft(
        jobId: 'job-1001',
        materialId: 'mat-001',
      );
      await appState.saveDraft(
        editDraft.copyWith(photoPaths: [photoFile.path]),
      );
      await appState.completeDraft(appState.draftById(editDraft.id));

      final exportResult = await appState.exportJob('job-1001');
      final exportedMaterial = appState.materialById(
        jobId: 'job-1001',
        materialId: 'mat-001',
      );

      expect(await File(exportedMaterial.pdfStoragePath).exists(), isTrue);
      expect(await Directory(exportResult.exportRootPath).exists(), isTrue);
      expect(await File(exportResult.zipPath).exists(), isTrue);

      await appState.deleteMaterial(jobId: 'job-1001', materialId: 'mat-001');

      expect(await photoFile.exists(), isFalse);
      expect(await File(exportedMaterial.pdfStoragePath).exists(), isFalse);
      expect(await Directory(exportResult.exportRootPath).exists(), isFalse);
      expect(await File(exportResult.zipPath).exists(), isFalse);
      expect(
        () => appState.materialById(jobId: 'job-1001', materialId: 'mat-001'),
        throwsA(isA<StateError>()),
      );
    },
  );

  test(
    'deleteMaterial preserves sibling material media in the same job',
    () async {
      final appState = MaterialGuardianAppState.seeded();
      final safeJobNumber = safeBaseName('MG-24031', fallback: 'job');
      final photoDirectory = await appSupportSubdirectory([
        'job_media',
        safeJobNumber,
        'photos',
      ]);
      await photoDirectory.create(recursive: true);

      final targetPhoto = File('${photoDirectory.path}\\mat_001_photo_1.jpg');
      final siblingPhoto = File('${photoDirectory.path}\\mat_002_photo_1.jpg');
      final previewImage = img.Image(width: 12, height: 12);
      img.fill(previewImage, color: img.ColorRgb8(230, 230, 230));
      final encodedPhoto = img.encodeJpg(previewImage, quality: 90);
      await targetPhoto.writeAsBytes(encodedPhoto, flush: true);
      await siblingPhoto.writeAsBytes(encodedPhoto, flush: true);

      final targetDraft = await appState.createEditDraft(
        jobId: 'job-1001',
        materialId: 'mat-001',
      );
      await appState.saveDraft(
        targetDraft.copyWith(photoPaths: [targetPhoto.path]),
      );
      await appState.completeDraft(appState.draftById(targetDraft.id));

      final siblingDraft = await appState.createBlankDraft(jobId: 'job-1001');
      await appState.saveDraft(
        siblingDraft.copyWith(
          materialTag: 'V-102',
          description: '4" gate valve',
          vendor: 'NEMO Overlay',
          poNumber: 'PO-24031',
          productType: 'Valve',
          specificationPrefix: 'SA',
          gradeType: '105',
          fittingStandard: 'B16.34',
          unitSystem: UnitSystem.imperial,
          quantity: '1',
          diameter: '4',
          diameterType: 'Nominal',
          b16Size: 'Accept',
          markingAcceptable: true,
          markingSelected: true,
          mtrAcceptable: true,
          mtrSelected: true,
          photoPaths: [siblingPhoto.path],
        ),
      );
      await appState.completeDraft(appState.draftById(siblingDraft.id));

      await appState.deleteMaterial(jobId: 'job-1001', materialId: 'mat-001');

      expect(await targetPhoto.exists(), isFalse);
      expect(await siblingPhoto.exists(), isTrue);
      expect(
        appState.jobs
            .singleWhere((job) => job.id == 'job-1001')
            .materials
            .singleWhere((material) => material.tag == 'V-102')
            .photoPaths,
        [siblingPhoto.path],
      );
    },
  );

  testWidgets(
    'privacy policy reflects backend-managed accounts and current Android scope',
    (tester) async {
      await tester.pumpWidget(const MaterialApp(home: PrivacyPolicyScreen()));
      await tester.pumpAndSettle();

      expect(find.textContaining('Welders Helper'), findsOneWidget);

      await tester.scrollUntilVisible(
        find.text('Data handled by the service'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      expect(find.text('Data handled by the service'), findsOneWidget);
      expect(
        find.textContaining('organization and seat information'),
        findsOneWidget,
      );
      await tester.scrollUntilVisible(
        find.text('Data that stays on your device'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      expect(find.text('Data that stays on your device'), findsOneWidget);
      expect(
        find.textContaining(
          'Cloud file sync and cross-device recovery for those files are not part of the current release behavior.',
        ),
        findsOneWidget,
      );
    },
  );

  testWidgets('material form keeps donor field caps for report alignment', (
    tester,
  ) async {
    final appState = MaterialGuardianAppState.seeded();

    await tester.pumpWidget(
      MaterialApp(
        home: MaterialFormScreen(
          appState: appState,
          jobId: 'job-1001',
          draftId: 'draft-001',
        ),
      ),
    );
    await tester.pumpAndSettle();

    Finder textFieldByLabel(String label) {
      return find.byWidgetPredicate(
        (widget) =>
            widget is TextField && widget.decoration?.labelText == label,
      );
    }

    final descriptionField = textFieldByLabel('Material Description');
    final poField = textFieldByLabel('PO #');
    final quantityField = textFieldByLabel('Qty');
    final qcManagerField = textFieldByLabel('QC Manager');
    final markingsField = textFieldByLabel('Markings found');
    final lengthField = textFieldByLabel('Length');

    await tester.enterText(descriptionField, 'X' * 60);
    await tester.enterText(poField, 'P' * 30);
    await tester.enterText(quantityField, '123456789');
    expect(
      tester.widget<TextField>(descriptionField).controller?.text,
      'X' * 40,
    );
    expect(tester.widget<TextField>(poField).controller?.text, 'P' * 20);
    expect(tester.widget<TextField>(quantityField).controller?.text, '123456');

    await tester.scrollUntilVisible(
      find.text('Actual Surface Finish Reading'),
      250,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    expect(find.text('Actual Surface Finish Reading'), findsOneWidget);
    expect(find.text('Actual Markings'), findsOneWidget);
    expect(find.text('B16 Dimensions acceptable'), findsOneWidget);
    expect(find.text('u-in'), findsOneWidget);
    expect(tester.widget<TextField>(markingsField).maxLines, 5);
    expect(
      tester.widget<TextField>(lengthField).keyboardType,
      TextInputType.text,
    );
    expect(
      tester.widget<TextField>(lengthField).decoration?.suffixText,
      isNull,
    );

    await tester.drag(find.byType(Scrollable).first, const Offset(0, -900));
    await tester.pumpAndSettle();
    await tester.drag(find.byType(Scrollable).first, const Offset(0, -900));
    await tester.pumpAndSettle();
    await tester.enterText(qcManagerField, 'ManagerNameTooLongForDonorParity');
    await tester.pump();

    expect(
      tester.widget<TextField>(qcManagerField).controller?.text,
      'ManagerNameTooLongFo',
    );
  });

  testWidgets('material form strips import and preview signature controls', (
    tester,
  ) async {
    final appState = MaterialGuardianAppState.seeded();

    await tester.pumpWidget(
      MaterialApp(
        home: MaterialFormScreen(
          appState: appState,
          jobId: 'job-1001',
          draftId: 'draft-001',
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.text('QC Inspector Signature'),
      250,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    expect(find.text('QC Inspector Signature'), findsOneWidget);
    expect(find.text('QC Manager Signature'), findsOneWidget);
    expect(find.text('Import Inspector Signature'), findsNothing);
    expect(find.text('Preview Inspector Signature'), findsNothing);
    expect(find.text('Import Manager Signature'), findsNothing);
    expect(find.text('Preview Manager Signature'), findsNothing);
    expect(find.text('Inspector signature attached.'), findsNothing);
    expect(find.text('Manager signature attached.'), findsNothing);
    expect(find.text('Pending'), findsWidgets);
  });

  testWidgets('material form stays stable on tablet width', (tester) async {
    tester.view.physicalSize = const Size(1600, 2560);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.reset);

    final appState = MaterialGuardianAppState.seeded();

    await tester.pumpWidget(
      MaterialApp(
        home: MaterialFormScreen(
          appState: appState,
          jobId: 'job-1001',
          draftId: 'draft-001',
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('RECEIVING INSPECTION\nREPORT'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Material Photos'),
      250,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    expect(find.text('Material Photos'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('customization screen exposes B16 dropdown preferences', (
    tester,
  ) async {
    final appState = MaterialGuardianAppState.seededSignedIn();

    await tester.pumpWidget(
      MaterialApp(home: CustomizationScreen(appState: appState)),
    );
    await tester.pumpAndSettle();

    expect(find.text('B16 Dropdown Preferences'), findsOneWidget);
    expect(find.text('B16.5  Flanges <=24 NPS'), findsOneWidget);
  });

  testWidgets(
    'dirty material form shows donor-style exit dialog and keeps draft on leave',
    (tester) async {
      final appState = MaterialGuardianAppState.seeded();

      await tester.pumpWidget(
        MaterialApp(
          home: MaterialFormScreen(
            appState: appState,
            jobId: 'job-1001',
            draftId: 'draft-001',
          ),
        ),
      );
      await tester.pumpAndSettle();

      final descriptionField = find.byWidgetPredicate(
        (widget) =>
            widget is TextField &&
            widget.decoration?.labelText == 'Material Description',
      );

      await tester.enterText(descriptionField, 'Back prompt draft check');
      await tester.pump();
      await tester.tap(find.byIcon(Icons.arrow_back_rounded));
      await tester.pumpAndSettle();

      expect(find.text('Exit receiving report?'), findsOneWidget);
      expect(find.text('Keep Editing'), findsOneWidget);
      expect(find.text('Leave'), findsOneWidget);
      expect(find.text('Delete Draft'), findsOneWidget);

      await tester.tap(find.text('Leave'));
      await tester.pumpAndSettle();

      expect(
        appState.draftById('draft-001').description,
        'Back prompt draft check',
      );
    },
  );

  testWidgets(
    'material form does not show the exit warning after autosave has already persisted the latest changes',
    (tester) async {
      final appState = MaterialGuardianAppState.seeded();

      await tester.pumpWidget(
        MaterialApp(
          home: MaterialFormScreen(
            appState: appState,
            jobId: 'job-1001',
            draftId: 'draft-001',
          ),
        ),
      );
      await tester.pumpAndSettle();

      final descriptionField = find.byWidgetPredicate(
        (widget) =>
            widget is TextField &&
            widget.decoration?.labelText == 'Material Description',
      );

      await tester.enterText(descriptionField, 'Autosaved clean exit');
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pumpAndSettle();

      expect(
        appState.draftById('draft-001').description,
        'Autosaved clean exit',
      );

      await tester.tap(find.byIcon(Icons.arrow_back_rounded));
      await tester.pumpAndSettle();

      expect(find.text('Exit receiving report?'), findsNothing);
      expect(
        appState.draftById('draft-001').description,
        'Autosaved clean exit',
      );
    },
  );

  testWidgets('dirty material form can delete the draft from the exit dialog', (
    tester,
  ) async {
    final appState = MaterialGuardianAppState.seeded();

    await tester.pumpWidget(
      MaterialApp(
        home: MaterialFormScreen(
          appState: appState,
          jobId: 'job-1001',
          draftId: 'draft-001',
        ),
      ),
    );
    await tester.pumpAndSettle();

    final descriptionField = find.byWidgetPredicate(
      (widget) =>
          widget is TextField &&
          widget.decoration?.labelText == 'Material Description',
    );

    await tester.enterText(descriptionField, 'Delete this draft');
    await tester.pump();
    await tester.tap(find.byIcon(Icons.arrow_back_rounded));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete Draft'));
    await tester.pumpAndSettle();

    expect(() => appState.draftById('draft-001'), throwsA(isA<StateError>()));
  });

  test(
    'editing a saved material updates it instead of duplicating it',
    () async {
      final appState = MaterialGuardianAppState.seeded();
      final originalJob = appState.jobById('job-1001');

      expect(originalJob.materials, hasLength(1));

      final editDraft = await appState.createEditDraft(
        jobId: 'job-1001',
        materialId: 'mat-001',
      );

      await appState.saveDraft(
        editDraft.copyWith(
          description: 'Updated gate valve',
          comments: 'Edited in Flutter draft flow',
          visualInspectionAcceptable: false,
          markingAcceptable: false,
          markingAcceptableNa: false,
          mtrAcceptable: false,
          mtrAcceptableNa: true,
          materialApproval: 'rejected',
          qcInspectorDate: DateTime(2026, 4, 2),
          qcManagerDate: DateTime(2026, 4, 3),
        ),
      );

      await appState.completeDraft(appState.draftById(editDraft.id));

      final updatedJob = appState.jobById('job-1001');
      final updatedMaterial = appState.materialById(
        jobId: 'job-1001',
        materialId: 'mat-001',
      );

      expect(updatedJob.materials, hasLength(1));
      expect(updatedMaterial.description, 'Updated gate valve');
      expect(updatedMaterial.comments, 'Edited in Flutter draft flow');
      expect(updatedMaterial.visualInspectionAcceptable, isFalse);
      expect(updatedMaterial.markingAcceptable, isFalse);
      expect(updatedMaterial.markingAcceptableNa, isFalse);
      expect(updatedMaterial.mtrAcceptable, isFalse);
      expect(updatedMaterial.mtrAcceptableNa, isTrue);
      expect(updatedMaterial.materialApproval, 'rejected');
      expect(updatedMaterial.qcInspectorDate, DateTime(2026, 4, 2));
      expect(updatedMaterial.qcManagerDate, DateTime(2026, 4, 3));
      expect(appState.draftsForJob('job-1001'), hasLength(1));
    },
  );

  test(
    'saving the unsaved draft creates a material without throwing',
    () async {
      final appState = MaterialGuardianAppState.seeded();
      final draft = appState.draftById('draft-001');
      await appState.saveDraft(
        draft.copyWith(
          description: 'Unfinished hanger',
          productType: '',
          surfaceFinish: '',
        ),
      );
      await appState.completeDraft(appState.draftById('draft-001'));

      final updatedJob = appState.jobById('job-1001');
      expect(
        updatedJob.materials.any(
          (item) => item.description == 'Unfinished hanger',
        ),
        isTrue,
      );
      expect(() => appState.draftById('draft-001'), throwsA(isA<StateError>()));
    },
  );

  test('exporting a job creates packet PDFs and a ZIP bundle', () async {
    final appState = MaterialGuardianAppState.seeded();

    final exportResult = await appState.exportJob('job-1001');
    final updatedJob = appState.jobById('job-1001');
    final updatedMaterial = appState.materialById(
      jobId: 'job-1001',
      materialId: 'mat-001',
    );

    expect(Directory(exportResult.exportRootPath).existsSync(), isTrue);
    expect(File(exportResult.zipPath).existsSync(), isTrue);
    final zipArchive = ZipDecoder().decodeBytes(
      File(exportResult.zipPath).readAsBytesSync(),
    );
    expect(
      zipArchive.files.any(
        (entry) =>
            entry.isFile && entry.name.endsWith('01_2_gate_valve_packet.pdf'),
      ),
      isTrue,
    );
    expect(exportResult.packetPathsByMaterialId, contains('mat-001'));
    expect(
      File(exportResult.packetPathsByMaterialId['mat-001']!).existsSync(),
      isTrue,
    );
    expect(updatedJob.exportPath, exportResult.exportRootPath);
    expect(updatedJob.exportedAt, isNotNull);
    expect(updatedMaterial.pdfStatus, 'exported');
    expect(File(updatedMaterial.pdfStoragePath).existsSync(), isTrue);
  });

  test(
    'exporting a job with no saved materials does not mark it exported',
    () async {
      final appState = MaterialGuardianAppState.seeded();

      await appState.deleteMaterial(jobId: 'job-1001', materialId: 'mat-001');
      final exportResult = await appState.exportJob('job-1001');
      final updatedJob = appState.jobById('job-1001');

      expect(exportResult.packetCount, 0);
      expect(updatedJob.exportedAt, isNull);
      expect(updatedJob.exportPath, isEmpty);
      expect(File(exportResult.zipPath).existsSync(), isTrue);
      expect(
        File(
          '${exportResult.exportRootPath}${Platform.pathSeparator}export_info.txt',
        ).existsSync(),
        isTrue,
      );
    },
  );

  test('exporting unicode packet fields succeeds with bundled fonts', () async {
    final appState = MaterialGuardianAppState.seeded();
    final editDraft = await appState.createEditDraft(
      jobId: 'job-1001',
      materialId: 'mat-001',
    );
    await appState.saveDraft(
      editDraft.copyWith(
        description: '2" valve – café check',
        vendor: 'Québec Works',
        comments: 'Inspector Renée verified µin finish.',
        qcInspectorName: 'Renée Weld',
        qcManagerName: 'Jürgen QA',
        surfaceFinishUnit: 'µin',
      ),
    );
    await appState.completeDraft(appState.draftById(editDraft.id));

    final exportResult = await appState.exportJob('job-1001');

    expect(
      File(exportResult.packetPathsByMaterialId['mat-001']!).existsSync(),
      isTrue,
    );
    expect(File(exportResult.zipPath).existsSync(), isTrue);
  });

  test(
    'exporting a scanned PDF also carries its preview image into export media',
    () async {
      final appState = MaterialGuardianAppState.seeded();
      final probeRoot = Directory(
        '${Directory.systemTemp.path}/material_guardian_scan_export_probe',
      )..createSync(recursive: true);
      final scanPdf = File('${probeRoot.path}/incoming_scan.pdf')
        ..writeAsBytesSync(const <int>[37, 80, 68, 70, 45, 49, 46, 52]);
      final previewImage = img.Image(width: 2, height: 2);
      img.fill(previewImage, color: img.ColorRgb8(240, 240, 240));
      previewImage.setPixelRgb(0, 0, 180, 180, 180);
      File(
        pdfPreviewSiblingPath(scanPdf.path),
      ).writeAsBytesSync(img.encodeJpg(previewImage, quality: 90));

      final editDraft = await appState.createEditDraft(
        jobId: 'job-1001',
        materialId: 'mat-001',
      );
      await appState.saveDraft(editDraft.copyWith(scanPaths: [scanPdf.path]));
      await appState.completeDraft(appState.draftById(editDraft.id));

      final exportResult = await appState.exportJob('job-1001');
      final zipArchive = ZipDecoder().decodeBytes(
        File(exportResult.zipPath).readAsBytesSync(),
      );

      expect(
        zipArchive.files.any(
          (entry) =>
              entry.isFile &&
              entry.name.contains('source_media/') &&
              entry.name.endsWith('_scan_01_preview.jpg'),
        ),
        isTrue,
      );
      expect(
        Directory(exportResult.exportRootPath)
            .listSync(recursive: true)
            .whereType<File>()
            .any((file) => file.path.endsWith('_scan_01_preview.jpg')),
        isTrue,
      );
    },
  );

  test(
    'blank drafts leave QC manager date unset until explicitly chosen',
    () async {
      final appState = MaterialGuardianAppState.seeded();

      final draft = await appState.createBlankDraft(jobId: 'job-1001');

      expect(draft.qcManagerDateEnabled, isFalse);
      expect(draft.qcManagerDateManual, isFalse);
    },
  );

  test('renaming a job and deleting a material update local state', () async {
    final appState = MaterialGuardianAppState.seeded();

    await appState.updateJob(
      jobId: 'job-1001',
      jobNumber: 'MG-24031-R1',
      description: 'Renamed receiving packet',
      notes: 'Updated by Flutter edit flow',
    );
    await appState.deleteMaterial(jobId: 'job-1001', materialId: 'mat-001');

    final updatedJob = appState.jobById('job-1001');

    expect(updatedJob.jobNumber, 'MG-24031-R1');
    expect(updatedJob.description, 'Renamed receiving packet');
    expect(updatedJob.notes, 'Updated by Flutter edit flow');
    expect(updatedJob.materials, isEmpty);
    expect(
      () => appState.materialById(jobId: 'job-1001', materialId: 'mat-001'),
      throwsA(isA<StateError>()),
    );
  });

  test(
    'app state can successfully call backend health through the shared service',
    () async {
      const baseUrl =
          'https://app-platforms-backend-dev-293518443128.us-east4.run.app';
      final service = BackendApiService(
        baseUrl: baseUrl,
        client: MockClient((request) async {
          expect(request.url.toString(), '$baseUrl/health');
          return http.Response(
            '{"status":"ok","service":"app-platforms-backend","mode":"postgres"}',
            200,
            headers: {'content-type': 'application/json'},
          );
        }),
      );
      final appState = MaterialGuardianAppState.seeded(
        backendApiService: service,
      );

      await appState.refreshBackendHealth();

      expect(appState.backendBaseUrl, baseUrl);
      expect(appState.backendHealth?.status, 'ok');
      expect(appState.backendHealth?.service, 'app-platforms-backend');
      expect(appState.backendHealth?.mode, 'postgres');
      expect(appState.backendHealthError, isNull);
    },
  );

  test('app state can sign in, hydrate backend account state, and sign out', () async {
    final requests = <http.Request>[];
    final sessionStore = InMemoryBackendAuthSessionStore();
    final service = BackendApiService(
      baseUrl:
          'https://app-platforms-backend-dev-293518443128.us-east4.run.app',
      client: MockClient((request) async {
        requests.add(request);

        if (request.url.path.endsWith('/auth/start')) {
          return http.Response(
            '{"flowId":"flow_1","deliveryTarget":"shop-admin@materialguardian.test","expiresAt":"2026-04-02T18:30:00.000Z","demoCode":"246810"}',
            200,
            headers: {'content-type': 'application/json'},
          );
        }

        if (request.url.path.endsWith('/auth/complete')) {
          return http.Response(
            '{"status":"authenticated","accessToken":"access-123","refreshToken":"refresh-123","user":{"id":"user_owner","email":"shop-admin@materialguardian.test","displayName":"Shop Admin","status":"active","createdAt":"2026-04-02T12:00:00.000Z","lastLoginAt":"2026-04-02T12:05:00.000Z"},"memberships":[{"id":"membership_owner","organizationId":"org_acme","organizationName":"Acme Fabrication","role":"owner","seatStatus":"assigned","invitedAt":"2026-04-02T12:00:00.000Z","acceptedAt":"2026-04-02T12:01:00.000Z"}],"activeEntitlement":{"productCode":"material_guardian","planCode":"material_guardian_business_monthly","accessState":"paid","seatAvailability":"assigned","subscriptionState":"active","trialRemaining":0,"organizationId":"org_acme","startsAt":"2026-04-02T12:00:00.000Z","endsAt":null},"session":{"id":"session_1","deviceLabel":"Kevin PowerShell","platform":"web","status":"active","issuedAt":"2026-04-02T12:05:00.000Z","lastSeenAt":"2026-04-02T12:05:00.000Z","revokedAt":null}}',
            200,
            headers: {'content-type': 'application/json'},
          );
        }

        if (request.url.path.endsWith('/me')) {
          return http.Response(
            '{"user":{"id":"user_owner","email":"shop-admin@materialguardian.test","displayName":"Shop Admin","status":"active","createdAt":"2026-04-02T12:00:00.000Z","lastLoginAt":"2026-04-02T12:05:00.000Z"},"memberships":[{"id":"membership_owner","organizationId":"org_acme","organizationName":"Acme Fabrication","role":"owner","seatStatus":"assigned","invitedAt":"2026-04-02T12:00:00.000Z","acceptedAt":"2026-04-02T12:01:00.000Z"}],"currentSeatAssignment":{"organizationId":"org_acme","status":"assigned"},"trialState":null,"activeEntitlement":{"productCode":"material_guardian","planCode":"material_guardian_business_monthly","accessState":"paid","seatAvailability":"assigned","subscriptionState":"active","trialRemaining":0,"organizationId":"org_acme","startsAt":"2026-04-02T12:00:00.000Z","endsAt":null},"activeSession":{"id":"session_1","deviceLabel":"Kevin PowerShell","platform":"web","status":"active","issuedAt":"2026-04-02T12:05:00.000Z","lastSeenAt":"2026-04-02T12:05:00.000Z","revokedAt":null}}',
            200,
            headers: {'content-type': 'application/json'},
          );
        }

        if (request.url.path.endsWith('/entitlements/current')) {
          return http.Response(
            '{"productCode":"material_guardian","planCode":"material_guardian_business_monthly","accessState":"paid","seatAvailability":"assigned","subscriptionState":"active","trialRemaining":0,"organizationId":"org_acme","startsAt":"2026-04-02T12:00:00.000Z","endsAt":null}',
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

        if (request.url.path.endsWith('/auth/logout')) {
          return http.Response(
            '{"revokedSessionId":"session_1","revokedAt":"2026-04-02T12:06:00.000Z"}',
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

    final appState = MaterialGuardianAppState.seeded(
      backendApiService: service,
      authSessionStore: sessionStore,
    );

    await appState.startBackendSignIn(
      email: 'shop-admin@materialguardian.test',
      displayName: 'Shop Admin',
    );
    expect(appState.pendingBackendAuthStart, isNotNull);

    await appState.completeBackendSignIn(code: '246810');

    expect(appState.isSignedIn, isTrue);
    expect(appState.backendMe?.user.email, 'shop-admin@materialguardian.test');
    expect(
      appState.backendEntitlement?.planCode,
      'material_guardian_business_monthly',
    );
    expect(appState.backendOrganization?.id, 'org_acme');
    expect((await sessionStore.load())?.refreshToken, 'refresh-123');

    await appState.logoutBackend();

    expect(appState.isSignedIn, isFalse);
    expect(await sessionStore.load(), isNull);
    expect(
      requests.any((request) => request.url.path.endsWith('/auth/logout')),
      isTrue,
    );
  });

  test(
    'billing catalog surfaces missing Play product IDs instead of failing silently',
    () async {
      final service = BackendApiService(
        baseUrl:
            'https://app-platforms-backend-dev-293518443128.us-east4.run.app',
        client: MockClient((request) async {
          if (request.url.path.endsWith('/plans')) {
            return http.Response(
              '''
            {
              "plans": [
                {
                  "planCode": "material_guardian_individual_monthly",
                  "productCode": "material_guardian",
                  "audienceType": "individual",
                  "billingInterval": "monthly",
                  "seatLimit": 1,
                  "displayPrice": "\$9.99",
                  "displayPriceCents": 999,
                  "storeProductIds": {
                    "google": "material_guardian_individual_monthly"
                  },
                  "futureBilling": {}
                }
              ]
            }
            ''',
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

      final appState = MaterialGuardianAppState.seeded(
        backendApiService: service,
        storePurchaseService: const _FakeStorePurchaseService(
          available: true,
          queryResult: StoreProductQueryResult(
            products: <StoreProductSnapshot>[],
            notFoundIds: <String>['material_guardian_individual_monthly'],
            errorMessage: null,
          ),
        ),
      );

      await appState.loadPurchaseCatalog();

      expect(appState.isStoreAvailable, isTrue);
      expect(appState.storeProductsById, isEmpty);
      expect(
        appState.lastMissingStoreProductIds,
        equals(<String>['material_guardian_individual_monthly']),
      );
      expect(
        appState.purchaseError,
        contains('Play did not return these product IDs'),
      );
    },
  );

  test(
    'restoring a stale backend session clears auth state without surfacing a sales error',
    () async {
      final sessionStore = InMemoryBackendAuthSessionStore();
      await sessionStore.save(
        const StoredBackendAuthSession(
          accessToken: 'stale-access',
          refreshToken: 'stale-refresh',
        ),
      );

      final service = BackendApiService(
        baseUrl:
            'https://app-platforms-backend-dev-293518443128.us-east4.run.app',
        client: MockClient((request) async {
          if (request.url.path.endsWith('/auth/refresh')) {
            return http.Response(
              '{"message":"Refresh token is invalid."}',
              401,
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

      final appState = MaterialGuardianAppState.seeded(
        backendApiService: service,
        authSessionStore: sessionStore,
      );

      await appState.restoreBackendSession();

      expect(appState.isSignedIn, isFalse);
      expect(appState.backendAuthSession, isNull);
      expect(appState.backendAccountError, isNull);
      expect(appState.shouldSurfaceSalesAuthError, isFalse);
      expect(await sessionStore.load(), isNull);
    },
  );

  test(
    'transient backend refresh failures do not wipe an existing signed-in session',
    () async {
      var refreshCalls = 0;
      final sessionStore = InMemoryBackendAuthSessionStore();
      final service = BackendApiService(
        baseUrl: 'https://backend.example.test',
        client: MockClient((request) async {
          if (request.url.path == '/auth/start') {
            return http.Response(
              '{"flowId":"flow_refresh","deliveryTarget":"refresh@materialguardian.test","expiresAt":"2026-04-02T18:30:00.000Z","demoCode":"246810"}',
              200,
              headers: {'content-type': 'application/json'},
            );
          }
          if (request.url.path == '/auth/complete') {
            return http.Response(
              '{"status":"authenticated","accessToken":"access-refresh","refreshToken":"refresh-refresh","user":{"id":"user_refresh","email":"refresh@materialguardian.test","displayName":"Refresh User","status":"active","createdAt":"2026-04-02T12:00:00.000Z","lastLoginAt":"2026-04-02T12:05:00.000Z"},"memberships":[],"activeEntitlement":{"productCode":"material_guardian","planCode":null,"accessState":"trial","seatAvailability":"not_applicable","subscriptionState":"trial","trialRemaining":6,"organizationId":null,"startsAt":"2026-04-02T12:00:00.000Z","endsAt":null},"session":{"id":"session_refresh","deviceLabel":"Kevin PowerShell","platform":"web","status":"active","issuedAt":"2026-04-02T12:05:00.000Z","lastSeenAt":"2026-04-02T12:05:00.000Z","revokedAt":null}}',
              200,
              headers: {'content-type': 'application/json'},
            );
          }
          if (request.url.path == '/auth/refresh') {
            refreshCalls += 1;
            return http.Response(
              '{"message":"Temporary upstream failure."}',
              503,
              headers: {'content-type': 'application/json'},
            );
          }
          if (request.url.path == '/me') {
            return http.Response(
              '{"user":{"id":"user_refresh","email":"refresh@materialguardian.test","displayName":"Refresh User","status":"active","createdAt":"2026-04-02T12:00:00.000Z","lastLoginAt":"2026-04-02T12:05:00.000Z"},"memberships":[],"currentSeatAssignment":{"organizationId":null,"status":"not_applicable"},"trialState":{"productCode":"material_guardian","jobsAllowed":6,"jobsUsed":0,"jobsRemaining":6,"status":"active"},"activeEntitlement":{"productCode":"material_guardian","planCode":null,"accessState":"trial","seatAvailability":"not_applicable","subscriptionState":"trial","trialRemaining":6,"organizationId":null,"startsAt":"2026-04-02T12:00:00.000Z","endsAt":null},"activeSession":{"id":"session_refresh","deviceLabel":"Kevin PowerShell","platform":"web","status":"active","issuedAt":"2026-04-02T12:05:00.000Z","lastSeenAt":"2026-04-02T12:05:00.000Z","revokedAt":null}}',
              200,
              headers: {'content-type': 'application/json'},
            );
          }
          if (request.url.path == '/entitlements/current') {
            return http.Response(
              '{"productCode":"material_guardian","planCode":null,"accessState":"trial","seatAvailability":"not_applicable","subscriptionState":"trial","trialRemaining":6,"organizationId":null,"startsAt":"2026-04-02T12:00:00.000Z","endsAt":null}',
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

      final appState = MaterialGuardianAppState.seeded(
        backendApiService: service,
        authSessionStore: sessionStore,
      );

      await appState.startBackendSignIn(
        email: 'refresh@materialguardian.test',
        displayName: 'Refresh User',
      );
      await appState.completeBackendSignIn(code: '246810');

      expect(appState.isSignedIn, isTrue);

      await appState.refreshBackendAccount();

      expect(refreshCalls, 1);
      expect(appState.isSignedIn, isTrue);
      expect(appState.backendAuthSession, isNotNull);
      expect(await sessionStore.load(), isNotNull);
      expect(appState.backendAccountError, isNull);
      expect(appState.shouldSurfaceSalesAuthError, isFalse);
    },
  );

  test(
    'restoring a saved session keeps the jobs shell visible when backend recovery is temporarily unavailable',
    () async {
      final sessionStore = InMemoryBackendAuthSessionStore();
      await sessionStore.save(
        const StoredBackendAuthSession(
          accessToken: 'access-startup',
          refreshToken: 'refresh-startup',
        ),
      );
      final service = BackendApiService(
        baseUrl: 'https://backend.example.test',
        client: MockClient((request) async {
          if (request.url.path == '/auth/refresh' ||
              request.url.path == '/me' ||
              request.url.path == '/entitlements/current') {
            return http.Response(
              '{"message":"Temporary upstream failure."}',
              503,
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

      final appState = MaterialGuardianAppState.seeded(
        backendApiService: service,
        authSessionStore: sessionStore,
      );

      await appState.restoreBackendSession();

      expect(appState.backendAuthSession, isNotNull);
      expect(appState.isSignedIn, isFalse);
      expect(appState.shouldUseSalesLaunch, isFalse);
      expect(appState.backendAccountError, contains('could not be refreshed'));
    },
  );

  test('seat-blocked paid members cannot create new jobs', () async {
    final sessionStore = InMemoryBackendAuthSessionStore();
    final service = BackendApiService(
      baseUrl: 'https://backend.example.test',
      client: MockClient((request) async {
        if (request.url.path == '/auth/start') {
          return http.Response(
            '{"flowId":"flow_seat","deliveryTarget":"seat@materialguardian.test","expiresAt":"2026-04-02T18:30:00.000Z","demoCode":"246810"}',
            200,
            headers: {'content-type': 'application/json'},
          );
        }
        if (request.url.path == '/auth/complete') {
          return http.Response(
            '{"status":"authenticated","accessToken":"access-seat","refreshToken":"refresh-seat","user":{"id":"user_seat","email":"seat@materialguardian.test","displayName":"Seat Blocked","status":"active","createdAt":"2026-04-02T12:00:00.000Z","lastLoginAt":"2026-04-02T12:05:00.000Z"},"memberships":[{"id":"membership_seat","organizationId":"org_seat","organizationName":"Seat Blocked Org","role":"member","seatStatus":"unassigned","invitedAt":"2026-04-02T12:00:00.000Z","acceptedAt":"2026-04-02T12:01:00.000Z"}],"activeEntitlement":{"productCode":"material_guardian_business","planCode":"material_guardian_business_5_monthly","accessState":"paid","seatAvailability":"unassigned","subscriptionState":"active","trialRemaining":0,"organizationId":"org_seat","startsAt":"2026-04-02T12:00:00.000Z","endsAt":null},"session":{"id":"session_seat","deviceLabel":"Kevin PowerShell","platform":"web","status":"active","issuedAt":"2026-04-02T12:05:00.000Z","lastSeenAt":"2026-04-02T12:05:00.000Z","revokedAt":null}}',
            200,
            headers: {'content-type': 'application/json'},
          );
        }
        if (request.url.path == '/me') {
          return http.Response(
            '{"user":{"id":"user_seat","email":"seat@materialguardian.test","displayName":"Seat Blocked","status":"active","createdAt":"2026-04-02T12:00:00.000Z","lastLoginAt":"2026-04-02T12:05:00.000Z"},"memberships":[{"id":"membership_seat","organizationId":"org_seat","organizationName":"Seat Blocked Org","role":"member","seatStatus":"unassigned","invitedAt":"2026-04-02T12:00:00.000Z","acceptedAt":"2026-04-02T12:01:00.000Z"}],"currentSeatAssignment":{"organizationId":"org_seat","status":"unassigned"},"trialState":null,"activeEntitlement":{"productCode":"material_guardian_business","planCode":"material_guardian_business_5_monthly","accessState":"paid","seatAvailability":"unassigned","subscriptionState":"active","trialRemaining":0,"organizationId":"org_seat","startsAt":"2026-04-02T12:00:00.000Z","endsAt":null},"activeSession":{"id":"session_seat","deviceLabel":"Kevin PowerShell","platform":"web","status":"active","issuedAt":"2026-04-02T12:05:00.000Z","lastSeenAt":"2026-04-02T12:05:00.000Z","revokedAt":null}}',
            200,
            headers: {'content-type': 'application/json'},
          );
        }
        if (request.url.path == '/entitlements/current') {
          return http.Response(
            '{"productCode":"material_guardian_business","planCode":"material_guardian_business_5_monthly","accessState":"paid","seatAvailability":"unassigned","subscriptionState":"active","trialRemaining":0,"organizationId":"org_seat","startsAt":"2026-04-02T12:00:00.000Z","endsAt":null}',
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

    final appState = MaterialGuardianAppState.seeded(
      backendApiService: service,
      authSessionStore: sessionStore,
    );

    await appState.startBackendSignIn(
      email: 'seat@materialguardian.test',
      displayName: 'Seat Blocked',
    );
    await appState.completeBackendSignIn(code: '246810');

    expect(appState.isSeatBlocked, isTrue);
    expect(appState.hasUsableJobAccess, isFalse);
    expect(
      () => appState.saveJob(
        jobNumber: 'SEAT-001',
        description: 'Blocked',
        notes: '',
      ),
      throwsA(
        isA<BackendApiException>().having(
          (error) => error.message,
          'message',
          contains('assigned report user seat'),
        ),
      ),
    );
    expect(
      () => appState.createBlankDraft(jobId: 'job-1001'),
      throwsA(
        isA<BackendApiException>().having(
          (error) => error.message,
          'message',
          contains('assigned report user seat'),
        ),
      ),
    );
  });

  testWidgets('paid accounts see the active plan instead of the full sales catalog', (
    tester,
  ) async {
    final sessionStore = InMemoryBackendAuthSessionStore();
    final service = BackendApiService(
      baseUrl:
          'https://app-platforms-backend-dev-293518443128.us-east4.run.app',
      client: MockClient((request) async {
        if (request.url.path.endsWith('/auth/start')) {
          return http.Response(
            '{"flowId":"flow_paid","deliveryTarget":"paid@materialguardian.test","expiresAt":"2026-04-02T18:30:00.000Z","demoCode":"246810"}',
            200,
            headers: {'content-type': 'application/json'},
          );
        }

        if (request.url.path.endsWith('/auth/complete')) {
          return http.Response(
            '{"status":"authenticated","accessToken":"access-paid","refreshToken":"refresh-paid","user":{"id":"user_paid","email":"paid@materialguardian.test","displayName":"Paid User","status":"active","createdAt":"2026-04-02T12:00:00.000Z","lastLoginAt":"2026-04-02T12:05:00.000Z"},"memberships":[],"activeEntitlement":{"productCode":"material_guardian","planCode":"material_guardian_individual_yearly","accessState":"paid","seatAvailability":"not_applicable","subscriptionState":"active","trialRemaining":0,"organizationId":null,"startsAt":"2026-04-02T12:00:00.000Z","endsAt":null},"session":{"id":"session_paid","deviceLabel":"Kevin PowerShell","platform":"web","status":"active","issuedAt":"2026-04-02T12:05:00.000Z","lastSeenAt":"2026-04-02T12:05:00.000Z","revokedAt":null}}',
            200,
            headers: {'content-type': 'application/json'},
          );
        }

        if (request.url.path.endsWith('/me')) {
          return http.Response(
            '{"user":{"id":"user_paid","email":"paid@materialguardian.test","displayName":"Paid User","status":"active","createdAt":"2026-04-02T12:00:00.000Z","lastLoginAt":"2026-04-02T12:05:00.000Z"},"memberships":[],"currentSeatAssignment":{"organizationId":null,"status":"not_applicable"},"trialState":null,"activeEntitlement":{"productCode":"material_guardian","planCode":"material_guardian_individual_yearly","accessState":"paid","seatAvailability":"not_applicable","subscriptionState":"active","trialRemaining":0,"organizationId":null,"startsAt":"2026-04-02T12:00:00.000Z","endsAt":null},"activeSession":{"id":"session_paid","deviceLabel":"Kevin PowerShell","platform":"web","status":"active","issuedAt":"2026-04-02T12:05:00.000Z","lastSeenAt":"2026-04-02T12:05:00.000Z","revokedAt":null}}',
            200,
            headers: {'content-type': 'application/json'},
          );
        }

        if (request.url.path.endsWith('/entitlements/current')) {
          return http.Response(
            '{"productCode":"material_guardian","planCode":"material_guardian_individual_yearly","accessState":"paid","seatAvailability":"not_applicable","subscriptionState":"active","trialRemaining":0,"organizationId":null,"startsAt":"2026-04-02T12:00:00.000Z","endsAt":null}',
            200,
            headers: {'content-type': 'application/json'},
          );
        }

        if (request.url.path.endsWith('/plans')) {
          return http.Response(
            '''
            {
              "plans": [
                {
                  "planCode": "material_guardian_individual_monthly",
                  "productCode": "material_guardian",
                  "audienceType": "individual",
                  "billingInterval": "monthly",
                  "seatLimit": 1,
                  "displayPrice": "\$9.99",
                  "displayPriceCents": 999,
                  "storeProductIds": {
                    "google": "material_guardian_individual_monthly"
                  },
                  "futureBilling": {}
                },
                {
                  "planCode": "material_guardian_individual_yearly",
                  "productCode": "material_guardian",
                  "audienceType": "individual",
                  "billingInterval": "yearly",
                  "seatLimit": 1,
                  "displayPrice": "\$99.99",
                  "displayPriceCents": 9999,
                  "annualSavingsDisplay": "\$20.00",
                  "storeProductIds": {
                    "google": "material_guardian_individual_yearly"
                  },
                  "futureBilling": {}
                }
              ]
            }
            ''',
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

    final appState = MaterialGuardianAppState.seeded(
      backendApiService: service,
      authSessionStore: sessionStore,
      storePurchaseService: const _FakeStorePurchaseService(
        available: true,
        queryResult: StoreProductQueryResult(
          products: <StoreProductSnapshot>[],
          notFoundIds: <String>[],
          errorMessage: null,
        ),
      ),
    );

    await appState.startBackendSignIn(
      email: 'paid@materialguardian.test',
      displayName: 'Paid User',
    );
    await appState.completeBackendSignIn(code: '246810');
    await appState.loadPurchaseCatalog();

    await tester.pumpWidget(MaterialApp(home: SalesScreen(appState: appState)));
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.text('Active subscription'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    expect(find.text('Active subscription'), findsOneWidget);
    expect(
      find.textContaining('This account already has an active subscription'),
      findsOneWidget,
    );
    expect(find.text('Choose This Plan'), findsNothing);
  });

  test(
    'restoring purchases surfaces a no-purchases-found message instead of silently idling',
    () async {
      final appState = MaterialGuardianAppState.seeded(
        storePurchaseService: const _FakeStorePurchaseService(
          available: true,
          queryResult: StoreProductQueryResult(
            products: <StoreProductSnapshot>[],
            notFoundIds: <String>[],
            errorMessage: null,
          ),
          restoreResult: StoreRestoreResult(
            updates: <StorePurchaseUpdate>[],
            errorMessage: null,
          ),
        ),
      );

      await appState.restorePurchases();

      expect(appState.isRestoringPurchases, isFalse);
      expect(appState.isPurchasing, isFalse);
      expect(
        appState.purchaseStatusMessage,
        anyOf(
          contains('No active Google Play purchases were found'),
          contains('No purchases were available to restore'),
        ),
      );
      expect(appState.purchaseError, isNull);
    },
  );

  test(
    'restoring purchases surfaces backend refresh failures instead of claiming no purchases exist',
    () async {
      final appState = MaterialGuardianAppState.seededSignedIn(
        backendApiService: BackendApiService(
          baseUrl: 'https://backend.example.test',
          client: MockClient((request) async {
            if (request.url.path == '/me' ||
                request.url.path == '/entitlements/current') {
              return http.Response(
                '{"message":"Temporary upstream failure."}',
                503,
                headers: {'content-type': 'application/json'},
              );
            }

            return http.Response(
              '{"status":"ok","service":"app-platforms-backend","mode":"postgres"}',
              200,
              headers: {'content-type': 'application/json'},
            );
          }),
        ),
        storePurchaseService: const _FakeStorePurchaseService(
          available: true,
          queryResult: StoreProductQueryResult(
            products: <StoreProductSnapshot>[],
            notFoundIds: <String>[],
            errorMessage: null,
          ),
          restoreResult: StoreRestoreResult(
            updates: <StorePurchaseUpdate>[],
            errorMessage: null,
          ),
        ),
      );

      await appState.restorePurchases();

      expect(appState.purchaseStatusMessage, isNull);
      expect(
        appState.purchaseError,
        contains('backend account could not be refreshed'),
      );
    },
  );

  test(
    'restoring purchases does not claim store relink success when backend access is already active but no store purchases are returned',
    () async {
      final appState = MaterialGuardianAppState.seededSignedIn(
        backendApiService: BackendApiService(
          baseUrl: 'https://backend.example.test',
          client: MockClient((request) async {
            if (request.url.path == '/me') {
              return http.Response(
                '{"user":{"id":"user_owner","email":"granitemfgllc@gmail.com","displayName":"Demigodofa","status":"active","createdAt":"2026-04-02T12:00:00.000Z","lastLoginAt":"2026-04-02T12:05:00.000Z"},"memberships":[{"id":"membership_owner","organizationId":"org_acme","organizationName":"Granite MFG LLC","role":"owner","seatStatus":"assigned","invitedAt":"2026-04-02T12:00:00.000Z","acceptedAt":"2026-04-02T12:01:00.000Z"}],"currentSeatAssignment":{"organizationId":"org_acme","status":"assigned"},"trialState":null,"activeEntitlement":{"productCode":"material_guardian_business","planCode":"material_guardian_business_5_yearly","accessState":"paid","seatAvailability":"assigned","subscriptionState":"active","trialRemaining":0,"organizationId":"org_acme","startsAt":"2026-04-02T12:00:00.000Z","endsAt":null},"activeSession":{"id":"session_owner","deviceLabel":"Kevin PowerShell","platform":"android","status":"active","issuedAt":"2026-04-02T12:05:00.000Z","lastSeenAt":"2026-04-02T12:05:00.000Z","revokedAt":null}}',
                200,
                headers: {'content-type': 'application/json'},
              );
            }
            if (request.url.path == '/entitlements/current') {
              return http.Response(
                '{"productCode":"material_guardian_business","planCode":"material_guardian_business_5_yearly","accessState":"paid","seatAvailability":"assigned","subscriptionState":"active","trialRemaining":0,"organizationId":"org_acme","startsAt":"2026-04-02T12:00:00.000Z","endsAt":null}',
                200,
                headers: {'content-type': 'application/json'},
              );
            }
            if (request.url.path == '/organizations/org_acme') {
              return http.Response(
                '{"id":"org_acme","name":"Granite MFG LLC","status":"active","planCode":"material_guardian_business_5_yearly","seatLimit":5,"seatsAssigned":1,"seatsRemaining":4,"userCount":1,"members":[]}',
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
        ),
        storePurchaseService: const _FakeStorePurchaseService(
          available: true,
          queryResult: StoreProductQueryResult(
            products: <StoreProductSnapshot>[],
            notFoundIds: <String>[],
            errorMessage: null,
          ),
          restoreResult: StoreRestoreResult(
            updates: <StorePurchaseUpdate>[],
            errorMessage: null,
          ),
        ),
      );

      await appState.restorePurchases();

      expect(
        appState.purchaseStatusMessage,
        anyOf(
          contains(
            'No active Google Play purchases were returned on this device',
          ),
          contains('No purchases were returned to re-link on this device'),
        ),
      );
      expect(appState.purchaseError, isNull);
    },
  );

  test(
    'restoring purchases verifies restored Google subscriptions through the backend',
    () async {
      final requests = <http.Request>[];
      final sessionStore = InMemoryBackendAuthSessionStore();
      final service = BackendApiService(
        baseUrl: 'https://backend.example.test',
        client: MockClient((request) async {
          requests.add(request);

          if (request.url.path == '/auth/refresh') {
            return http.Response(
              '{"status":"authenticated","accessToken":"access-456","refreshToken":"refresh-456","user":{"id":"user_owner","email":"granitemfgllc@gmail.com","displayName":"Demigodofa","status":"active","createdAt":"2026-04-02T12:00:00.000Z","lastLoginAt":"2026-04-02T12:05:00.000Z"},"memberships":[{"id":"membership_owner","organizationId":"org_acme","organizationName":"Granite MFG LLC","role":"owner","seatStatus":"assigned","invitedAt":"2026-04-02T12:00:00.000Z","acceptedAt":"2026-04-02T12:01:00.000Z"}],"activeEntitlement":{"productCode":"material_guardian_business","planCode":"material_guardian_business_5_yearly","accessState":"paid","seatAvailability":"assigned","subscriptionState":"active","trialRemaining":0,"organizationId":"org_acme","startsAt":"2026-04-02T12:00:00.000Z","endsAt":null},"session":{"id":"session_1","deviceLabel":"Kevin PowerShell","platform":"android","status":"active","issuedAt":"2026-04-02T12:05:00.000Z","lastSeenAt":"2026-04-02T12:05:00.000Z","revokedAt":null}}',
              200,
              headers: {'content-type': 'application/json'},
            );
          }

          if (request.url.path == '/plans') {
            return http.Response(
              '''
              {
                "plans": [
                  {
                    "planCode": "material_guardian_business_5_yearly",
                    "productCode": "material_guardian_business",
                    "audienceType": "business",
                    "billingInterval": "yearly",
                    "seatLimit": 5,
                    "displayPrice": "\$299.99",
                    "displayPriceCents": 29999,
                    "storeProductIds": {
                      "google": "material_guardian_business_5_yearly"
                    },
                    "futureBilling": {}
                  }
                ]
              }
              ''',
              200,
              headers: {'content-type': 'application/json'},
            );
          }

          if (request.url.path == '/me') {
            return http.Response(
              '{"user":{"id":"user_owner","email":"granitemfgllc@gmail.com","displayName":"Demigodofa","status":"active","createdAt":"2026-04-02T12:00:00.000Z","lastLoginAt":"2026-04-02T12:05:00.000Z"},"memberships":[{"id":"membership_owner","organizationId":"org_acme","organizationName":"Granite MFG LLC","role":"owner","seatStatus":"assigned","invitedAt":"2026-04-02T12:00:00.000Z","acceptedAt":"2026-04-02T12:01:00.000Z"}],"currentSeatAssignment":{"organizationId":"org_acme","status":"assigned"},"trialState":null,"activeEntitlement":{"productCode":"material_guardian_business","planCode":"material_guardian_business_5_yearly","accessState":"paid","seatAvailability":"assigned","subscriptionState":"active","trialRemaining":0,"organizationId":"org_acme","startsAt":"2026-04-02T12:00:00.000Z","endsAt":null},"activeSession":{"id":"session_1","deviceLabel":"Kevin PowerShell","platform":"android","status":"active","issuedAt":"2026-04-02T12:05:00.000Z","lastSeenAt":"2026-04-02T12:05:00.000Z","revokedAt":null}}',
              200,
              headers: {'content-type': 'application/json'},
            );
          }

          if (request.url.path == '/entitlements/current') {
            return http.Response(
              '{"productCode":"material_guardian_business","planCode":"material_guardian_business_5_yearly","accessState":"paid","seatAvailability":"assigned","subscriptionState":"active","trialRemaining":0,"organizationId":"org_acme","startsAt":"2026-04-02T12:00:00.000Z","endsAt":null}',
              200,
              headers: {'content-type': 'application/json'},
            );
          }

          if (request.url.path == '/organizations/org_acme') {
            return http.Response(
              '{"id":"org_acme","name":"Granite MFG LLC","status":"active","planCode":"material_guardian_business_5_yearly","seatLimit":5,"seatsAssigned":2,"seatsRemaining":3,"userCount":2,"members":[]}',
              200,
              headers: {'content-type': 'application/json'},
            );
          }

          if (request.url.path == '/purchases/google/verify') {
            return http.Response(
              '{"status":"ok","subscription":{"id":"sub_1","provider":"google","planCode":"material_guardian_business_5_yearly","status":"active","providerSubscriptionRef":"token_123","providerOriginalRef":"token_123","startsAt":"2026-04-02T12:00:00.000Z","endsAt":"2027-04-02T12:00:00.000Z"},"activeEntitlement":{"productCode":"material_guardian_business","planCode":"material_guardian_business_5_yearly","accessState":"paid","seatAvailability":"assigned","subscriptionState":"active","trialRemaining":0,"organizationId":"org_acme","startsAt":"2026-04-02T12:00:00.000Z","endsAt":"2027-04-02T12:00:00.000Z"}}',
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

      await sessionStore.save(
        const StoredBackendAuthSession(
          accessToken: 'access-123',
          refreshToken: 'refresh-123',
        ),
      );

      final appState = await MaterialGuardianAppState.create(
        backendApiService: service,
        authSessionStore: sessionStore,
        storePurchaseService: const _FakeStorePurchaseService(
          available: true,
          queryResult: StoreProductQueryResult(
            products: <StoreProductSnapshot>[
              StoreProductSnapshot(
                id: 'material_guardian_business_5_yearly',
                title: 'Business Yearly',
                description: '5 users yearly',
                price: '\$299.99',
                currencyCode: 'USD',
                rawPrice: 299.99,
              ),
            ],
            notFoundIds: <String>[],
            errorMessage: null,
          ),
          restoreResult: StoreRestoreResult(
            updates: <StorePurchaseUpdate>[
              StorePurchaseUpdate(
                productId: 'material_guardian_business_5_yearly',
                purchaseId: 'purchase-1',
                status: 'restored',
                provider: 'google',
                pendingCompletePurchase: false,
                verificationServerData: 'server',
                verificationLocalData: 'local',
                verificationSource: 'google_play',
                transactionDate: null,
                providerTransactionRef: 'GPA.1234-5678',
                providerOriginalRef: 'token_123',
                errorMessage: null,
              ),
            ],
            errorMessage: null,
          ),
        ),
      );

      await appState.restorePurchases();

      final verifyRequest = requests.singleWhere(
        (request) => request.url.path == '/purchases/google/verify',
      );
      final verifyBody = jsonDecode(verifyRequest.body) as Map<String, dynamic>;

      expect(verifyBody['planCode'], 'material_guardian_business_5_yearly');
      expect(verifyBody['organizationId'], 'org_acme');
      expect(
        verifyBody['googleProductId'],
        'material_guardian_business_5_yearly',
      );
      expect(verifyBody['googlePurchaseToken'], 'token_123');
      expect(appState.purchaseStatusMessage, 'Purchase restored and verified.');
      expect(appState.purchaseError, isNull);
    },
  );

  test('store purchase updates defer until billing catalog is loaded', () async {
    final store = _TrackingStorePurchaseService(
      available: true,
      queryResult: const StoreProductQueryResult(
        products: <StoreProductSnapshot>[
          StoreProductSnapshot(
            id: 'material_guardian_individual_yearly',
            title: 'Material Guardian Individual Yearly',
            description: 'Yearly individual access',
            price: '\$99.99',
            currencyCode: 'USD',
            rawPrice: 99.99,
          ),
        ],
        notFoundIds: <String>[],
        errorMessage: null,
      ),
    );
    final requests = <http.Request>[];
    final sessionStore = InMemoryBackendAuthSessionStore();
    final service = BackendApiService(
      baseUrl: 'https://backend.example.test',
      client: MockClient((request) async {
        requests.add(request);
        if (request.url.path == '/auth/start') {
          return http.Response(
            '{"flowId":"flow_deferred","deliveryTarget":"deferred@materialguardian.test","expiresAt":"2026-04-02T18:30:00.000Z","demoCode":"246810"}',
            200,
            headers: {'content-type': 'application/json'},
          );
        }
        if (request.url.path == '/auth/complete') {
          return http.Response(
            '{"status":"authenticated","accessToken":"access-deferred","refreshToken":"refresh-deferred","user":{"id":"user_deferred","email":"deferred@materialguardian.test","displayName":"Deferred User","status":"active","createdAt":"2026-04-02T12:00:00.000Z","lastLoginAt":"2026-04-02T12:05:00.000Z"},"memberships":[],"activeEntitlement":{"productCode":"material_guardian","planCode":null,"accessState":"trial","seatAvailability":"not_applicable","subscriptionState":"trial","trialRemaining":6,"organizationId":null,"startsAt":"2026-04-02T12:00:00.000Z","endsAt":null},"session":{"id":"session_deferred","deviceLabel":"Kevin PowerShell","platform":"android","status":"active","issuedAt":"2026-04-02T12:05:00.000Z","lastSeenAt":"2026-04-02T12:05:00.000Z","revokedAt":null}}',
            200,
            headers: {'content-type': 'application/json'},
          );
        }
        if (request.url.path == '/plans') {
          return http.Response(
            '''
              {
                "plans": [
                  {
                    "planCode": "material_guardian_individual_yearly",
                    "productCode": "material_guardian",
                    "audienceType": "individual",
                    "billingInterval": "yearly",
                    "seatLimit": 1,
                    "displayPrice": "\$99.99",
                    "displayPriceCents": 9999,
                    "storeProductIds": {
                      "google": "material_guardian_individual_yearly"
                    },
                    "futureBilling": {}
                  }
                ]
              }
              ''',
            200,
            headers: {'content-type': 'application/json'},
          );
        }
        if (request.url.path == '/me') {
          return http.Response(
            '{"user":{"id":"user_deferred","email":"deferred@materialguardian.test","displayName":"Deferred User","status":"active","createdAt":"2026-04-02T12:00:00.000Z","lastLoginAt":"2026-04-02T12:05:00.000Z"},"memberships":[],"currentSeatAssignment":{"organizationId":null,"status":"not_applicable"},"trialState":{"remainingJobs":6},"activeEntitlement":{"productCode":"material_guardian","planCode":"material_guardian_individual_yearly","accessState":"paid","seatAvailability":"not_applicable","subscriptionState":"active","trialRemaining":0,"organizationId":null,"startsAt":"2026-04-02T12:00:00.000Z","endsAt":"2027-04-02T12:00:00.000Z"},"activeSession":{"id":"session_deferred","deviceLabel":"Kevin PowerShell","platform":"android","status":"active","issuedAt":"2026-04-02T12:05:00.000Z","lastSeenAt":"2026-04-02T12:05:00.000Z","revokedAt":null}}',
            200,
            headers: {'content-type': 'application/json'},
          );
        }
        if (request.url.path == '/entitlements/current') {
          return http.Response(
            '{"productCode":"material_guardian","planCode":"material_guardian_individual_yearly","accessState":"paid","seatAvailability":"not_applicable","subscriptionState":"active","trialRemaining":0,"organizationId":null,"startsAt":"2026-04-02T12:00:00.000Z","endsAt":"2027-04-02T12:00:00.000Z"}',
            200,
            headers: {'content-type': 'application/json'},
          );
        }
        if (request.url.path == '/purchases/google/verify') {
          return http.Response(
            '{"status":"ok","subscription":{"id":"sub_deferred","provider":"google","planCode":"material_guardian_individual_yearly","status":"active","providerSubscriptionRef":"token_deferred","providerOriginalRef":"token_deferred","startsAt":"2026-04-02T12:00:00.000Z","endsAt":"2027-04-02T12:00:00.000Z"},"activeEntitlement":{"productCode":"material_guardian","planCode":"material_guardian_individual_yearly","accessState":"paid","seatAvailability":"not_applicable","subscriptionState":"active","trialRemaining":0,"organizationId":null,"startsAt":"2026-04-02T12:00:00.000Z","endsAt":"2027-04-02T12:00:00.000Z"}}',
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

    final appState = MaterialGuardianAppState.seeded(
      backendApiService: service,
      authSessionStore: sessionStore,
      storePurchaseService: store,
    );
    await appState.startBackendSignIn(
      email: 'deferred@materialguardian.test',
      displayName: 'Deferred User',
    );
    await appState.completeBackendSignIn(code: '246810');

    store.emitPurchaseUpdates(const <StorePurchaseUpdate>[
      StorePurchaseUpdate(
        productId: 'material_guardian_individual_yearly',
        purchaseId: 'purchase-deferred',
        status: 'purchased',
        provider: 'google',
        pendingCompletePurchase: false,
        verificationServerData: 'server-data',
        verificationLocalData: 'local-data',
        verificationSource: 'google_play',
        transactionDate: null,
        providerTransactionRef: 'GPA.4444-5555-6666',
        providerOriginalRef: 'token_deferred',
        errorMessage: null,
      ),
    ]);
    await Future<void>.delayed(const Duration(milliseconds: 10));

    expect(
      requests.where(
        (request) => request.url.path == '/purchases/google/verify',
      ),
      isEmpty,
    );
    expect(
      appState.purchaseStatusMessage,
      contains('Finishing store verification'),
    );

    await appState.loadPurchaseCatalog();
    await Future<void>.delayed(const Duration(milliseconds: 10));

    expect(
      requests
          .where((request) => request.url.path == '/purchases/google/verify')
          .length,
      1,
    );
    expect(
      appState.purchaseStatusMessage,
      'Purchase verified. Your backend access has been refreshed.',
    );
  });

  test(
    'business purchase verification surfaces seat assignment required when backend returns no seat',
    () async {
      final store = _TrackingStorePurchaseService(
        available: true,
        queryResult: const StoreProductQueryResult(
          products: <StoreProductSnapshot>[
            StoreProductSnapshot(
              id: 'material_guardian_business_5_yearly',
              title: 'Business Yearly',
              description: '5 users yearly',
              price: '\$299.99',
              currencyCode: 'USD',
              rawPrice: 299.99,
            ),
          ],
          notFoundIds: <String>[],
          errorMessage: null,
        ),
      );
      final service = BackendApiService(
        baseUrl: 'https://backend.example.test',
        client: MockClient((request) async {
          if (request.url.path == '/auth/start') {
            return http.Response(
              '{"flowId":"flow_business","deliveryTarget":"business@materialguardian.test","expiresAt":"2026-04-02T18:30:00.000Z","demoCode":"246810"}',
              200,
              headers: {'content-type': 'application/json'},
            );
          }
          if (request.url.path == '/auth/complete') {
            return http.Response(
              '{"status":"authenticated","accessToken":"access-business","refreshToken":"refresh-business","user":{"id":"user_business","email":"business@materialguardian.test","displayName":"Business User","status":"active","createdAt":"2026-04-02T12:00:00.000Z","lastLoginAt":"2026-04-02T12:05:00.000Z"},"memberships":[{"id":"membership_business","organizationId":"org_business","organizationName":"Business Org","role":"owner","seatStatus":"unassigned","invitedAt":"2026-04-02T12:00:00.000Z","acceptedAt":"2026-04-02T12:01:00.000Z"}],"activeEntitlement":{"productCode":"material_guardian_business","planCode":"material_guardian_business_5_yearly","accessState":"trial","seatAvailability":"not_applicable","subscriptionState":"none","trialRemaining":6,"organizationId":"org_business","startsAt":"2026-04-02T12:00:00.000Z","endsAt":null},"session":{"id":"session_business","deviceLabel":"Kevin PowerShell","platform":"android","status":"active","issuedAt":"2026-04-02T12:05:00.000Z","lastSeenAt":"2026-04-02T12:05:00.000Z","revokedAt":null}}',
              200,
              headers: {'content-type': 'application/json'},
            );
          }
          if (request.url.path == '/plans') {
            return http.Response(
              '''
              {
                "plans": [
                  {
                    "planCode": "material_guardian_business_5_yearly",
                    "productCode": "material_guardian_business",
                    "audienceType": "business",
                    "billingInterval": "yearly",
                    "seatLimit": 5,
                    "displayPrice": "\$299.99",
                    "displayPriceCents": 29999,
                    "storeProductIds": {
                      "google": "material_guardian_business_5_yearly"
                    },
                    "futureBilling": {}
                  }
                ]
              }
              ''',
              200,
              headers: {'content-type': 'application/json'},
            );
          }
          if (request.url.path == '/me') {
            return http.Response(
              '{"user":{"id":"user_business","email":"business@materialguardian.test","displayName":"Business User","status":"active","createdAt":"2026-04-02T12:00:00.000Z","lastLoginAt":"2026-04-02T12:05:00.000Z"},"memberships":[{"id":"membership_business","organizationId":"org_business","organizationName":"Business Org","role":"owner","seatStatus":"unassigned","invitedAt":"2026-04-02T12:00:00.000Z","acceptedAt":"2026-04-02T12:01:00.000Z"}],"currentSeatAssignment":{"organizationId":"org_business","status":"unassigned"},"trialState":null,"activeEntitlement":{"productCode":"material_guardian_business","planCode":"material_guardian_business_5_yearly","accessState":"no_seat","seatAvailability":"unassigned","subscriptionState":"active","trialRemaining":0,"organizationId":"org_business","startsAt":"2026-04-02T12:00:00.000Z","endsAt":"2027-04-02T12:00:00.000Z"},"activeSession":{"id":"session_business","deviceLabel":"Kevin PowerShell","platform":"android","status":"active","issuedAt":"2026-04-02T12:05:00.000Z","lastSeenAt":"2026-04-02T12:05:00.000Z","revokedAt":null}}',
              200,
              headers: {'content-type': 'application/json'},
            );
          }
          if (request.url.path == '/entitlements/current') {
            return http.Response(
              '{"productCode":"material_guardian_business","planCode":"material_guardian_business_5_yearly","accessState":"no_seat","seatAvailability":"unassigned","subscriptionState":"active","trialRemaining":0,"organizationId":"org_business","startsAt":"2026-04-02T12:00:00.000Z","endsAt":"2027-04-02T12:00:00.000Z"}',
              200,
              headers: {'content-type': 'application/json'},
            );
          }
          if (request.url.path == '/organizations/org_business') {
            return http.Response(
              '{"id":"org_business","name":"Business Org","status":"active","planCode":"material_guardian_business_5_yearly","seatLimit":5,"seatsAssigned":0,"seatsRemaining":5,"userCount":1,"members":[]}',
              200,
              headers: {'content-type': 'application/json'},
            );
          }
          if (request.url.path == '/purchases/google/verify') {
            return http.Response(
              '{"status":"ok","subscription":{"id":"sub_business","provider":"google","planCode":"material_guardian_business_5_yearly","status":"active","providerSubscriptionRef":"token_business","providerOriginalRef":"token_business","startsAt":"2026-04-02T12:00:00.000Z","endsAt":"2027-04-02T12:00:00.000Z"},"activeEntitlement":{"productCode":"material_guardian_business","planCode":"material_guardian_business_5_yearly","accessState":"no_seat","seatAvailability":"unassigned","subscriptionState":"active","trialRemaining":0,"organizationId":"org_business","startsAt":"2026-04-02T12:00:00.000Z","endsAt":"2027-04-02T12:00:00.000Z"}}',
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

      final appState = MaterialGuardianAppState.seeded(
        backendApiService: service,
        storePurchaseService: store,
      );
      await appState.startBackendSignIn(
        email: 'business@materialguardian.test',
        displayName: 'Business User',
      );
      await appState.completeBackendSignIn(code: '246810');
      await appState.loadPurchaseCatalog();

      store.emitPurchaseUpdates(const <StorePurchaseUpdate>[
        StorePurchaseUpdate(
          productId: 'material_guardian_business_5_yearly',
          purchaseId: 'purchase-business',
          status: 'restored',
          provider: 'google',
          pendingCompletePurchase: false,
          verificationServerData: 'server-data',
          verificationLocalData: 'local-data',
          verificationSource: 'google_play',
          transactionDate: null,
          providerTransactionRef: 'GPA.7777-8888-9999',
          providerOriginalRef: 'token_business',
          errorMessage: null,
        ),
      ]);
      await Future<void>.delayed(const Duration(milliseconds: 10));

      expect(
        appState.purchaseStatusMessage,
        contains('seat still needs to be assigned'),
      );
      expect(appState.isSeatBlocked, isTrue);
    },
  );

  test(
    'loadPurchaseCatalog ignores non-Material Guardian plans from shared backend catalog',
    () async {
      final service = BackendApiService(
        baseUrl: 'https://backend.example.test',
        client: MockClient((request) async {
          if (request.url.path == '/plans') {
            return http.Response(
              '''
            {
              "plans": [
                {
                  "planCode": "material_guardian_individual_monthly",
                  "productCode": "material_guardian",
                  "audienceType": "individual",
                  "billingInterval": "monthly",
                  "seatLimit": 1,
                  "displayPrice": "\$9.99",
                  "displayPriceCents": 999,
                  "storeProductIds": {
                    "google": "material_guardian_individual_monthly"
                  },
                  "futureBilling": {}
                },
                {
                  "planCode": "flange_helper_pc_program_monthly",
                  "productCode": "flange_helper_pc_program",
                  "audienceType": "individual",
                  "billingInterval": "monthly",
                  "seatLimit": 1,
                  "displayPrice": "\$29.99",
                  "displayPriceCents": 2999,
                  "storeProductIds": {
                    "google": "flange_helper_pc_program_monthly"
                  },
                  "futureBilling": {}
                }
              ]
            }
            ''',
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

      final store = _TrackingStorePurchaseService(
        available: true,
        queryResult: const StoreProductQueryResult(
          products: <StoreProductSnapshot>[],
          notFoundIds: <String>['material_guardian_individual_monthly'],
          errorMessage: null,
        ),
      );
      final appState = MaterialGuardianAppState.seeded(
        backendApiService: service,
        storePurchaseService: store,
      );

      await appState.loadPurchaseCatalog();

      expect(
        appState.backendPlans
            .map((plan) => plan.planCode)
            .toList(growable: false),
        equals(<String>['material_guardian_individual_monthly']),
      );
    },
  );

  test('purchase verification failure does not acknowledge the Play purchase', () async {
    final store = _TrackingStorePurchaseService(
      available: true,
      queryResult: const StoreProductQueryResult(
        products: <StoreProductSnapshot>[
          StoreProductSnapshot(
            id: 'material_guardian_individual_yearly',
            title: 'Material Guardian Individual Yearly',
            description: 'Yearly individual access',
            price: '\$99.99',
            currencyCode: 'USD',
            rawPrice: 99.99,
          ),
        ],
        notFoundIds: <String>[],
        errorMessage: null,
      ),
    );
    final service = BackendApiService(
      baseUrl: 'https://backend.example.test',
      client: MockClient((request) async {
        if (request.url.path == '/plans') {
          return http.Response(
            '''
            {
              "plans": [
                {
                  "planCode": "material_guardian_individual_yearly",
                  "productCode": "material_guardian",
                  "audienceType": "individual",
                  "billingInterval": "yearly",
                  "seatLimit": 1,
                  "displayPrice": "\$99.99",
                  "displayPriceCents": 9999,
                  "storeProductIds": {
                    "google": "material_guardian_individual_yearly"
                  },
                  "futureBilling": {}
                }
              ]
            }
            ''',
            200,
            headers: {'content-type': 'application/json'},
          );
        }
        if (request.url.path == '/auth/start') {
          return http.Response(
            '{"flowId":"flow_paid","deliveryTarget":"paid@materialguardian.test","expiresAt":"2026-04-02T18:30:00.000Z","demoCode":"246810"}',
            200,
            headers: {'content-type': 'application/json'},
          );
        }
        if (request.url.path == '/auth/complete') {
          return http.Response(
            '{"status":"authenticated","accessToken":"access-paid","refreshToken":"refresh-paid","user":{"id":"user_paid","email":"paid@materialguardian.test","displayName":"Paid User","status":"active","createdAt":"2026-04-02T12:00:00.000Z","lastLoginAt":"2026-04-02T12:05:00.000Z"},"memberships":[],"activeEntitlement":{"productCode":"material_guardian","planCode":"material_guardian_individual_yearly","accessState":"trial","seatAvailability":"not_applicable","subscriptionState":"none","trialRemaining":6,"organizationId":null,"startsAt":"2026-04-02T12:00:00.000Z","endsAt":null},"session":{"id":"session_paid","deviceLabel":"Kevin PowerShell","platform":"web","status":"active","issuedAt":"2026-04-02T12:05:00.000Z","lastSeenAt":"2026-04-02T12:05:00.000Z","revokedAt":null}}',
            200,
            headers: {'content-type': 'application/json'},
          );
        }
        if (request.url.path == '/purchases/google/verify') {
          return http.Response(
            '{"error":"verification failed"}',
            500,
            headers: {'content-type': 'application/json'},
          );
        }
        if (request.url.path == '/me') {
          return http.Response(
            '{"user":{"id":"user_paid","email":"paid@materialguardian.test","displayName":"Paid User","status":"active","createdAt":"2026-04-02T12:00:00.000Z","lastLoginAt":"2026-04-02T12:05:00.000Z"},"memberships":[],"currentSeatAssignment":{"organizationId":null,"status":"not_applicable"},"trialState":{"remainingJobs":6},"activeEntitlement":{"productCode":"material_guardian","planCode":"material_guardian_individual_yearly","accessState":"trial","seatAvailability":"not_applicable","subscriptionState":"none","trialRemaining":6,"organizationId":null,"startsAt":"2026-04-02T12:00:00.000Z","endsAt":null},"activeSession":{"id":"session_paid","deviceLabel":"Kevin PowerShell","platform":"web","status":"active","issuedAt":"2026-04-02T12:05:00.000Z","lastSeenAt":"2026-04-02T12:05:00.000Z","revokedAt":null}}',
            200,
            headers: {'content-type': 'application/json'},
          );
        }
        if (request.url.path == '/entitlements/current') {
          return http.Response(
            '{"productCode":"material_guardian","planCode":"material_guardian_individual_yearly","accessState":"trial","seatAvailability":"not_applicable","subscriptionState":"none","trialRemaining":6,"organizationId":null,"startsAt":"2026-04-02T12:00:00.000Z","endsAt":null}',
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

    final appState = MaterialGuardianAppState.seeded(
      backendApiService: service,
      storePurchaseService: store,
    );
    await appState.startBackendSignIn(
      email: 'paid@materialguardian.test',
      displayName: 'Paid User',
    );
    await appState.completeBackendSignIn(code: '246810');
    await appState.loadPurchaseCatalog();

    store.emitPurchaseUpdates(const <StorePurchaseUpdate>[
      StorePurchaseUpdate(
        productId: 'material_guardian_individual_yearly',
        purchaseId: 'purchase-123',
        status: 'purchased',
        provider: 'google',
        pendingCompletePurchase: true,
        verificationServerData: 'server-data',
        verificationLocalData: 'local-data',
        verificationSource: 'google_play',
        transactionDate: null,
        providerTransactionRef: 'GPA.1234-5678-9012-34567',
        providerOriginalRef: 'purchase-token-123',
        errorMessage: null,
      ),
    ]);
    await Future<void>.delayed(const Duration(milliseconds: 10));

    expect(store.completedProductIds, isEmpty);
    expect(
      appState.purchaseError,
      contains('backend verification did not finish'),
    );
  });

  testWidgets(
    'signed-in seated non-admin still sees account entry for self-service actions',
    (tester) async {
      final sessionStore = InMemoryBackendAuthSessionStore();
      final service = BackendApiService(
        baseUrl:
            'https://app-platforms-backend-dev-293518443128.us-east4.run.app',
        client: MockClient((request) async {
          if (request.url.path.endsWith('/auth/start')) {
            return http.Response(
              '{"flowId":"flow_member","deliveryTarget":"member@materialguardian.test","expiresAt":"2026-04-02T18:30:00.000Z","demoCode":"246810"}',
              200,
              headers: {'content-type': 'application/json'},
            );
          }

          if (request.url.path.endsWith('/auth/complete')) {
            return http.Response(
              '{"status":"authenticated","accessToken":"access-member","refreshToken":"refresh-member","user":{"id":"user_member","email":"member@materialguardian.test","displayName":"Field User","status":"active","createdAt":"2026-04-02T12:00:00.000Z","lastLoginAt":"2026-04-02T12:05:00.000Z"},"memberships":[{"id":"membership_member","organizationId":"org_acme","organizationName":"Acme Fabrication","role":"member","seatStatus":"assigned","invitedAt":"2026-04-02T12:00:00.000Z","acceptedAt":"2026-04-02T12:01:00.000Z"}],"activeEntitlement":{"productCode":"material_guardian","planCode":"material_guardian_business_5_monthly","accessState":"paid","seatAvailability":"assigned","subscriptionState":"active","trialRemaining":0,"organizationId":"org_acme","startsAt":"2026-04-02T12:00:00.000Z","endsAt":null},"session":{"id":"session_member","deviceLabel":"Kevin PowerShell","platform":"web","status":"active","issuedAt":"2026-04-02T12:05:00.000Z","lastSeenAt":"2026-04-02T12:05:00.000Z","revokedAt":null}}',
              200,
              headers: {'content-type': 'application/json'},
            );
          }

          if (request.url.path.endsWith('/me')) {
            return http.Response(
              '{"user":{"id":"user_member","email":"member@materialguardian.test","displayName":"Field User","status":"active","createdAt":"2026-04-02T12:00:00.000Z","lastLoginAt":"2026-04-02T12:05:00.000Z"},"memberships":[{"id":"membership_member","organizationId":"org_acme","organizationName":"Acme Fabrication","role":"member","seatStatus":"assigned","invitedAt":"2026-04-02T12:00:00.000Z","acceptedAt":"2026-04-02T12:01:00.000Z"}],"currentSeatAssignment":{"organizationId":"org_acme","status":"assigned"},"trialState":null,"activeEntitlement":{"productCode":"material_guardian","planCode":"material_guardian_business_5_monthly","accessState":"paid","seatAvailability":"assigned","subscriptionState":"active","trialRemaining":0,"organizationId":"org_acme","startsAt":"2026-04-02T12:00:00.000Z","endsAt":null},"activeSession":{"id":"session_member","deviceLabel":"Kevin PowerShell","platform":"web","status":"active","issuedAt":"2026-04-02T12:05:00.000Z","lastSeenAt":"2026-04-02T12:05:00.000Z","revokedAt":null}}',
              200,
              headers: {'content-type': 'application/json'},
            );
          }

          if (request.url.path.endsWith('/entitlements/current')) {
            return http.Response(
              '{"productCode":"material_guardian","planCode":"material_guardian_business_5_monthly","accessState":"paid","seatAvailability":"assigned","subscriptionState":"active","trialRemaining":0,"organizationId":"org_acme","startsAt":"2026-04-02T12:00:00.000Z","endsAt":null}',
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

      final appState = MaterialGuardianAppState.seeded(
        backendApiService: service,
        authSessionStore: sessionStore,
      );

      await appState.startBackendSignIn(
        email: 'member@materialguardian.test',
        displayName: 'Field User',
      );
      await appState.completeBackendSignIn(code: '246810');

      await tester.pumpWidget(
        MaterialApp(home: JobsScreen(appState: appState)),
      );
      await tester.pumpAndSettle();

      expect(find.text('Plans'), findsOneWidget);
      expect(find.text('Customization'), findsOneWidget);
      expect(find.text('Account'), findsOneWidget);
    },
  );

  testWidgets(
    'signed-in admin account screen is account admin only and clamps org inputs',
    (tester) async {
      final sessionStore = InMemoryBackendAuthSessionStore();
      final service = BackendApiService(
        baseUrl:
            'https://app-platforms-backend-dev-293518443128.us-east4.run.app',
        client: MockClient((request) async {
          if (request.url.path.endsWith('/auth/start')) {
            return http.Response(
              '{"flowId":"flow_admin","deliveryTarget":"owner@materialguardian.test","expiresAt":"2026-04-02T18:30:00.000Z","demoCode":"246810"}',
              200,
              headers: {'content-type': 'application/json'},
            );
          }

          if (request.url.path.endsWith('/auth/complete')) {
            return http.Response(
              '{"status":"authenticated","accessToken":"access-admin","refreshToken":"refresh-admin","user":{"id":"user_admin","email":"owner@materialguardian.test","displayName":"Owner","status":"active","createdAt":"2026-04-02T12:00:00.000Z","lastLoginAt":"2026-04-02T12:05:00.000Z"},"memberships":[{"id":"membership_owner","organizationId":"org_acme","organizationName":"Acme Fabrication","role":"owner","seatStatus":"assigned","invitedAt":"2026-04-02T12:00:00.000Z","acceptedAt":"2026-04-02T12:01:00.000Z"}],"activeEntitlement":{"productCode":"material_guardian","planCode":"material_guardian_business_5_monthly","accessState":"paid","seatAvailability":"assigned","subscriptionState":"active","trialRemaining":0,"organizationId":"org_acme","startsAt":"2026-04-02T12:00:00.000Z","endsAt":null},"session":{"id":"session_admin","deviceLabel":"Kevin PowerShell","platform":"web","status":"active","issuedAt":"2026-04-02T12:05:00.000Z","lastSeenAt":"2026-04-02T12:05:00.000Z","revokedAt":null}}',
              200,
              headers: {'content-type': 'application/json'},
            );
          }

          if (request.url.path.endsWith('/me')) {
            return http.Response(
              '{"user":{"id":"user_admin","email":"owner@materialguardian.test","displayName":"Owner","status":"active","createdAt":"2026-04-02T12:00:00.000Z","lastLoginAt":"2026-04-02T12:05:00.000Z"},"memberships":[{"id":"membership_owner","organizationId":"org_acme","organizationName":"Acme Fabrication","role":"owner","seatStatus":"assigned","invitedAt":"2026-04-02T12:00:00.000Z","acceptedAt":"2026-04-02T12:01:00.000Z"}],"currentSeatAssignment":{"organizationId":"org_acme","status":"assigned"},"trialState":null,"activeEntitlement":{"productCode":"material_guardian","planCode":"material_guardian_business_5_monthly","accessState":"paid","seatAvailability":"assigned","subscriptionState":"active","trialRemaining":0,"organizationId":"org_acme","startsAt":"2026-04-02T12:00:00.000Z","endsAt":null},"activeSession":{"id":"session_admin","deviceLabel":"Kevin PowerShell","platform":"web","status":"active","issuedAt":"2026-04-02T12:05:00.000Z","lastSeenAt":"2026-04-02T12:05:00.000Z","revokedAt":null}}',
              200,
              headers: {'content-type': 'application/json'},
            );
          }

          if (request.url.path.endsWith('/entitlements/current')) {
            return http.Response(
              '{"productCode":"material_guardian","planCode":"material_guardian_business_5_monthly","accessState":"paid","seatAvailability":"assigned","subscriptionState":"active","trialRemaining":0,"organizationId":"org_acme","startsAt":"2026-04-02T12:00:00.000Z","endsAt":null}',
              200,
              headers: {'content-type': 'application/json'},
            );
          }

          if (request.url.path.endsWith('/organizations/org_acme')) {
            return http.Response(
              '{"id":"org_acme","name":"Acme Fabrication","status":"active","planCode":"material_guardian_business_5_monthly","seatLimit":5,"seatsAssigned":2,"seatsRemaining":3,"userCount":3,"members":[]}',
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

      final appState = MaterialGuardianAppState.seeded(
        backendApiService: service,
        authSessionStore: sessionStore,
      );

      await appState.startBackendSignIn(
        email: 'owner@materialguardian.test',
        displayName: 'Owner',
      );
      await appState.completeBackendSignIn(code: '246810');

      await tester.pumpWidget(
        MaterialApp(home: AccountScreen(appState: appState)),
      );
      await tester.pumpAndSettle();

      expect(find.text('Plans & Billing'), findsNothing);
      expect(find.text('Plans'), findsOneWidget);
      final scrollable = find.byType(Scrollable).first;
      await tester.scrollUntilVisible(
        find.text('Need another company workspace?'),
        200,
        scrollable: scrollable,
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Need another company workspace?'));
      await tester.pumpAndSettle();

      expect(
        find.widgetWithText(FilledButton, 'Create New Workspace'),
        findsOneWidget,
      );

      await tester.scrollUntilVisible(
        find.widgetWithText(FilledButton, 'Invite Member'),
        200,
        scrollable: scrollable,
      );
      await tester.pumpAndSettle();

      Finder textFieldByLabel(String label) {
        return find.byWidgetPredicate(
          (widget) =>
              widget is TextField && widget.decoration?.labelText == label,
        );
      }

      final inviteEmailField = textFieldByLabel('Invite Email');
      final inviteNameField = textFieldByLabel('Display Name (optional)');

      await tester.enterText(inviteEmailField, 'e' * 150);
      await tester.enterText(inviteNameField, 'n' * 60);
      await tester.pump();

      expect(
        tester.widget<TextField>(inviteEmailField).controller?.text.length,
        120,
      );
      expect(
        tester.widget<TextField>(inviteNameField).controller?.text.length,
        40,
      );
    },
  );
}

class _FakeStorePurchaseService implements StorePurchaseService {
  const _FakeStorePurchaseService({
    required this.available,
    required this.queryResult,
    this.restoreResult = const StoreRestoreResult(
      updates: <StorePurchaseUpdate>[],
      errorMessage: null,
    ),
  });

  final bool available;
  final StoreProductQueryResult queryResult;
  final StoreRestoreResult restoreResult;

  @override
  Stream<List<StorePurchaseUpdate>> get purchaseUpdates =>
      const Stream<List<StorePurchaseUpdate>>.empty();

  @override
  Future<bool> isAvailable() async => available;

  @override
  Future<StoreProductQueryResult> queryProducts(Set<String> productIds) async =>
      queryResult;

  @override
  Future<void> buyProduct(String productId) async {}

  @override
  Future<void> completePurchase(String productId) async {}

  @override
  Future<StoreRestoreResult> restorePurchases() async => restoreResult;

  @override
  void dispose() {}
}

class _TrackingStorePurchaseService implements StorePurchaseService {
  _TrackingStorePurchaseService({
    required this.available,
    required this.queryResult,
  });

  final bool available;
  final StoreProductQueryResult queryResult;
  final StreamController<List<StorePurchaseUpdate>> _controller =
      StreamController<List<StorePurchaseUpdate>>.broadcast();
  final List<String> completedProductIds = <String>[];
  Set<String> lastQueriedProductIds = <String>{};
  StoreRestoreResult restoreResult = const StoreRestoreResult(
    updates: <StorePurchaseUpdate>[],
    errorMessage: null,
  );

  @override
  Stream<List<StorePurchaseUpdate>> get purchaseUpdates => _controller.stream;

  @override
  Future<bool> isAvailable() async => available;

  @override
  Future<StoreProductQueryResult> queryProducts(Set<String> productIds) async {
    lastQueriedProductIds = Set<String>.from(productIds);
    return queryResult;
  }

  @override
  Future<void> buyProduct(String productId) async {}

  @override
  Future<void> completePurchase(String productId) async {
    completedProductIds.add(productId);
  }

  @override
  Future<StoreRestoreResult> restorePurchases() async => restoreResult;

  void emitPurchaseUpdates(List<StorePurchaseUpdate> updates) {
    _controller.add(updates);
  }

  @override
  void dispose() {
    unawaited(_controller.close());
  }
}
