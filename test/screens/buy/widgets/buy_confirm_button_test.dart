import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:realunit_wallet/generated/i18n.dart';
import 'package:realunit_wallet/packages/service/dfx/models/payment/buy/buy_payment_info.dart';
import 'package:realunit_wallet/screens/buy/buy_payment_details_page.dart';
import 'package:realunit_wallet/screens/buy/cubits/buy_confirm/buy_confirm_cubit.dart';
import 'package:realunit_wallet/screens/buy/widgets/buy_confirm_button.dart';
import 'package:realunit_wallet/setup/routing/routes/app_routes.dart';
import 'package:realunit_wallet/styles/currency.dart';

class _MockBuyConfirmCubit extends MockCubit<BuyConfirmState>
    implements BuyConfirmCubit {}

const _info = BuyPaymentInfo(
  id: 42,
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

void main() {
  late _MockBuyConfirmCubit cubit;

  setUp(() {
    cubit = _MockBuyConfirmCubit();
    when(() => cubit.state).thenReturn(const BuyConfirmInitial());
    when(() => cubit.confirmPayment(any())).thenAnswer((_) async {});
  });

  Widget host({GoRouter? router}) {
    final view = BlocProvider<BuyConfirmCubit>.value(
      value: cubit,
      child: const BuyConfirmButtonView(buyPaymentInfo: _info, amount: '100'),
    );
    if (router != null) {
      return MaterialApp.router(
        routerConfig: router,
        locale: const Locale('de'),
        localizationsDelegates: [
          S.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
        ],
        supportedLocales: S.delegate.supportedLocales,
      );
    }
    return MaterialApp(
      locale: const Locale('de'),
      localizationsDelegates: [
        S.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ],
      supportedLocales: S.delegate.supportedLocales,
      home: Scaffold(body: view),
    );
  }

  group('$BuyConfirmButtonView', () {
    testWidgets('renders the binding-buy label', (tester) async {
      await tester.pumpWidget(host());

      expect(find.text(S.current.buyPaymentConfirm), findsOneWidget);
    });

    testWidgets('tapping confirms the payment for the quote id', (tester) async {
      await tester.pumpWidget(host());

      await tester.tap(find.text(S.current.buyPaymentConfirm));
      await tester.pump();

      verify(() => cubit.confirmPayment(42)).called(1);
    });

    testWidgets('shows a loading indicator while confirming', (tester) async {
      when(() => cubit.state).thenReturn(const BuyConfirmLoading());

      await tester.pumpWidget(host());

      expect(find.byType(CupertinoActivityIndicator), findsOneWidget);
    });

    testWidgets('shows a snackbar with the generic error on failure',
        (tester) async {
      whenListen(
        cubit,
        Stream.fromIterable([
          const BuyConfirmFailure(BuyConfirmError.unknown),
        ]),
        initialState: const BuyConfirmInitial(),
      );

      await tester.pumpWidget(host());
      await tester.pump();

      expect(find.text(S.current.buyPaymentConfirmFailed), findsOneWidget);
    });

    testWidgets('shows the aktionariat-specific error on a 503 failure',
        (tester) async {
      whenListen(
        cubit,
        Stream.fromIterable([
          const BuyConfirmFailure(BuyConfirmError.aktionariat),
        ]),
        initialState: const BuyConfirmInitial(),
      );

      await tester.pumpWidget(host());
      await tester.pump();

      expect(find.text(S.current.buyPaymentConfirmFailedAktionariat), findsOneWidget);
    });

    testWidgets('navigates to the payment details page on success',
        (tester) async {
      whenListen(
        cubit,
        Stream.fromIterable([
          const BuyConfirmSuccess('REF-1'),
        ]),
        initialState: const BuyConfirmInitial(),
      );

      final router = GoRouter(
        initialLocation: '/buy',
        routes: [
          GoRoute(
            name: AppRoutes.buy,
            path: '/buy',
            builder: (_, _) => Scaffold(
              body: BlocProvider<BuyConfirmCubit>.value(
                value: cubit,
                child: const BuyConfirmButtonView(
                  buyPaymentInfo: _info,
                  amount: '100',
                ),
              ),
            ),
          ),
          GoRoute(
            name: AppRoutes.buyPaymentDetails,
            path: '/buyPaymentDetails',
            builder: (_, state) => BuyPaymentDetailsPage(
              params: state.extra as BuyPaymentDetailsParams,
            ),
          ),
        ],
      );

      await tester.pumpWidget(host(router: router));
      await tester.pumpAndSettle();

      expect(find.text(S.current.buyPaymentDetailsTitle), findsOneWidget);
      expect(find.text(S.current.buyPaymentInstructionEmail), findsOneWidget);
    });
  });
}
