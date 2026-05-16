import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:realunit_wallet/screens/legal/steps/legal_disclaimer_step.dart';

import '../../../helper/helper.dart';

void main() {
  group('$LegalDisclaimerStep', () {
    testWidgets('step 0: renders the legalDisclaimerTitle / legalDisclaimerText pair',
        (tester) async {
      tester.view.physicalSize = const Size(1200, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      await tester.pumpApp(const LegalDisclaimerStep(step: 0));

      // Both lines render; just count that we got two Text widgets (the
      // i18n strings are i18n-deterministic but their contents change with
      // locale, so we only pin the structure).
      expect(find.byType(Text), findsNWidgets(2));
    });

    testWidgets('step 1: renders the *Title2 / *Text2 pair', (tester) async {
      tester.view.physicalSize = const Size(1200, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      await tester.pumpApp(const LegalDisclaimerStep(step: 1));

      expect(find.byType(Text), findsNWidgets(2));
    });

    testWidgets('step 0 vs step 1 produce different titles', (tester) async {
      tester.view.physicalSize = const Size(1200, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      await tester.pumpApp(const LegalDisclaimerStep(step: 0));
      final firstTitle = tester.widgetList<Text>(find.byType(Text)).first.data;

      await tester.pumpApp(const LegalDisclaimerStep(step: 1));
      final secondTitle = tester.widgetList<Text>(find.byType(Text)).first.data;

      expect(firstTitle, isNotNull);
      expect(secondTitle, isNotNull);
      expect(firstTitle, isNot(secondTitle));
    });
  });
}
