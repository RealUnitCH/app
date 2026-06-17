import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:realunit_wallet/generated/i18n.dart';
import 'package:realunit_wallet/packages/service/dfx/models/payment/buy/buy_payment_info.dart';
import 'package:realunit_wallet/screens/buy/buy_payment_details_page.dart';
import 'package:realunit_wallet/screens/buy/widgets/payment_details_card.dart';
import 'package:realunit_wallet/setup/routing/routes/app_routes.dart';
import 'package:realunit_wallet/styles/currency.dart';

import '../../helper/helper.dart';

const _info = BuyPaymentInfo(
  id: 1,
  iban: 'CH00 0000 0000 0000 0000 0',
  bic: 'BICCBIC',
  name: 'RealUnit AG',
  street: 'Bahnhofstrasse',
  number: '1',
  zip: '8001',
  city: 'Zurich',
  country: 'Switzerland',
  currency: Currency.chf,
);

BuyPaymentDetailsParams _params({String reference = 'REF-1'}) =>
    BuyPaymentDetailsParams(
      buyPaymentInfo: _info,
      amount: '100',
      reference: reference,
    );

void main() {
  group('$BuyPaymentDetailsPage', () {
    testWidgets('renders title, instruction, purpose hint and the details card',
        (tester) async {
      await tester.pumpApp(BuyPaymentDetailsPage(params: _params()));

      expect(find.text(S.current.buyPaymentDetailsTitle), findsOneWidget);
      expect(find.text(S.current.buyPaymentInstructionEmail), findsOneWidget);
      expect(find.text(S.current.buyPaymentPurposeHint), findsOneWidget);
      expect(find.byType(PaymentDetailsCard), findsOneWidget);
    });

    testWidgets('renders the order reference when present', (tester) async {
      await tester.pumpApp(BuyPaymentDetailsPage(params: _params()));

      expect(
        find.text('${S.current.buyExecutedReference}: REF-1'),
        findsOneWidget,
      );
    });

    testWidgets('hides the reference row when reference is empty',
        (tester) async {
      await tester.pumpApp(
        BuyPaymentDetailsPage(params: _params(reference: '')),
      );

      expect(
        find.textContaining(S.current.buyExecutedReference),
        findsNothing,
      );
    });

    testWidgets('renders the back-to-main button', (tester) async {
      await tester.pumpApp(BuyPaymentDetailsPage(params: _params()));

      expect(find.text(S.current.buyBackToMain), findsOneWidget);
    });

    testWidgets('back-to-main button navigates to home', (tester) async {
      final router = GoRouter(
        initialLocation: '/buyPaymentDetails',
        routes: [
          GoRoute(
            name: AppRoutes.home,
            path: '/home',
            builder: (_, _) => const Scaffold(body: Text('HOME-AREA')),
          ),
          GoRoute(
            name: AppRoutes.buyPaymentDetails,
            path: '/buyPaymentDetails',
            builder: (_, _) => BuyPaymentDetailsPage(params: _params()),
          ),
        ],
      );

      await tester.pumpWidget(
        MaterialApp.router(
          routerConfig: router,
          locale: const Locale('de'),
          localizationsDelegates: [
            S.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
          ],
          supportedLocales: S.delegate.supportedLocales,
        ),
      );

      await tester.ensureVisible(find.text(S.current.buyBackToMain));
      await tester.tap(find.text(S.current.buyBackToMain));
      await tester.pumpAndSettle();

      expect(find.text('HOME-AREA'), findsOneWidget);
    });
  });
}
