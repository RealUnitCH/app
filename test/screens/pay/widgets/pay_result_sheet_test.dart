import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:realunit_wallet/screens/pay/widgets/pay_result_sheet.dart';
import 'package:realunit_wallet/styles/colors.dart';
import 'package:realunit_wallet/widgets/buttons/app_filled_button.dart';

import '../../../helper/helper.dart';

void main() {
  group('$PayResultSheet', () {
    testWidgets('renders close-only chrome and close calls onClose', (tester) async {
      var closed = false;
      await tester.pumpApp(
        PayResultSheet(
          icon: Icons.check_circle_rounded,
          title: 'Paid',
          description: 'The payment went through.',
          closeLabel: 'Close',
          onClose: () => closed = true,
        ),
      );

      final icon = tester.widget<Icon>(find.byIcon(Icons.check_circle_rounded));
      expect(icon.color, RealUnitColors.realUnitBlue);
      expect(icon.size, 64);

      expect(find.byType(AppFilledButton), findsOne);
      final button = tester.widget<AppFilledButton>(find.byType(AppFilledButton));
      expect(button.variant, FilledButtonVariant.secondary);
      expect(button.fullWidth, isFalse);

      final handle = tester.widget<Container>(
        find.byWidgetPredicate((widget) {
          if (widget is! Container) {
            return false;
          }
          final decoration = widget.decoration;
          return decoration is BoxDecoration &&
              decoration.color == RealUnitColors.neutral300;
        }),
      );
      expect(handle.decoration, isA<BoxDecoration>());
      expect((handle.decoration! as BoxDecoration).color, RealUnitColors.neutral300);
      expect(handle.height, 5);
      expect(handle.width, 36);

      await tester.tap(find.text('Close'));
      expect(closed, isTrue);
    });

    testWidgets('renders retry primary action without calling onClose', (tester) async {
      var closed = false;
      var retried = false;
      await tester.pumpApp(
        PayResultSheet(
          icon: Icons.check_circle_rounded,
          title: 'Try again',
          description: 'Something went wrong.',
          closeLabel: 'Close',
          onClose: () => closed = true,
          primaryLabel: 'Retry',
          onPrimary: () => retried = true,
        ),
      );

      expect(find.byType(AppFilledButton), findsNWidgets(2));

      final closeButton = tester.widget<AppFilledButton>(
        find.widgetWithText(AppFilledButton, 'Close'),
      );
      expect(closeButton.variant, FilledButtonVariant.secondary);

      final retryButton = tester.widget<AppFilledButton>(
        find.widgetWithText(AppFilledButton, 'Retry'),
      );
      expect(retryButton.variant, FilledButtonVariant.primary);

      await tester.tap(find.text('Retry'));
      expect(retried, isTrue);
      expect(closed, isFalse);
    });
  });
}
