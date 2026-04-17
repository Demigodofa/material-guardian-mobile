import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_guardian_mobile/app/material_guardian_state.dart';
import 'package:material_guardian_mobile/data/material_guardian_snapshot_store.dart';

const MethodChannel _pathProviderChannel = MethodChannel(
  'plugins.flutter.io/path_provider',
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory testDirectory;

  setUpAll(() async {
    testDirectory = Directory(
      '${Directory.systemTemp.path}/material_guardian_mobile_snapshot_test',
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

  tearDown(() async {
    if (await testDirectory.exists()) {
      await testDirectory.delete(recursive: true);
    }
    await testDirectory.create(recursive: true);
  });

  tearDownAll(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_pathProviderChannel, null);
  });

  test(
    'snapshot store falls back to backup when the primary file is corrupt',
    () async {
      final store = MaterialGuardianSnapshotStore();
      final seeded = MaterialGuardianAppState.seeded();
      final snapshot = MaterialGuardianSnapshot(
        jobs: seeded.jobs,
        drafts: seeded.drafts,
        localTrialJobsConsumed: seeded.jobs.length,
      );

      await store.save(snapshot);

      final primaryFile = File(
        '${testDirectory.path}/material_guardian_snapshot.json',
      );
      await primaryFile.writeAsString('{corrupt json', flush: true);

      final loaded = await store.load();

      expect(loaded.jobs.length, snapshot.jobs.length);
      expect(loaded.drafts.length, snapshot.drafts.length);
      expect(loaded.localTrialJobsConsumed, snapshot.localTrialJobsConsumed);
    },
  );

  test('snapshot store keeps a current backup after saving', () async {
    final store = MaterialGuardianSnapshotStore();
    final seeded = MaterialGuardianAppState.seeded();
    final snapshot = MaterialGuardianSnapshot(
      jobs: seeded.jobs,
      drafts: seeded.drafts,
      localTrialJobsConsumed: seeded.jobs.length,
    );

    await store.save(snapshot);

    final backupFile = File(
      '${testDirectory.path}/material_guardian_snapshot.backup.json',
    );

    expect(await backupFile.exists(), isTrue);
    expect(await backupFile.readAsString(), contains('"jobs"'));
    expect(await backupFile.readAsString(), contains('"drafts"'));
  });
}
