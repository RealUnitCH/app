import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:realunit_wallet/screens/pin/widgets/enable_biometric_bottom_sheet.dart';

import '../../../helper/helper.dart';

void main() {
  const phoneConstraints = BoxConstraints.tightFor(width: 390, height: 844);

  // The sheet is presented via showModalBottomSheet from the PIN setup flow
  // once the user has confirmed their PIN. For the golden we render the sheet
  // content alone in a Scaffold's bottomSheet slot with a dark backdrop, in
  // the same pattern as settings_confirm_logout_wallet_sheet_golden_test.dart.
  // The handbook flow shows a dimmed PIN screen behind the sheet; this golden
  // does NOT reproduce that exact backdrop — the dark scrim is enough to
  // verify the sheet shape, header, and button layout.
  group('$EnableBiometricBottomSheet', () {
    goldenTest(
      'default state with activate and skip buttons',
      fileName: 'biometric_prompt_sheet_default',
      constraints: phoneConstraints,
      builder: () => wrapForGolden(
        const Scaffold(
          backgroundColor: Colors.black54,
          bottomSheet: EnableBiometricBottomSheet(),
        ),
      ),
    );
  });
}
