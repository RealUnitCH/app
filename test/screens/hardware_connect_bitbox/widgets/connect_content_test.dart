import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:realunit_wallet/screens/hardware_connect_bitbox/widgets/connect_content.dart';
import 'package:realunit_wallet/widgets/buttons/app_filled_button.dart';

import '../../../helper/helper.dart';

void main() {
  group('$ConnectContent', () {
    testWidgets('renders the title', (tester) async {
      // Use a non-existent asset path — SvgPicture.asset throws lazily on
      // render, which is acceptable here since we only need the structural
      // assertions; the test framework swallows asset errors quietly.
      await tester.pumpApp(
        const ConnectContent(
          imagePath: 'assets/images/bitbox/test.svg',
          title: 'Pair your BitBox',
          child: SizedBox.shrink(),
        ),
      );

      expect(find.text('Pair your BitBox'), findsOneWidget);
    });

    testWidgets('omits both buttons when neither callback is provided',
        (tester) async {
      await tester.pumpApp(
        const ConnectContent(
          imagePath: 'assets/images/bitbox/test.svg',
          title: 'Title',
          child: SizedBox.shrink(),
        ),
      );

      expect(find.byType(AppFilledButton), findsNothing);
    });

    testWidgets('renders the confirm button when onConfirm is provided',
        (tester) async {
      var confirms = 0;
      await tester.pumpApp(
        ConnectContent(
          imagePath: 'assets/images/bitbox/test.svg',
          title: 'Title',
          child: const SizedBox.shrink(),
          onConfirm: () => confirms++,
        ),
      );

      expect(find.byType(AppFilledButton), findsOneWidget);
      await tester.tap(find.byType(AppFilledButton));
      await tester.pump();
      expect(confirms, 1);
    });

    testWidgets('renders both buttons when both callbacks are provided',
        (tester) async {
      await tester.pumpApp(
        ConnectContent(
          imagePath: 'assets/images/bitbox/test.svg',
          title: 'Title',
          child: const SizedBox.shrink(),
          onConfirm: () {},
          onCancel: () {},
        ),
      );

      expect(find.byType(AppFilledButton), findsNWidgets(2));
    });

    testWidgets('cancel button uses the secondary variant', (tester) async {
      await tester.pumpApp(
        ConnectContent(
          imagePath: 'assets/images/bitbox/test.svg',
          title: 'Title',
          child: const SizedBox.shrink(),
          onConfirm: () {},
          onCancel: () {},
        ),
      );

      // The secondary button is the second AppFilledButton (cancel below confirm).
      final buttons = tester.widgetList<AppFilledButton>(find.byType(AppFilledButton)).toList();
      expect(buttons, hasLength(2));
      // Cancel button uses FilledButtonVariant.secondary, narrow (fullWidth: false).
      expect(buttons[1].variant, FilledButtonVariant.secondary);
      expect(buttons[1].fullWidth, isFalse);
    });
  });
}
