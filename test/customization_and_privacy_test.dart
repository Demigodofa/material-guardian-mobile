import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_guardian_mobile/screens/privacy_policy_screen.dart';
import 'package:material_guardian_mobile/widgets/signature_capture_dialog.dart';

void main() {
  testWidgets(
    'signature dialog accepts drawing input on a narrow phone viewport',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(320, 640));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return Center(
                  child: FilledButton(
                    onPressed: () {
                      showSignatureCaptureDialog(
                        context,
                        title: 'Capture default QC inspector signature',
                      );
                    },
                    child: const Text('Open'),
                  ),
                );
              },
            ),
          ),
        ),
      );
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      final canvas = find.byKey(const ValueKey('signature-canvas'));
      expect(canvas, findsOneWidget);
      expect(
        find.widgetWithText(FilledButton, 'Save Signature'),
        findsOneWidget,
      );
      expect(find.widgetWithText(TextButton, 'Cancel'), findsOneWidget);
      expect(tester.takeException(), isNull);

      final start = tester.getTopLeft(canvas) + const Offset(36, 36);
      final gesture = await tester.startGesture(start);
      await tester.pump();
      await gesture.moveBy(const Offset(90, 24));
      await tester.pump();
      await gesture.up();
      await tester.pumpAndSettle();

      final clearButton = tester.widget<TextButton>(
        find.widgetWithText(TextButton, 'Clear'),
      );
      expect(clearButton.onPressed, isNotNull);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('privacy policy reflects the shipped Android behavior', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: PrivacyPolicyScreen()));
    await tester.pumpAndSettle();

    expect(find.text('Overview'), findsOneWidget);
    expect(find.textContaining('Welders Helper'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('Data handled by the service'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    expect(find.text('Data handled by the service'), findsOneWidget);
    expect(find.textContaining('Google Play'), findsWidgets);

    await tester.scrollUntilVisible(
      find.text('Security'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    expect(find.text('Security'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('Retention and deletion'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    expect(find.text('Retention and deletion'), findsOneWidget);
    expect(find.textContaining('delete-account page'), findsOneWidget);
  });
}
