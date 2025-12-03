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
      await tester.pumpApp(WelcomePage());

      expect(find.byType(Scaffold), findsOne);
      expect(find.byType(RealUnitIcon), findsOne);
      expect(find.text(S.current.realunit_wallet), findsOne);
      expect(find.text(S.current.realunit_wallet_subtitle), findsOneWidget);
      expect(find.byType(WelcomeCard), findsNWidgets(2));
    });

    group('has $WelcomeCard', () {
      testWidgets('for Software Wallet', (tester) async {
        await tester.pumpApp(WelcomePage());

        final welcomeCardFinder = find.byWidgetPredicate(
          (Widget widget) => widget is WelcomeCard && widget.title == S.current.software_wallet,
        );
        final welcomeCardWidget = tester.widget(welcomeCardFinder) as WelcomeCard;

        expect(welcomeCardWidget.trailing, isA<SvgPicture>());
        expect(welcomeCardWidget.actions.length, 2);
        expect(welcomeCardWidget.actions[0].title, S.current.create_wallet);
        expect(welcomeCardWidget.actions[1].title, S.current.restore_wallet);
      });

      testWidgets('for Hardware Wallet', (tester) async {
        await tester.pumpApp(WelcomePage());

        final welcomeCardFinder = find.byWidgetPredicate(
          (Widget widget) =>
              widget is WelcomeCard &&
              widget.title == '${S.current.bitbox}\n${S.current.hardware_wallet}',
        );
        final welcomeCardWidget = tester.widget(welcomeCardFinder) as WelcomeCard;

        expect(welcomeCardWidget.trailing, isA<SvgPicture>());
        expect(welcomeCardWidget.actions.length, 1);
        expect(welcomeCardWidget.actions[0].title, S.current.connect_with(S.current.bitbox));
      });
    });
  });
}
