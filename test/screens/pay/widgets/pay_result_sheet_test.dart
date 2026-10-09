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
      expect(handle.constraints?.maxHeight, 5);
      expect(handle.constraints?.maxWidth, 36);

      await tester.tap(find.text('Close'));
      expect(closed, isTrue);
    });
  });
}
