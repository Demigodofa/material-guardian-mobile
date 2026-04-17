import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:image/image.dart' as img;
import 'package:path/path.dart' as p;

import 'package:material_guardian_mobile/app/material_guardian_state.dart';
import 'package:material_guardian_mobile/data/backend_auth_session_store.dart';
import 'package:material_guardian_mobile/services/backend_api_service.dart';

const MethodChannel _pathProviderChannel = MethodChannel(
  'plugins.flutter.io/path_provider',
);
const MethodChannel _sharedPreferencesChannel = MethodChannel(
  'plugins.flutter.io/shared_preferences',
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final sharedPreferencesState = <String, Object>{};

  setUpAll(() async {
    final testDirectory = Directory(
      '${Directory.systemTemp.path}/material_guardian_mobile_release_stress',
    );
    await testDirectory.create(recursive: true);

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_pathProviderChannel, (call) async {
          if (call.method == 'getApplicationSupportDirectory') {
            return testDirectory.path;
          }
          return null;
        });
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_sharedPreferencesChannel, (call) async {
          switch (call.method) {
            case 'getAll':
              return Map<String, Object>.from(sharedPreferencesState);
            case 'setString':
            case 'setBool':
            case 'setInt':
            case 'setDouble':
            case 'setStringList':
              final rawArguments = call.arguments;
              if (rawArguments is List<dynamic>) {
                sharedPreferencesState[rawArguments[0] as String] =
                    rawArguments[1] as Object;
              } else if (rawArguments is Map) {
                final key = rawArguments['key']?.toString() ?? '';
                if (key.isNotEmpty) {
                  sharedPreferencesState[key] = rawArguments['value'] as Object;
                }
              }
              return true;
            case 'remove':
              sharedPreferencesState.remove(call.arguments as String);
              return true;
            case 'clear':
              sharedPreferencesState.clear();
              return true;
          }
          return null;
        });
  });

  tearDownAll(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_pathProviderChannel, null);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_sharedPreferencesChannel, null);
  });

  test('stress export creates 15 media-heavy receiving packets', () async {
    final probeRoot = Directory(
      p.join(
        Directory.systemTemp.path,
        'material_guardian_release_stress_assets',
        DateTime.now().microsecondsSinceEpoch.toString(),
      ),
    );
    await probeRoot.create(recursive: true);

    final appState = MaterialGuardianAppState.seededSignedIn();
    await appState.saveJob(
      jobNumber: 'STRESS-BULK',
      description: 'Media-heavy release probe',
      notes: '15 receiving reports in one job',
    );
    final stressJobId = appState.jobs
        .firstWhere((job) => job.jobNumber == 'STRESS-BULK')
        .id;

    for (var materialIndex = 1; materialIndex <= 15; materialIndex++) {
      final draft = await appState.createBlankDraft(jobId: stressJobId);
      final photoPaths = <String>[];
      final scanPaths = <String>[];
      for (var photoIndex = 1; photoIndex <= 4; photoIndex++) {
        photoPaths.add(
          await _writeProbeImage(
            probeRoot,
            'material_${materialIndex}_photo_$photoIndex.jpg',
            fillColor: img.ColorRgb8(210, 220 - photoIndex * 5, 235),
            accentColor: img.ColorRgb8(45 + photoIndex * 10, 70, 105),
          ),
        );
      }
      for (var scanIndex = 1; scanIndex <= 2; scanIndex++) {
        scanPaths.add(
          await _writeProbeImage(
            probeRoot,
            'material_${materialIndex}_scan_image_$scanIndex.jpg',
            fillColor: img.ColorRgb8(240, 236, 224),
            accentColor: img.ColorRgb8(120, 95 + scanIndex * 10, 45),
          ),
        );
      }
      for (var scanIndex = 3; scanIndex <= 4; scanIndex++) {
        scanPaths.add(
          await _writeProbePdfWithPreview(
            probeRoot,
            'material_${materialIndex}_scan_pdf_$scanIndex',
          ),
        );
      }
      final inspectorSignature = await _writeProbeImage(
        probeRoot,
        'material_${materialIndex}_inspector_signature.png',
        fillColor: img.ColorRgb8(250, 250, 250),
        accentColor: img.ColorRgb8(20, 20, 20),
      );
      final managerSignature = await _writeProbeImage(
        probeRoot,
        'material_${materialIndex}_manager_signature.png',
        fillColor: img.ColorRgb8(252, 252, 252),
        accentColor: img.ColorRgb8(110, 30, 30),
      );

      await appState.saveDraft(
        draft.copyWith(
          description: 'Stress Material $materialIndex',
          materialTag: 'TAG-$materialIndex',
          vendor: 'Granite Supplier $materialIndex',
          quantity: '${materialIndex + 1}',
          productType: materialIndex.isEven ? 'Plate' : 'Pipe',
          thickness1: '${materialIndex / 8}',
          width: '${materialIndex * 3}"',
          length: '${materialIndex + 20}\' $materialIndex"',
          diameter: materialIndex.isOdd ? '${materialIndex + 1}"' : '',
          diameterType: materialIndex.isOdd ? 'O.D.' : '',
          surfaceFinish: materialIndex.isEven ? 'SF2' : '',
          surfaceFinishReading: materialIndex.isEven ? '118' : '',
          markings: 'Heat ${1000 + materialIndex}, Lot ${2000 + materialIndex}',
          comments: 'Stress export material $materialIndex',
          qcInspectorName: 'Inspector $materialIndex',
          qcManagerName: 'Manager $materialIndex',
          qcManagerDate: DateTime(2026, 4, materialIndex.clamp(1, 28)),
          qcManagerDateEnabled: materialIndex.isEven,
          qcManagerDateManual: materialIndex.isEven,
          qcSignaturePath: inspectorSignature,
          qcManagerSignaturePath: materialIndex.isEven ? managerSignature : '',
          photoPaths: photoPaths,
          scanPaths: scanPaths,
        ),
      );
      await appState.completeDraft(appState.draftById(draft.id));
    }

    final exportResult = await appState.exportJob(stressJobId);
    final summary = File(p.join(probeRoot.path, 'stress_export_summary.txt'));
    await summary.writeAsString(
      [
        'jobId=$stressJobId',
        'exportRoot=${exportResult.exportRootPath}',
        'zipPath=${exportResult.zipPath}',
        'packetCount=${exportResult.packetCount}',
        'photoCount=${exportResult.photoCount}',
        'scanCount=${exportResult.scanCount}',
      ].join('\n'),
      flush: true,
    );

    expect(exportResult.packetCount, 15);
    expect(exportResult.photoCount, 60);
    expect(exportResult.scanCount, 60);
    expect(await Directory(exportResult.exportRootPath).exists(), isTrue);
    expect(await File(exportResult.zipPath).exists(), isTrue);
    expect(await summary.exists(), isTrue);

    // ignore: avoid_print
    print('stress_export_root=${exportResult.exportRootPath}');
  });

  test('trial access locks before a seventh new job is created', () async {
    final sessionStore = InMemoryBackendAuthSessionStore();
    var jobsUsed = 0;
    final service = BackendApiService(
      baseUrl:
          'https://app-platforms-backend-dev-293518443128.us-east4.run.app',
      client: MockClient((request) async {
        if (request.url.path.endsWith('/auth/start')) {
          return http.Response(
            '{"flowId":"flow_trial_limit","deliveryTarget":"trial-limit@materialguardian.test","expiresAt":"2026-04-02T18:30:00.000Z","demoCode":"246810"}',
            200,
            headers: {'content-type': 'application/json'},
          );
        }
        if (request.url.path.endsWith('/auth/complete')) {
          return http.Response(
            '{"status":"authenticated","accessToken":"access-trial-limit","refreshToken":"refresh-trial-limit","user":{"id":"user_trial_limit","email":"trial-limit@materialguardian.test","displayName":"Trial Limit User","status":"active","createdAt":"2026-04-02T12:00:00.000Z","lastLoginAt":"2026-04-02T12:05:00.000Z"},"memberships":[],"activeEntitlement":{"productCode":"material_guardian","planCode":null,"accessState":"trial","seatAvailability":"not_applicable","subscriptionState":"trial","trialRemaining":6,"organizationId":null,"startsAt":"2026-04-02T12:00:00.000Z","endsAt":null},"session":{"id":"session_trial_limit","deviceLabel":"Kevin PowerShell","platform":"web","status":"active","issuedAt":"2026-04-02T12:05:00.000Z","lastSeenAt":"2026-04-02T12:05:00.000Z","revokedAt":null}}',
            200,
            headers: {'content-type': 'application/json'},
          );
        }
        if (request.url.path.endsWith('/me')) {
          return http.Response(
            '{"user":{"id":"user_trial_limit","email":"trial-limit@materialguardian.test","displayName":"Trial Limit User","status":"active","createdAt":"2026-04-02T12:00:00.000Z","lastLoginAt":"2026-04-02T12:05:00.000Z"},"memberships":[],"currentSeatAssignment":{"organizationId":null,"status":"not_applicable"},"trialState":{"productCode":"material_guardian","jobsAllowed":6,"jobsUsed":$jobsUsed,"jobsRemaining":${(6 - jobsUsed).clamp(0, 6)},"status":"${jobsUsed >= 6 ? 'exhausted' : 'active'}"},"activeEntitlement":{"productCode":"material_guardian","planCode":null,"accessState":"${jobsUsed >= 6 ? 'locked' : 'trial'}","seatAvailability":"not_applicable","subscriptionState":"${jobsUsed >= 6 ? 'inactive' : 'trial'}","trialRemaining":${(6 - jobsUsed).clamp(0, 6)},"organizationId":null,"startsAt":"2026-04-02T12:00:00.000Z","endsAt":null},"activeSession":{"id":"session_trial_limit","deviceLabel":"Kevin PowerShell","platform":"web","status":"active","issuedAt":"2026-04-02T12:05:00.000Z","lastSeenAt":"2026-04-02T12:05:00.000Z","revokedAt":null}}',
            200,
            headers: {'content-type': 'application/json'},
          );
        }
        if (request.url.path.endsWith('/entitlements/current')) {
          return http.Response(
            '{"productCode":"material_guardian","planCode":null,"accessState":"${jobsUsed >= 6 ? 'locked' : 'trial'}","seatAvailability":"not_applicable","subscriptionState":"${jobsUsed >= 6 ? 'inactive' : 'trial'}","trialRemaining":${(6 - jobsUsed).clamp(0, 6)},"organizationId":null,"startsAt":"2026-04-02T12:00:00.000Z","endsAt":null}',
            200,
            headers: {'content-type': 'application/json'},
          );
        }
        if (request.url.path.endsWith('/trials/consume-job')) {
          if (jobsUsed >= 6) {
            return http.Response(
              '{"message":"Trial job limit has already been reached."}',
              409,
              headers: {'content-type': 'application/json'},
            );
          }
          jobsUsed += 1;
          return http.Response(
            '{"trialState":{"productCode":"material_guardian","jobsAllowed":6,"jobsUsed":$jobsUsed,"jobsRemaining":${6 - jobsUsed},"status":"${jobsUsed >= 6 ? 'exhausted' : 'active'}"},"activeEntitlement":{"productCode":"material_guardian","planCode":null,"accessState":"${jobsUsed >= 6 ? 'locked' : 'trial'}","seatAvailability":"not_applicable","subscriptionState":"${jobsUsed >= 6 ? 'inactive' : 'trial'}","trialRemaining":${(6 - jobsUsed).clamp(0, 6)},"organizationId":null,"startsAt":"2026-04-02T12:00:00.000Z","endsAt":null}}',
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
    final initialJobCount = appState.jobs.length;
    await appState.startBackendSignIn(
      email: 'trial-limit@materialguardian.test',
      displayName: 'Trial Limit User',
    );
    await appState.completeBackendSignIn(code: '246810');

    for (var index = 1; index <= 6; index++) {
      await appState.saveJob(
        jobNumber: 'LIMIT-$index',
        description: 'Trial job $index',
        notes: '',
      );
    }

    await expectLater(
      () => appState.saveJob(
        jobNumber: 'LIMIT-7',
        description: 'Trial job 7',
        notes: '',
      ),
      throwsA(isA<BackendApiException>()),
    );
    expect(appState.jobs.length, initialJobCount + 6);
    expect(appState.effectiveBackendEntitlement?.accessState, 'locked');
    expect(appState.effectiveBackendEntitlement?.trialRemaining, 0);
  });

  test('local unknown-access state still stops at six total jobs', () async {
    final appState = MaterialGuardianAppState.seeded();
    final initialJobCount = appState.jobs.length;

    for (var index = initialJobCount + 1; index <= 6; index++) {
      await appState.saveJob(
        jobNumber: 'LOCAL-$index',
        description: 'Local trial job $index',
        notes: '',
      );
    }

    await expectLater(
      () => appState.saveJob(
        jobNumber: 'LOCAL-7',
        description: 'Local trial job 7',
        notes: '',
      ),
      throwsA(isA<BackendApiException>()),
    );
    expect(appState.jobs.length, 6);
  });

  test('local fallback trial count does not reopen after deleting a job', () async {
    final appState = MaterialGuardianAppState.seeded();
    final initialJobCount = appState.jobs.length;

    for (var index = initialJobCount + 1; index <= 6; index++) {
      await appState.saveJob(
        jobNumber: 'LOCAL-$index',
        description: 'Local trial job $index',
        notes: '',
      );
    }

    await appState.deleteJob('job-1001');

    await expectLater(
      () => appState.saveJob(
        jobNumber: 'LOCAL-REOPEN',
        description: 'Should stay blocked after delete',
        notes: '',
      ),
      throwsA(isA<BackendApiException>()),
    );
  });
}

Future<String> _writeProbeImage(
  Directory directory,
  String filename, {
  required img.ColorRgb8 fillColor,
  required img.ColorRgb8 accentColor,
}) async {
  final canvas = img.Image(width: 960, height: 640);
  img.fill(canvas, color: fillColor);
  img.fillRect(canvas, x1: 80, y1: 90, x2: 880, y2: 170, color: accentColor);
  img.fillRect(
    canvas,
    x1: 110,
    y1: 220,
    x2: 850,
    y2: 540,
    color: img.ColorRgb8(
      ((fillColor.r + accentColor.r) / 2).round(),
      ((fillColor.g + accentColor.g) / 2).round(),
      ((fillColor.b + accentColor.b) / 2).round(),
    ),
  );
  final file = File(p.join(directory.path, filename));
  final encoded = filename.toLowerCase().endsWith('.png')
      ? img.encodePng(canvas)
      : img.encodeJpg(canvas, quality: 90);
  await file.writeAsBytes(encoded, flush: true);
  return file.path;
}

Future<String> _writeProbePdfWithPreview(
  Directory directory,
  String baseName,
) async {
  final pdfFile = File(p.join(directory.path, '$baseName.pdf'));
  await pdfFile.writeAsBytes(const <int>[
    37,
    80,
    68,
    70,
    45,
    49,
    46,
    52,
  ], flush: true);
  final previewImage = img.Image(width: 700, height: 900);
  img.fill(previewImage, color: img.ColorRgb8(250, 250, 250));
  img.fillRect(
    previewImage,
    x1: 70,
    y1: 80,
    x2: 630,
    y2: 150,
    color: img.ColorRgb8(60, 60, 60),
  );
  img.fillRect(
    previewImage,
    x1: 95,
    y1: 220,
    x2: 605,
    y2: 760,
    color: img.ColorRgb8(216, 216, 216),
  );
  await File(
    p.join(directory.path, '${baseName}_preview.jpg'),
  ).writeAsBytes(img.encodeJpg(previewImage, quality: 90), flush: true);
  return pdfFile.path;
}
