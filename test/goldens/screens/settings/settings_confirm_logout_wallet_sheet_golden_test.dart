import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:realunit_wallet/screens/settings/widgets/settings_confirm_logout_wallet_sheet.dart';

import '../../../helper/helper.dart';

void main() {
  const phoneConstraints = BoxConstraints.tightFor(width: 390, height: 844);

  // The sheet is presented via showModalBottomSheet from the Settings page.
  // For the golden we render the sheet content alone in a Scaffold's
  // bottomSheet slot — this matches the sheet's shape and clipping without
  // requiring a real Settings page with its full provider graph as backdrop.
  // The handbook flow keeps a greyed-out Settings page behind the sheet; this
  // golden does NOT reproduce that backdrop. If 1:1 backdrop fidelity is
  // needed for the handbook, render an actual Settings page underneath.
  group('$SettingsConfirmLogoutWalletSheet', () {
    goldenTest(
      'initial state with checkbox unchecked',
      fileName: 'settings_confirm_logout_wallet_sheet_default',
      constraints: phoneConstraints,
      builder: () => wrapForGolden(
        const Scaffold(
          backgroundColor: Colors.black54,
          bottomSheet: SettingsConfirmLogoutWalletSheet(),
        ),
      ),
    );
  });
}
