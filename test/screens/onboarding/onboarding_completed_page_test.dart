import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:realunit_wallet/generated/i18n.dart';
import 'package:realunit_wallet/screens/onboarding/onboarding_completed_page.dart';

import '../../helper/helper.dart';

void main() {
  group('$OnboardingCompletedPage', () {
    testWidgets('renders initially correctly', (tester) async {
      await tester.pumpApp(OnboardingCompletedPage());

      expect(find.byType(Scaffold), findsOne);
      expect(find.byType(AppBar), findsOne);
      expect(find.byType(Image), findsOne);

      expect(find.text(S.current.onboarding_completed_title), findsOne);
      expect(find.text(S.current.onboarding_completed_subtitle), findsOneWidget);

      expect(find.byType(Checkbox), findsOne);
      expect(find.byType(FilledButton), findsOne);
    });

    testWidgets('initial state', (tester) async {
      await tester.pumpApp(OnboardingCompletedPage());

      expect((tester.widget(find.byType(Checkbox)) as Checkbox).value, false);
      expect((tester.widget(find.byType(FilledButton)) as FilledButton).enabled, false);
      expect((tester.widget(find.byType(FilledButton)) as FilledButton).onPressed, isNull);
    });

    testWidgets('state when terms agreed', (tester) async {
      await tester.pumpApp(OnboardingCompletedPage());

      await tester.tap(find.byType(Checkbox));
      await tester.pumpAndSettle();

      expect((tester.widget(find.byType(Checkbox)) as Checkbox).value, true);
      expect((tester.widget(find.byType(FilledButton)) as FilledButton).enabled, true);
      expect((tester.widget(find.byType(FilledButton)) as FilledButton).onPressed, isNotNull);
    });
  });
}
