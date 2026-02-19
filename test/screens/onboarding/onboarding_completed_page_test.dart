import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:realunit_wallet/generated/i18n.dart';
import 'package:realunit_wallet/screens/onboarding/onboarding_completed_page.dart';

import '../../helper/helper.dart';

void main() {
  group('$OnboardingCompletedPage', () {
    testWidgets('renders initially correctly', (tester) async {
      await tester.pumpApp(const OnboardingCompletedPage());

      expect(find.byType(Scaffold), findsOne);
      expect(find.byType(AppBar), findsOne);
      expect(find.byType(Image), findsOne);

      expect(find.text(S.current.onboardingCompletedTitle), findsOne);
      expect(find.text(S.current.onboardingCompletedSubtitle), findsOneWidget);

      expect(find.byType(FilledButton), findsOne);
    });

    testWidgets('continue button is enabled', (tester) async {
      await tester.pumpApp(const OnboardingCompletedPage());

      expect((tester.widget(find.byType(FilledButton)) as FilledButton).enabled, true);
      expect((tester.widget(find.byType(FilledButton)) as FilledButton).onPressed, isNotNull);
    });
  });
}
