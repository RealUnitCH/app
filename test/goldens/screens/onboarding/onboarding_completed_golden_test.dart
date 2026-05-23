import 'package:alchemist/alchemist.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:realunit_wallet/screens/onboarding/onboarding_completed_page.dart';

import '../../../helper/helper.dart';

void main() {
  group('$OnboardingCompletedPage', () {
    goldenTest(
      'default state',
      fileName: 'onboarding_completed_page_default',
      constraints: const BoxConstraints.tightFor(width: 390, height: 844),
      builder: () => wrapForGolden(const OnboardingCompletedPage()),
    );
  });
}
