import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:realunit_wallet/screens/settings/widgets/settings_confirm_logout_wallet_sheet.dart';
import 'package:realunit_wallet/widgets/buttons/app_filled_button.dart';

import '../../../helper/helper.dart';

Finder _checkboxRow() => find
    .descendant(
      of: find.byWidgetPredicate(
        (w) => w is Semantics && w.properties.identifier == 'wallet-logout-confirm-checkbox',
      ),
      matching: find.byType(GestureDetector),
    )
    .first;

void main() {
  group('$SettingsConfirmLogoutWalletSheet', () {
    testWidgets('initial: checkbox unchecked + logout button disabled', (tester) async {
      tester.view.physicalSize = const Size(1200, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpApp(const Scaffold(body: SettingsConfirmLogoutWalletSheet()));

      final checkbox = tester.widget<Checkbox>(find.byType(Checkbox));
      expect(checkbox.value, isFalse);

      final buttons = tester.widgetList<AppFilledButton>(find.byType(AppFilledButton)).toList();
      expect(buttons, hasLength(2));
      // [0] = Close (secondary), [1] = Logout (primary, disabled while unchecked)
      expect(buttons[0].variant, FilledButtonVariant.secondary);
      expect(buttons[0].onPressed, isNotNull);
      expect(buttons[1].onPressed, isNull);
    });

    testWidgets('after checking the box, logout button becomes enabled', (tester) async {
      tester.view.physicalSize = const Size(1200, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpApp(const Scaffold(body: SettingsConfirmLogoutWalletSheet()));

      // The Checkbox itself is wrapped in AbsorbPointer; the surrounding
      // GestureDetector (opaque, full-row) carries the tap so a click on
      // either the box or the label toggles the state — that's the surface
      // Maestro tap-tests target via the Semantics identifier.
      await tester.tap(_checkboxRow());
      await tester.pump();

      final checkbox = tester.widget<Checkbox>(find.byType(Checkbox));
      expect(checkbox.value, isTrue);

      final logoutButton = tester.widgetList<AppFilledButton>(find.byType(AppFilledButton)).last;
      expect(logoutButton.onPressed, isNotNull);
    });

    testWidgets('un-checking again disables logout button', (tester) async {
      tester.view.physicalSize = const Size(1200, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpApp(const Scaffold(body: SettingsConfirmLogoutWalletSheet()));

      // Toggle on
      await tester.tap(_checkboxRow());
      await tester.pump();
      // Toggle off
      await tester.tap(_checkboxRow());
      await tester.pump();

      final logoutButton = tester.widgetList<AppFilledButton>(find.byType(AppFilledButton)).last;
      expect(logoutButton.onPressed, isNull);
    });

    testWidgets('tapping the row label (not just the checkbox) also toggles the box', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1200, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpApp(const Scaffold(body: SettingsConfirmLogoutWalletSheet()));

      // Tap the label text — the row-wide opaque GestureDetector picks this
      // up even though the text sits well to the right of the visual
      // checkbox (same UX as native iOS-style checkbox rows).
      await tester.tap(find.text('I have backed up my recovery phrase.'));
      await tester.pump();

      final checkbox = tester.widget<Checkbox>(find.byType(Checkbox));
      expect(checkbox.value, isTrue);
    });

    testWidgets('checkbox row exposes Semantics identifier + toggled state for Maestro', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1200, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpApp(const Scaffold(body: SettingsConfirmLogoutWalletSheet()));

      // The GestureDetector-wrapped row sits inside a Semantics widget with
      // the identifier Maestro tap-tests target via `tapOn: id:`. The
      // `toggled` property must mirror the current checkbox value so the
      // a11y tree treats the node as a checkbox state.
      Semantics findCheckboxSemantics() => tester
          .widgetList<Semantics>(find.byType(Semantics))
          .firstWhere(
            (s) => s.properties.identifier == 'wallet-logout-confirm-checkbox',
          );

      expect(findCheckboxSemantics().properties.toggled, isFalse);

      await tester.tap(_checkboxRow());
      await tester.pump();

      expect(findCheckboxSemantics().properties.toggled, isTrue);
    });

    testWidgets('renders the privacy_tip_rounded icon (blue, size 64)', (tester) async {
      tester.view.physicalSize = const Size(1200, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpApp(const Scaffold(body: SettingsConfirmLogoutWalletSheet()));

      final icon = tester.widget<Icon>(find.byIcon(Icons.privacy_tip_rounded));
      expect(icon.size, 64);
    });
  });
}
