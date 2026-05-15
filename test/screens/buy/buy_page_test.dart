import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:mocktail/mocktail.dart';
import 'package:realunit_wallet/generated/i18n.dart';
import 'package:realunit_wallet/packages/config/api_config.dart';
import 'package:realunit_wallet/packages/repository/cache_repository.dart';
import 'package:realunit_wallet/packages/service/app_store.dart';
import 'package:realunit_wallet/packages/service/dfx/dfx_brokerbot_service.dart';
import 'package:realunit_wallet/packages/service/dfx/dfx_price_service.dart';
import 'package:realunit_wallet/packages/service/dfx/models/payment/buy/buy_payment_info.dart';
import 'package:realunit_wallet/packages/service/dfx/models/payment/payment_info_error.dart';
import 'package:realunit_wallet/packages/service/dfx/real_unit_buy_payment_info_service.dart';
import 'package:realunit_wallet/packages/service/session_cache.dart';
import 'package:realunit_wallet/screens/buy/buy_page.dart';
import 'package:realunit_wallet/screens/buy/cubits/buy_converter/buy_converter_cubit.dart';
import 'package:realunit_wallet/screens/buy/cubits/buy_payment_info/buy_payment_info_cubit.dart';
import 'package:realunit_wallet/screens/buy/widgets/payment_action_required.dart';
import 'package:realunit_wallet/screens/buy/widgets/payment_converter.dart';
import 'package:realunit_wallet/screens/buy/widgets/payment_information.dart';
import 'package:realunit_wallet/screens/buy/widgets/payment_information_details.dart';
import 'package:realunit_wallet/styles/currency.dart';
import 'package:realunit_wallet/widgets/buttons/app_filled_button.dart';
import 'package:realunit_wallet/widgets/tab_selector.dart';

import '../../helper/helper.dart';

class MockBuyConverterCubit extends MockCubit<BuyConverterState> implements BuyConverterCubit {}

class MockBuyPaymentInfoCubit extends MockCubit<BuyPaymentInfoState>
    implements BuyPaymentInfoCubit {}

class MockDfxBrokerbotService extends Mock implements DfxBrokerbotService {}

class MockRealUnitBuyPaymentInfoService extends Mock implements RealUnitBuyPaymentInfoService {}

class MockDfxPriceService extends Mock implements DFXPriceService {}

class MockApiConfig extends Mock implements ApiConfig {}

class MockCacheRepository extends Mock implements CacheRepository {}

