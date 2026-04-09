import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:path/path.dart' as p;

import 'package:material_guardian_mobile/app/material_guardian_state.dart';

const MethodChannel _pathProviderChannel = MethodChannel(
  'plugins.flutter.io/path_provider',
);
const MethodChannel _sharedPreferencesChannel = MethodChannel(
  'plugins.flutter.io/shared_preferences',
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final manualProbeEnabled =
      Platform.environment['MG_RUN_MANUAL_EXPORT_PROBE'] == '1';
  final sharedPreferencesState = <String, Object>{};

  setUpAll(() async {
    final testDirectory = Directory(
      '${Directory.systemTemp.path}/material_guardian_mobile_export_probe',
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

  test(
    'manual export probe copies full seeded export variants to Desktop',
    () async {
      final desktopRoot =
          Platform.environment['OneDrive'] ??
          Platform.environment['USERPROFILE'];
      expect(desktopRoot, isNotNull);

      final timestamp = DateTime.now()
          .toIso8601String()
          .replaceAll(':', '')
          .replaceAll('.', '')
          .replaceAll('-', '');
      final targetDirectory = Directory(
        p.join(
          desktopRoot!,
          'Desktop',
          'material_guardian_export_probe',
          timestamp,
        ),
      );
      await targetDirectory.create(recursive: true);

      final probeMediaDirectory = Directory(
        p.join(
          Directory.systemTemp.path,
          'material_guardian_mobile_export_probe_assets',
          timestamp,
        ),
      );
      await probeMediaDirectory.create(recursive: true);

      final customizedResult = await _runCustomizedExportProbe(
        probeMediaDirectory,
      );
      final plainResult = await _runPlainExportProbe(probeMediaDirectory);

      await _copyExportVariant(
        exportResult: customizedResult,
        targetDirectory: Directory(p.join(targetDirectory.path, 'customized')),
      );
      await _copyExportVariant(
        exportResult: plainResult,
        targetDirectory: Directory(p.join(targetDirectory.path, 'plain')),
      );

      final summaryFile = File(
        p.join(targetDirectory.path, 'probe_summary.txt'),
      );
      await summaryFile.writeAsString(
        [
          'Material Guardian manual export probe',
          'Desktop output: ${targetDirectory.path}',
          'Variants: customized, plain',
          'Customized packets: ${customizedResult.packetCount}',
          'Customized photos: ${customizedResult.photoCount}',
          'Customized scans: ${customizedResult.scanCount}',
          'Plain packets: ${plainResult.packetCount}',
          'Plain photos: ${plainResult.photoCount}',
          'Plain scans: ${plainResult.scanCount}',
        ].join('\n'),
        flush: true,
      );

      // ignore: avoid_print
      print('manual_export_probe=${targetDirectory.path}');
      expect(targetDirectory.listSync().isNotEmpty, isTrue);
    },
    skip: !manualProbeEnabled,
  );
}

Future<void> _copyExportVariant({
  required dynamic exportResult,
  required Directory targetDirectory,
}) async {
  await targetDirectory.create(recursive: true);
  await _copyDirectoryRecursive(
    Directory(exportResult.exportRootPath as String),
    Directory(p.join(targetDirectory.path, 'export_root')),
  );
  await File(exportResult.zipPath as String).copy(
    p.join(targetDirectory.path, 'bundle.zip'),
  );
}

Future<void> _copyDirectoryRecursive(Directory source, Directory destination) async {
  await destination.create(recursive: true);
  await for (final entity in source.list(recursive: false)) {
    final nextPath = p.join(destination.path, p.basename(entity.path));
    if (entity is Directory) {
      await _copyDirectoryRecursive(entity, Directory(nextPath));
    } else if (entity is File) {
      await entity.copy(nextPath);
    }
  }
}

Future<dynamic> _runCustomizedExportProbe(Directory probeMediaDirectory) async {
  final appState = MaterialGuardianAppState.seededSignedIn();
  final logoPath = await _writeProbeImage(
    probeMediaDirectory,
    'company_logo.png',
    fillColor: img.ColorRgb8(20, 70, 120),
    accentColor: img.ColorRgb8(250, 210, 80),
  );
  final inspectorSignaturePath = await _writeProbeImage(
    probeMediaDirectory,
    'qc_signature.png',
    fillColor: img.ColorRgb8(245, 245, 245),
    accentColor: img.ColorRgb8(25, 25, 25),
  );
  final managerSignaturePath = await _writeProbeImage(
    probeMediaDirectory,
    'manager_signature.png',
    fillColor: img.ColorRgb8(250, 250, 250),
    accentColor: img.ColorRgb8(120, 30, 30),
  );
  final photoOnePath = await _writeProbeImage(
    probeMediaDirectory,
    'arrival_photo_01.jpg',
    fillColor: img.ColorRgb8(214, 228, 240),
    accentColor: img.ColorRgb8(42, 78, 105),
  );
  final photoTwoPath = await _writeProbeImage(
    probeMediaDirectory,
    'arrival_photo_02.jpg',
    fillColor: img.ColorRgb8(228, 214, 240),
    accentColor: img.ColorRgb8(84, 42, 105),
  );
  final scanImagePath = await _writeProbeImage(
    probeMediaDirectory,
    'mtr_scan_image.jpg',
    fillColor: img.ColorRgb8(240, 238, 222),
    accentColor: img.ColorRgb8(132, 110, 35),
  );
  final scanPdfPath = await _writeProbePdfWithPreview(
    probeMediaDirectory,
    'mtr_scan_packet',
  );

  await appState.saveCustomization(
    appState.customization.copyWith(
      includeCompanyLogoOnReports: true,
      companyLogoPath: logoPath,
      hasSavedInspectorSignature: true,
      savedInspectorSignaturePath: inspectorSignaturePath,
      defaultQcInspectorName: 'Renée Weld',
      defaultQcManagerName: 'Jürgen Shop QA',
      surfaceFinishUnit: 'µin',
    ),
  );

  final editDraft = await appState.createEditDraft(
    jobId: 'job-1001',
    materialId: 'mat-001',
  );
  await appState.saveDraft(
    editDraft.copyWith(
      description: '2" gate valve – café test',
      vendor: 'Québec Valve Works',
      comments: 'Unicode probe – verify logo, signatures, and scan thumbnails.',
      qcInspectorName: 'Renée Weld',
      qcManagerName: 'Jürgen Shop QA',
      qcSignaturePath: inspectorSignaturePath,
      qcManagerSignaturePath: managerSignaturePath,
      photoPaths: [photoOnePath, photoTwoPath],
      scanPaths: [scanImagePath, scanPdfPath],
      surfaceFinish: '125 AARH',
      surfaceFinishReading: '118',
      surfaceFinishUnit: 'µin',
    ),
  );
  await appState.completeDraft(appState.draftById(editDraft.id));

  final exportResult = await appState.exportJob('job-1001');
  appState.dispose();
  return exportResult;
}

Future<dynamic> _runPlainExportProbe(Directory probeMediaDirectory) async {
  final appState = MaterialGuardianAppState.seededSignedIn();
  final photoPath = await _writeProbeImage(
    probeMediaDirectory,
    'plain_photo.jpg',
    fillColor: img.ColorRgb8(225, 225, 225),
    accentColor: img.ColorRgb8(70, 70, 70),
  );
  final scanPdfPath = await _writeProbePdfWithPreview(
    probeMediaDirectory,
    'plain_scan_packet',
  );

  await appState.saveCustomization(
    appState.customization.copyWith(
      includeCompanyLogoOnReports: false,
      companyLogoPath: '',
      hasSavedInspectorSignature: false,
      savedInspectorSignaturePath: '',
      defaultQcInspectorName: 'Plain Inspector',
      defaultQcManagerName: 'Plain Manager',
    ),
  );

  final editDraft = await appState.createEditDraft(
    jobId: 'job-1001',
    materialId: 'mat-001',
  );
  await appState.saveDraft(
    editDraft.copyWith(
      description: '2" gate valve plain export',
      vendor: 'Baseline Supply',
      comments: 'No logo, simpler media set, PDF preview still expected.',
      qcInspectorName: 'Plain Inspector',
      qcManagerName: 'Plain Manager',
      qcSignaturePath: '',
      qcManagerSignaturePath: '',
      photoPaths: [photoPath],
      scanPaths: [scanPdfPath],
      surfaceFinish: '',
      surfaceFinishReading: '',
      surfaceFinishUnit: 'u-in',
    ),
  );
  await appState.completeDraft(appState.draftById(editDraft.id));

  final exportResult = await appState.exportJob('job-1001');
  appState.dispose();
  return exportResult;
}

Future<String> _writeProbeImage(
  Directory directory,
  String filename, {
  required img.ColorRgb8 fillColor,
  required img.ColorRgb8 accentColor,
}) async {
  final canvas = img.Image(width: 960, height: 640);
  img.fill(canvas, color: fillColor);
  img.fillRect(
    canvas,
    x1: 80,
    y1: 90,
    x2: 880,
    y2: 170,
    color: accentColor,
  );
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
  await pdfFile.writeAsBytes(
    const <int>[37, 80, 68, 70, 45, 49, 46, 52],
    flush: true,
  );
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
  await File(p.join(directory.path, '${baseName}_preview.jpg')).writeAsBytes(
    img.encodeJpg(previewImage, quality: 90),
    flush: true,
  );
  return pdfFile.path;
}
