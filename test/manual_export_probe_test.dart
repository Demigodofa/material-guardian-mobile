import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

import 'package:material_guardian_mobile/app/material_guardian_state.dart';

const MethodChannel _pathProviderChannel = MethodChannel(
  'plugins.flutter.io/path_provider',
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final manualProbeEnabled =
      Platform.environment['MG_RUN_MANUAL_EXPORT_PROBE'] == '1';

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
  });

  tearDownAll(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_pathProviderChannel, null);
  });

  test(
    'manual export probe copies a seeded packet to Desktop',
    () async {
      final appState = MaterialGuardianAppState.seededSignedIn();
      final exportResult = await appState.exportJob('job-1001');
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

      for (final packetPath in exportResult.packetPathsByMaterialId.values) {
        final packetFile = File(packetPath);
        await packetFile.copy(
          p.join(targetDirectory.path, p.basename(packetFile.path)),
        );
      }

      final zipFile = File(exportResult.zipPath);
      await zipFile.copy(p.join(targetDirectory.path, p.basename(zipFile.path)));

      final infoFile = File(
        p.join(exportResult.exportRootPath, 'export_info.txt'),
      );
      if (await infoFile.exists()) {
        await infoFile.copy(
          p.join(targetDirectory.path, p.basename(infoFile.path)),
        );
      }

      // ignore: avoid_print
      print('manual_export_probe=${targetDirectory.path}');
      expect(targetDirectory.listSync().isNotEmpty, isTrue);
    },
    skip: !manualProbeEnabled,
  );
}
