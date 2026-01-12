import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:realunit_wallet/generated/i18n.dart';
import 'package:realunit_wallet/screens/welcome/welcome_page.dart';
import 'package:realunit_wallet/screens/welcome/widgets/welcome_card.dart';
import 'package:realunit_wallet/styles/icons.dart';

import '../../helper/helper.dart';

void main() {
  group('$WelcomePage', () {
    testWidgets('renders initially correctly', (tester) async {
      await tester.pumpApp(const WelcomePage());

      expect(find.byType(Scaffold), findsOne);
      expect(find.byType(RealUnitIcon), findsOne);
      expect(find.text(S.current.realunit_wallet), findsOne);
      expect(find.text(S.current.realunit_wallet_subtitle), findsOneWidget);
      final visibleCards = find.byType(WelcomeCard).hitTestable();
      expect(visibleCards, findsNWidgets(2));
    });

    group('has $WelcomeCard', () {
      testWidgets('for Software Wallet', (tester) async {
        await tester.pumpApp(const WelcomePage());

        final welcomeCardFinder = find.byWidgetPredicate(
          (Widget widget) => widget is WelcomeCard && widget.title == S.current.software_wallet,
        );
        final welcomeCardWidget = tester.widget(welcomeCardFinder) as WelcomeCard;

        expect(welcomeCardWidget.trailing, isA<SvgPicture>());
      });

      testWidgets('for Hardware Wallet', (tester) async {
        await tester.pumpApp(const WelcomePage());

        final welcomeCardFinder = find.byWidgetPredicate(
          (Widget widget) => widget is WelcomeCard && widget.title == S.current.bitbox,
        );
        final welcomeCardWidget = tester.widget(welcomeCardFinder) as WelcomeCard;

        expect(welcomeCardWidget.trailing, isA<SvgPicture>());
      });
    });

    testWidgets('shows new cards when Software Wallet card tapped', (tester) async {
      await tester.pumpApp(const WelcomePage());

      expect(
        find
            .byWidgetPredicate(
              (Widget widget) => widget is WelcomeCard && widget.title == S.current.create_wallet,
            )
            .hitTestable(),
        findsNothing,
      );
      expect(
        find
            .byWidgetPredicate(
              (Widget widget) => widget is WelcomeCard && widget.title == S.current.restore_wallet,
            )
            .hitTestable(),
        findsNothing,
      );

      final welcomeCardFinder = find.byWidgetPredicate(
        (Widget widget) => widget is WelcomeCard && widget.title == S.current.software_wallet,
      );

      await tester.tap(welcomeCardFinder);
      await tester.pumpAndSettle();

      final visibleCards = find.byType(WelcomeCard).hitTestable();
      expect(visibleCards, findsNWidgets(2));
      expect(
        find
            .byWidgetPredicate(
              (Widget widget) => widget is WelcomeCard && widget.title == S.current.create_wallet,
            )
            .hitTestable(),
        findsOne,
      );
      expect(
        find
            .byWidgetPredicate(
              (Widget widget) => widget is WelcomeCard && widget.title == S.current.restore_wallet,
            )
            .hitTestable(),
        findsOne,
      );
    });
  });
}
