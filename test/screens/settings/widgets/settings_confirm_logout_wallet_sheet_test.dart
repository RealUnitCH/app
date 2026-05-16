import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:realunit_wallet/screens/settings/widgets/settings_confirm_logout_wallet_sheet.dart';
import 'package:realunit_wallet/widgets/buttons/app_filled_button.dart';

import '../../../helper/helper.dart';

void main() {
  group('$SettingsConfirmLogoutWalletSheet', () {
    testWidgets('initial: checkbox unchecked + logout button disabled',
        (tester) async {
      tester.view.physicalSize = const Size(1200, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpApp(const Scaffold(body: SettingsConfirmLogoutWalletSheet()));

      final checkbox = tester.widget<Checkbox>(find.byType(Checkbox));
      expect(checkbox.value, isFalse);

      final buttons = tester
          .widgetList<AppFilledButton>(find.byType(AppFilledButton))
          .toList();
      expect(buttons, hasLength(2));
      // [0] = Close (secondary), [1] = Logout (primary, disabled while unchecked)
      expect(buttons[0].variant, FilledButtonVariant.secondary);
      expect(buttons[0].onPressed, isNotNull);
      expect(buttons[1].onPressed, isNull);
    });

    testWidgets('after checking the box, logout button becomes enabled',
        (tester) async {
      tester.view.physicalSize = const Size(1200, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpApp(const Scaffold(body: SettingsConfirmLogoutWalletSheet()));

      await tester.tap(find.byType(Checkbox));
      await tester.pump();

      final checkbox = tester.widget<Checkbox>(find.byType(Checkbox));
      expect(checkbox.value, isTrue);

      final logoutButton = tester
          .widgetList<AppFilledButton>(find.byType(AppFilledButton))
          .last;
      expect(logoutButton.onPressed, isNotNull);
    });

    testWidgets('un-checking again disables logout button', (tester) async {
      tester.view.physicalSize = const Size(1200, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpApp(const Scaffold(body: SettingsConfirmLogoutWalletSheet()));

      // Toggle on
      await tester.tap(find.byType(Checkbox));
      await tester.pump();
      // Toggle off
      await tester.tap(find.byType(Checkbox));
      await tester.pump();

      final logoutButton = tester
          .widgetList<AppFilledButton>(find.byType(AppFilledButton))
          .last;
      expect(logoutButton.onPressed, isNull);
    });

    testWidgets('renders the privacy_tip_rounded icon (blue, size 64)',
        (tester) async {
      tester.view.physicalSize = const Size(1200, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpApp(const Scaffold(body: SettingsConfirmLogoutWalletSheet()));

      final icon = tester.widget<Icon>(find.byIcon(Icons.privacy_tip_rounded));
      expect(icon.size, 64);
    });
  });
}