void main() {
  late BuyConverterCubit converterCubit;
  late BuyPaymentInfoCubit buyPaymentInfoCubit;

  setUp(() {
    converterCubit = MockBuyConverterCubit();
    buyPaymentInfoCubit = MockBuyPaymentInfoCubit();

    when(() => converterCubit.state).thenReturn(const BuyConverterState());
    when(() => buyPaymentInfoCubit.state).thenReturn(const BuyPaymentInfoInitial());
    when(
      () => buyPaymentInfoCubit.getPaymentInfo(
        amount: any(named: 'amount'),
        currency: any(named: 'currency'),
      ),
    ).thenAnswer((_) => Future.value());
  });

  void setupDependencyInjection() {
    final getIt = GetIt.instance;
    getIt.registerSingleton<AppStore>(
      AppStore(() => MockApiConfig(), SessionCache(MockCacheRepository())),
    );
    getIt.registerSingleton<DfxBrokerbotService>(MockDfxBrokerbotService());
    getIt.registerSingleton<RealUnitBuyPaymentInfoService>(MockRealUnitBuyPaymentInfoService());
    getIt.registerSingleton<DFXPriceService>(MockDfxPriceService());
  }

  setUpAll(() {
    registerFallbackValue(Currency.chf);
    setupDependencyInjection();
  });

  tearDownAll(() async => await GetIt.instance.reset());

  Widget buildSubject(Widget child) {
    return MultiBlocProvider(
      providers: [
        BlocProvider.value(value: converterCubit),
        BlocProvider.value(value: buyPaymentInfoCubit),
      ],
      child: const BuyView(),
    );
  }

  group('$BuyPage', () {
    testWidgets('renders $BuyView', (tester) async {
      await tester.pumpApp(const BuyPage());

      expect(find.byType(BuyView), findsOne);
    });
  });

  group('$BuyView', () {
    testWidgets('renders initially correctly', (tester) async {
      await tester.pumpApp(buildSubject(const BuyView()));

      expect(find.byType(PaymentConverter), findsOne);
      expect(find.byType(PaymentInformation), findsOne);
    });

    testWidgets('renders correctly when $BuyPaymentInfo is available', (tester) async {
      when(() => buyPaymentInfoCubit.state).thenReturn(
        const BuyPaymentInfoSuccess(
          BuyPaymentInfo(
            id: 1,
            iban: 'iban',
            bic: 'bic',
            name: 'name',
            street: 'street',
            number: 'number',
            zip: 'zip',
            city: 'city',
            country: 'country',
            currency: Currency.chf,
          ),
        ),
      );

      whenListen(
        converterCubit,
        Stream.fromIterable([
          const BuyConverterState(fiatText: '100', sharesText: '1.00', loading: true),
          const BuyConverterState(fiatText: '100', sharesText: '1.00', loading: false),
        ]),
        initialState: const BuyConverterState(fiatText: '100', sharesText: '1.00'),
      );

      await tester.pumpApp(buildSubject(const BuyView()));
      await tester.pumpAndSettle();

      expect(find.byType(PaymentConverter), findsOne);
      expect(find.byType(PaymentInformationDetails), findsOne);
    });

    testWidgets(
      'render correctly when $BuyPaymentInfo paymentRequest is not null',
      (tester) async {
        when(() => buyPaymentInfoCubit.state).thenReturn(
          const BuyPaymentInfoSuccess(
            BuyPaymentInfo(
              id: 1,
              iban: 'iban',
              bic: 'bic',
              name: 'name',
              street: 'street',
              number: 'number',
              zip: 'zip',
              city: 'city',
              country: 'country',
              currency: Currency.chf,
              paymentRequest: 'svgString',
            ),
          ),
        );

        whenListen(
          converterCubit,
          Stream.fromIterable([
            const BuyConverterState(fiatText: '100', sharesText: '1.00', loading: true),
            const BuyConverterState(fiatText: '100', sharesText: '1.00', loading: false),
          ]),
          initialState: const BuyConverterState(fiatText: '100', sharesText: '1.00'),
        );

        await tester.pumpApp(buildSubject(const BuyView()));
        await tester.pumpAndSettle();

        expect(find.byType(PaymentConverter), findsOne);
        expect(find.byType(PaymentInformationDetails), findsOne);
        expect(find.byType(TabSelector<PaymentInfoOptions>), findsOne);
      },
    );

    testWidgets('renders correctly when $BuyPaymentInfo is loading', (tester) async {
      when(() => buyPaymentInfoCubit.state).thenReturn(const BuyPaymentInfoLoading());

      await tester.pumpApp(buildSubject(const BuyView()));

      expect(find.byType(PaymentConverter), findsOne);
      expect(find.byType(CupertinoActivityIndicator), findsOne);
    });

    testWidgets('renders correctly when registration is required', (tester) async {
      when(() => buyPaymentInfoCubit.state).thenReturn(
        const BuyPaymentInfoFailure(PaymentInfoError.registrationRequired),
      );

      await tester.pumpApp(buildSubject(const BuyView()));

      expect(find.byType(PaymentActionRequired), findsOne);
      expect(find.byType(PaymentInformation), findsOne);
      expect(find.text(S.current.registrationRequired), findsOne);
      expect(
        find.byWidgetPredicate(
          (Widget widget) => widget is AppFilledButton && widget.onPressed != null,
        ),
        findsOne,
      );
    });

    testWidgets('renders correctly when kyc is required', (tester) async {
      when(() => buyPaymentInfoCubit.state).thenReturn(
        const BuyPaymentInfoFailure(PaymentInfoError.kycRequired),
      );

      await tester.pumpApp(buildSubject(const BuyView()));

      expect(find.byType(PaymentActionRequired), findsOne);
      expect(find.byType(PaymentInformation), findsOne);
      expect(find.text(S.current.identityCheckRequired), findsOne);
      expect(
        find.byWidgetPredicate(
          (Widget widget) => widget is AppFilledButton && widget.onPressed != null,
        ),
        findsOne,
      );
    });

    testWidgets('renders correctly when min amount is not met', (tester) async {
      final minAmount = 100.0;
      final currency = Currency.chf;

      when(() => buyPaymentInfoCubit.state).thenReturn(
        BuyPaymentInfoMinAmountNotMetFailure(
          PaymentInfoError.minAmountNotMet,
          minAmount: minAmount,
        ),
      );
      when(() => converterCubit.state).thenReturn(
        BuyConverterState(
          currency: currency,
        ),
      );

      await tester.pumpApp(buildSubject(const BuyView()));

      expect(find.byType(PaymentActionRequired), findsNothing);
      expect(find.byType(PaymentInformation), findsOne);
      expect(find.text(S.current.buyMinAmount('${minAmount.round()}', currency.code)), findsOne);
      expect(
        find.byWidgetPredicate(
          (Widget widget) => widget is AppFilledButton && widget.onPressed == null,
        ),
        findsOne,
      );
    });

    testWidgets('retries payment info when unknown error is shown', (tester) async {
      when(() => buyPaymentInfoCubit.state).thenReturn(
        const BuyPaymentInfoFailure(PaymentInfoError.unknown),
      );
      when(() => converterCubit.state).thenReturn(
        const BuyConverterState(currency: Currency.eur),
      );

      await tester.pumpApp(buildSubject(const BuyView()));

      expect(find.text(S.current.paymentInformationFailed), findsOne);
      expect(find.text(S.current.retry), findsOne);

      await tester.tap(find.text(S.current.retry));
      await tester.pump();

      verify(
        () => buyPaymentInfoCubit.getPaymentInfo(
          amount: '',
          currency: Currency.eur,
        ),
      ).called(1);
    });

    testWidgets('updates controllers when $BuyConverterState changes', (tester) async {
      whenListen(
        converterCubit,
        Stream.fromIterable([
          const BuyConverterState(fiatText: '5.00', sharesText: '0.10', loading: true),
          const BuyConverterState(fiatText: '5.00', sharesText: '0.50', loading: false),
        ]),
        initialState: const BuyConverterState(fiatText: '1.00', sharesText: '0.10'),
      );

      await tester.pumpApp(buildSubject(const BuyView()));
      await tester.pumpAndSettle();

      final amountField = find.byType(TextField).first;
      final resultField = find.byType(TextField).last;

      TextField amount = tester.widget(amountField);
      TextField result = tester.widget(resultField);

      expect(amount.controller!.text, equals('5.00'));
      expect(result.controller!.text, equals('0.50'));
    });
  });
}
