import 'package:alchemist/alchemist.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:realunit_wallet/screens/welcome/welcome_page.dart';
import 'package:realunit_wallet/styles/themes.dart';

import '../../../helper/helper.dart';

void main() {

  group('$WelcomePage', () {
    goldenTest(
      'on iOS',
      fileName: 'welcome_page_ios',
      constraints: phoneConstraints,
      builder: () => wrapForGolden(
        const WelcomePage(),
        theme: realUnitTheme.copyWith(platform: TargetPlatform.iOS),
      ),
    );

    goldenTest(
      'on Android',
      fileName: 'welcome_page_android',
      constraints: phoneConstraints,
      builder: () => wrapForGolden(
        const WelcomePage(),
        theme: realUnitTheme.copyWith(platform: TargetPlatform.android),
      ),
    );
  });
}
