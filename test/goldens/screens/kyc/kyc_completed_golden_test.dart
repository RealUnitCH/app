import 'package:alchemist/alchemist.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:realunit_wallet/screens/kyc/subpages/kyc_completed_page.dart';

import '../../../helper/helper.dart';

void main() {
  const phoneConstraints = BoxConstraints.tightFor(width: 390, height: 844);

  group('$KycCompletedPage', () {
    goldenTest(
      'default state',
      fileName: 'kyc_completed_page_default',
      constraints: phoneConstraints,
      builder: () => wrapForGolden(const KycCompletedPage()),
    );
  });
}
