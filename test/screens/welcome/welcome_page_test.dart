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
    group('on iOS', () {
      testWidgets(
        'renders initially correctly',
        variant: TargetPlatformVariant.only(TargetPlatform.iOS),
        (tester) async {
          await tester.pumpApp(const WelcomePage());

          expect(find.byType(Scaffold), findsOne);
          expect(find.byType(RealUnitIcon), findsOne);
          expect(find.text(S.current.realunitWallet), findsOne);
          expect(find.text(S.current.realunitWalletSubtitle), findsOneWidget);
          final visibleCards = find.byType(WelcomeCard).hitTestable();
          expect(visibleCards, findsNWidgets(3));
        },
      );

      group('has $WelcomeCard', () {
        testWidgets(
          'for Create Wallet',
          variant: TargetPlatformVariant.only(TargetPlatform.iOS),
          (tester) async {
            await tester.pumpApp(const WelcomePage());

            final welcomeCardFinder = find.byWidgetPredicate(
              (Widget widget) => widget is WelcomeCard && widget.title == S.current.createWallet,
            );
            final welcomeCardWidget = tester.widget(welcomeCardFinder) as WelcomeCard;

            expect(welcomeCardWidget.trailing, isA<SvgPicture>());
          },
        );

        testWidgets(
          'for Restore Wallet',
          variant: TargetPlatformVariant.only(TargetPlatform.iOS),
          (tester) async {
            await tester.pumpApp(const WelcomePage());

            final welcomeCardFinder = find.byWidgetPredicate(
              (Widget widget) => widget is WelcomeCard && widget.title == S.current.restoreWallet,
            );
            final welcomeCardWidget = tester.widget(welcomeCardFinder) as WelcomeCard;

            expect(welcomeCardWidget.trailing, isA<SvgPicture>());
          },
        );
      });
    });

    group('on Android', () {
      testWidgets(
        'renders initially correctly',
        variant: TargetPlatformVariant.only(TargetPlatform.android),
        (tester) async {
          await tester.pumpApp(const WelcomePage());

          expect(find.byType(Scaffold), findsOne);
          expect(find.byType(RealUnitIcon), findsOne);
          expect(find.text(S.current.realunitWallet), findsOne);
          expect(find.text(S.current.realunitWalletSubtitle), findsOneWidget);
          final visibleCards = find.byType(WelcomeCard).hitTestable();
          expect(visibleCards, findsNWidgets(2));
        },
      );

      group('has $WelcomeCard', () {
        testWidgets(
          'for Software Wallet',
          variant: TargetPlatformVariant.only(TargetPlatform.android),
          (tester) async {
            await tester.pumpApp(const WelcomePage());

            final welcomeCardFinder = find.byWidgetPredicate(
              (Widget widget) => widget is WelcomeCard && widget.title == S.current.softwareWallet,
            );
            final welcomeCardWidget = tester.widget(welcomeCardFinder) as WelcomeCard;

            expect(welcomeCardWidget.trailing, isA<SvgPicture>());
          },
        );

        testWidgets(
          'for Hardware Wallet',
          variant: TargetPlatformVariant.only(TargetPlatform.android),
          (tester) async {
            await tester.pumpApp(const WelcomePage());

            final welcomeCardFinder = find.byWidgetPredicate(
              (Widget widget) => widget is WelcomeCard && widget.title == S.current.bitbox,
            );
            final welcomeCardWidget = tester.widget(welcomeCardFinder) as WelcomeCard;

            expect(welcomeCardWidget.trailing, isA<SvgPicture>());
          },
        );
      });

      testWidgets(
        'shows new cards when Software Wallet card tapped',
        variant: TargetPlatformVariant.only(TargetPlatform.android),
        (tester) async {
          await tester.pumpApp(const WelcomePage());

          expect(
            find
                .byWidgetPredicate(
                  (Widget widget) => widget is WelcomeCard && widget.title == S.current.createWallet,
                )
                .hitTestable(),
            findsNothing,
          );
          expect(
            find
                .byWidgetPredicate(
                  (Widget widget) => widget is WelcomeCard && widget.title == S.current.restoreWallet,
                )
                .hitTestable(),
            findsNothing,
          );

          final welcomeCardFinder = find.byWidgetPredicate(
            (Widget widget) => widget is WelcomeCard && widget.title == S.current.softwareWallet,
          );

          await tester.tap(welcomeCardFinder);
          await tester.pumpAndSettle();

          final visibleCards = find.byType(WelcomeCard).hitTestable();
          expect(visibleCards, findsNWidgets(3));
          expect(
            find
                .byWidgetPredicate(
                  (Widget widget) => widget is WelcomeCard && widget.title == S.current.createWallet,
                )
                .hitTestable(),
            findsOne,
          );
          expect(
            find
                .byWidgetPredicate(
                  (Widget widget) => widget is WelcomeCard && widget.title == S.current.restoreWallet,
                )
                .hitTestable(),
            findsOne,
          );
        },
      );
    });
  });
}
