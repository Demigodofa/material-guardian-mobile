import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:material_guardian_mobile/app/material_guardian_state.dart';
import 'package:material_guardian_mobile/screens/customization_screen.dart';
import 'package:material_guardian_mobile/screens/material_form_screen.dart';
import 'package:material_guardian_mobile/services/storage_utils.dart';
import 'package:shared_preferences/shared_preferences.dart';

const MethodChannel _pathProviderChannel = MethodChannel(
  'plugins.flutter.io/path_provider',
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    final testDirectory = Directory(
      '${Directory.systemTemp.path}/material_guardian_mobile_ios_qa',
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

  testWidgets(
    'material form stays stable across phone and tablet layouts and keeps dropdowns usable',
    (tester) async {
      final appState = MaterialGuardianAppState.seeded();

      Future<void> pumpForm(Size logicalSize, {double devicePixelRatio = 3}) async {
        _setDisplay(tester, logicalSize, devicePixelRatio: devicePixelRatio);
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
        expect(find.text('Material photos'), findsOneWidget);
        expect(tester.takeException(), isNull);
      }

      await pumpForm(const Size(393, 852));
      await pumpForm(const Size(852, 393));
      await pumpForm(const Size(1024, 1366), devicePixelRatio: 2);
      await pumpForm(const Size(1366, 1024), devicePixelRatio: 2);

      await tester.scrollUntilVisible(
        find.text('Product'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('Product||true')).first);
      await tester.pumpAndSettle();
      expect(find.text('Tube'), findsWidgets);
      await tester.tap(find.text('Tube').last);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'customization screen stays stable on phone and tablet layouts with saved assets',
    (tester) async {
      final appState = MaterialGuardianAppState.seededSignedIn();
      final logoPath = await _writePngAsset('company_logo');
      final signaturePath = await _writePngAsset('saved_signature');
      await appState.saveCustomization(
        appState.customization.copyWith(
          includeCompanyLogoOnReports: true,
          companyLogoPath: logoPath,
          hasSavedInspectorSignature: true,
          savedInspectorSignaturePath: signaturePath,
        ),
      );

      Future<void> pumpCustomization(
        Size logicalSize, {
        double devicePixelRatio = 3,
      }) async {
        _setDisplay(tester, logicalSize, devicePixelRatio: devicePixelRatio);
        await tester.pumpWidget(
          MaterialApp(home: CustomizationScreen(appState: appState)),
        );
        await tester.pumpAndSettle();
        await tester.scrollUntilVisible(
          find.text('Company logo'),
          200,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.pumpAndSettle();
        expect(find.text('Company logo'), findsOneWidget);
        expect(find.text('Saved QC inspector signature'), findsOneWidget);
        expect(find.textContaining('company_logo'), findsOneWidget);
        expect(find.textContaining('saved_signature'), findsOneWidget);
        expect(tester.takeException(), isNull);
      }

      await pumpCustomization(const Size(852, 393));
      await pumpCustomization(const Size(1024, 1366), devicePixelRatio: 2);
      await pumpCustomization(const Size(1366, 1024), devicePixelRatio: 2);
    },
  );

  test(
    'exporting with company logo and signatures present creates the packet bundle cleanly',
    () async {
      final appState = MaterialGuardianAppState.seeded();
      final logoPath = await _writePngAsset('export_logo');
      final inspectorSignaturePath = await _writePngAsset('inspector_signature');
      final managerSignaturePath = await _writePngAsset('manager_signature');

      await appState.saveCustomization(
        appState.customization.copyWith(
          includeCompanyLogoOnReports: true,
          companyLogoPath: logoPath,
          hasSavedInspectorSignature: true,
          savedInspectorSignaturePath: inspectorSignaturePath,
        ),
      );

      final editDraft = await appState.createEditDraft(
        jobId: 'job-1001',
        materialId: 'mat-001',
      );
      await appState.saveDraft(
        editDraft.copyWith(
          qcSignaturePath: inspectorSignaturePath,
          qcManagerSignaturePath: managerSignaturePath,
          signatureApplied: true,
        ),
      );
      await appState.completeDraft(appState.draftById(editDraft.id));

      final exportResult = await appState.exportJob('job-1001');

      expect(Directory(exportResult.exportRootPath).existsSync(), isTrue);
      expect(File(exportResult.zipPath).existsSync(), isTrue);
      expect(exportResult.packetPathsByMaterialId['mat-001'], isNotNull);
      expect(
        File(exportResult.packetPathsByMaterialId['mat-001']!).existsSync(),
        isTrue,
      );
    },
  );
}

void _setDisplay(
  WidgetTester tester,
  Size logicalSize, {
  required double devicePixelRatio,
}) {
  tester.view.devicePixelRatio = devicePixelRatio;
  tester.view.physicalSize = Size(
    logicalSize.width * devicePixelRatio,
    logicalSize.height * devicePixelRatio,
  );
  addTearDown(tester.view.reset);
}

Future<String> _writePngAsset(String baseName) async {
  final targetDirectory = await appSupportSubdirectory(['ios_qa_assets']);
  final image = img.Image(width: 8, height: 8);
  img.fill(image, color: img.ColorRgb8(245, 245, 245));
  image.setPixelRgb(1, 1, 200, 40, 40);
  image.setPixelRgb(6, 6, 40, 40, 200);
  return writeBytesToDirectory(
    bytes: Uint8List.fromList(img.encodePng(image)),
    targetDirectory: targetDirectory,
    targetBaseName: baseName,
  );
}
