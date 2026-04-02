import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:material_guardian_mobile/app/material_guardian_app.dart';
import 'package:material_guardian_mobile/app/material_guardian_state.dart';
import 'package:material_guardian_mobile/data/backend_auth_session_store.dart';
import 'package:material_guardian_mobile/screens/material_form_screen.dart';
import 'package:material_guardian_mobile/services/backend_api_service.dart';
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
      MaterialGuardianApp(appState: MaterialGuardianAppState.seeded()),
    );
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();

    expect(find.text('Create Job'), findsOneWidget);
    expect(find.text('Current Jobs'), findsOneWidget);
    expect(find.text('Drafts (1)'), findsNothing);

    final firstJob = find.text('Job# MG-24031');
    await tester.ensureVisible(firstJob);
    await tester.tap(firstJob);
    await tester.pumpAndSettle();

    expect(find.text('JOB DETAILS'), findsOneWidget);
    expect(find.text('Resume Draft'), findsOneWidget);
  });

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
    final markingsField = textFieldByLabel('Actual Markings');

    expect(find.text('Actual Surface Finish Reading'), findsOneWidget);
    expect(find.text('u-in'), findsOneWidget);

    await tester.enterText(descriptionField, 'X' * 60);
    await tester.enterText(poField, 'P' * 30);
    await tester.enterText(quantityField, '123456789');
    await tester.enterText(qcManagerField, 'ManagerNameTooLongForDonorParity');
    await tester.pump();

    expect(
      tester.widget<TextField>(descriptionField).controller?.text,
      'X' * 40,
    );
    expect(tester.widget<TextField>(poField).controller?.text, 'P' * 20);
    expect(tester.widget<TextField>(quantityField).controller?.text, '123456');
    expect(
      tester.widget<TextField>(qcManagerField).controller?.text,
      'ManagerNameTooLongFo',
    );
    expect(tester.widget<TextField>(markingsField).maxLines, 5);
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

  test('billing catalog surfaces missing Play product IDs instead of failing silently', () async {
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
  });

  test('restoring purchases does not leave the app stuck in purchasing mode', () async {
    final appState = MaterialGuardianAppState.seeded(
      storePurchaseService: const _FakeStorePurchaseService(
        available: true,
        queryResult: StoreProductQueryResult(
          products: <StoreProductSnapshot>[],
          notFoundIds: <String>[],
          errorMessage: null,
        ),
      ),
    );

    await appState.restorePurchases();

    expect(appState.isRestoringPurchases, isFalse);
    expect(appState.isPurchasing, isFalse);
    expect(appState.purchaseStatusMessage, isNull);
  });
}

class _FakeStorePurchaseService implements StorePurchaseService {
  const _FakeStorePurchaseService({
    required this.available,
    required this.queryResult,
  });

  final bool available;
  final StoreProductQueryResult queryResult;

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
  Future<void> restorePurchases() async {}

  @override
  void dispose() {}
}
