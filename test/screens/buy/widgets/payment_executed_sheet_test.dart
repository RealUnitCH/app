import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:realunit_wallet/screens/buy/widgets/payment_executed_sheet.dart';
import 'package:realunit_wallet/styles/colors.dart';
import 'package:realunit_wallet/widgets/buttons/app_filled_button.dart';

import '../../../helper/helper.dart';

void main() {
  group('$PaymentExecutedSheet', () {
    testWidgets('renders the blue check_circle_rounded success icon (size 64)',
        (tester) async {
      tester.view.physicalSize = const Size(1200, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      await tester.pumpApp(const Scaffold(
        body: PaymentExecutedSheet(reference: 'ABC-123'),
      ));

      final icon = tester.widget<Icon>(find.byIcon(Icons.check_circle_rounded));
      expect(icon.color, RealUnitColors.realUnitBlue);
      expect(icon.size, 64);
    });

    testWidgets('renders the reference inline with the label', (tester) async {
      tester.view.physicalSize = const Size(1200, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      await tester.pumpApp(const Scaffold(
        body: PaymentExecutedSheet(reference: 'ABC-123'),
      ));

      // The label appends the reference via "<label>: <reference>".
      expect(find.textContaining('ABC-123'), findsOneWidget);
    });

    testWidgets('renders the copy icon next to the reference', (tester) async {
      tester.view.physicalSize = const Size(1200, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      await tester.pumpApp(const Scaffold(
        body: PaymentExecutedSheet(reference: 'ABC-123'),
      ));

      expect(find.byIcon(Icons.copy_outlined), findsOneWidget);
    });

    testWidgets('tapping the copy icon writes the reference to the clipboard',
        (tester) async {
      String? copied;
      // Intercept the clipboard platform channel.
      final messenger = TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
      messenger.setMockMethodCallHandler(SystemChannels.platform, (call) async {
        if (call.method == 'Clipboard.setData') {
          copied = (call.arguments as Map)['text'] as String?;
        }
        return null;
      });
      addTearDown(() {
        messenger.setMockMethodCallHandler(SystemChannels.platform, null);
      });

      tester.view.physicalSize = const Size(1200, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      await tester.pumpApp(const Scaffold(
        body: PaymentExecutedSheet(reference: 'ABC-123'),
      ));

      await tester.tap(find.byIcon(Icons.copy_outlined));
      await tester.pump();

      expect(copied, 'ABC-123');
    });

    testWidgets('renders a secondary, narrow close AppFilledButton', (tester) async {
      tester.view.physicalSize = const Size(1200, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      await tester.pumpApp(const Scaffold(
        body: PaymentExecutedSheet(reference: 'ABC-123'),
      ));

      final button = tester.widget<AppFilledButton>(find.byType(AppFilledButton));
      expect(button.variant, FilledButtonVariant.secondary);
      expect(button.fullWidth, isFalse);
    });
  });
}
