import 'package:alchemist/alchemist.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:realunit_wallet/screens/legal/legal_disclaimer_page.dart';

import '../../../helper/helper.dart';

void main() {
  group('$LegalDisclaimerPage', () {
    goldenTest(
      'default state, first step',
      fileName: 'legal_disclaimer_page_default',
      constraints: const BoxConstraints.tightFor(width: 390, height: 844),
      builder: () => wrapForGolden(const LegalDisclaimerPage()),
    );
  });
}
