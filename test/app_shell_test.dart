import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_guardian_mobile/app/material_guardian_app.dart';
import 'package:material_guardian_mobile/app/material_guardian_state.dart';

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

  tearDownAll(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_pathProviderChannel, null);
  });

  testWidgets('jobs shell opens drafts view', (tester) async {
    await tester.pumpWidget(
      MaterialGuardianApp(appState: MaterialGuardianAppState.seeded()),
    );

    expect(find.text('Material Guardian'), findsOneWidget);
    expect(find.text('Active Jobs'), findsOneWidget);

    final draftsButton = find.widgetWithText(TextButton, 'Drafts (1)');
    await tester.ensureVisible(draftsButton);
    await tester.tap(draftsButton);
    await tester.pumpAndSettle();

    expect(find.text('Material Drafts'), findsOneWidget);
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
}
