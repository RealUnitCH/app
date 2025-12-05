import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:realunit_wallet/generated/i18n.dart';
import 'package:realunit_wallet/main.dart' as app;
import 'package:realunit_wallet/screens/dashboard/dashboard_page.dart';
import 'package:realunit_wallet/screens/welcome/widgets/welcome_card.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets("shows $DashboardPage after user completed onboarding", (WidgetTester tester) async {
    await app.main();
    await tester.pumpAndSettle();

    final softwareWalletCardFinder = find.byWidgetPredicate(
      (widget) => widget is WelcomeCard && widget.title == S.current.software_wallet,
    );
    await tester.tap(softwareWalletCardFinder);
    await tester.pumpAndSettle();

    final createNewWalletCardFinder = find.byWidgetPredicate(
      (widget) => widget is WelcomeCard && widget.title == S.current.create_wallet,
    );
    await tester.tap(createNewWalletCardFinder);
    await tester.pumpAndSettle();

    final createWalletButtonFinder = find.text(S.current.create_wallet_confirm);
    await tester.tap(createWalletButtonFinder);
    await tester.pumpAndSettle();

    final checkbox = find.byType(Checkbox);
    await tester.tap(checkbox);
    await tester.pumpAndSettle();

    final completeOnboardingButtonFinder = find.text(S.current.next);
    await tester.tap(completeOnboardingButtonFinder);
    await tester.pumpAndSettle();

    expect(find.byType(DashboardPage), findsOne);
  });
}
