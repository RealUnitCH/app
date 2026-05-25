import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:realunit_wallet/screens/support/support_page.dart';

import '../../../helper/helper.dart';

void main() {
  group('$SupportPage', () {
    goldenTest(
      'default tiles',
      fileName: 'support_page_default',
      constraints: const BoxConstraints.tightFor(width: 390, height: 844),
      builder: () => wrapForGolden(const SupportPage()),
    );
  });
}
