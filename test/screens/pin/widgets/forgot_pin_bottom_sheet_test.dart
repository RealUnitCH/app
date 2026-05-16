import 'package:flutter_test/flutter_test.dart';
import 'package:realunit_wallet/screens/pin/widgets/forgot_pin_bottom_sheet.dart';
import 'package:realunit_wallet/widgets/buttons/app_filled_button.dart';

import '../../../helper/helper.dart';

void main() {
  group('$ForgotPinBottomSheet', () {
    testWidgets('renders exactly two AppFilledButtons (Close + Reset)',
        (tester) async {
      await tester.pumpApp(const ForgotPinBottomSheet());

      expect(find.byType(AppFilledButton), findsNWidgets(2));
    });

    testWidgets('the close button (first) uses the secondary variant',
        (tester) async {
      await tester.pumpApp(const ForgotPinBottomSheet());

      final buttons = tester.widgetList<AppFilledButton>(find.byType(AppFilledButton)).toList();
      expect(buttons[0].variant, FilledButtonVariant.secondary);
    });

    testWidgets('the reset button (second) uses the primary variant',
        (tester) async {
      await tester.pumpApp(const ForgotPinBottomSheet());

      final buttons = tester.widgetList<AppFilledButton>(find.byType(AppFilledButton)).toList();
      expect(buttons[1].variant, FilledButtonVariant.primary);
    });

    testWidgets('both buttons have non-null onPressed callbacks', (tester) async {
      await tester.pumpApp(const ForgotPinBottomSheet());

      final buttons = tester.widgetList<AppFilledButton>(find.byType(AppFilledButton)).toList();
      expect(buttons[0].onPressed, isNotNull);
      expect(buttons[1].onPressed, isNotNull);
    });
  });
}
