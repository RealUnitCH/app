import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:mocktail/mocktail.dart';
import 'package:realunit_wallet/generated/i18n.dart';
import 'package:realunit_wallet/packages/config/api_config.dart';
import 'package:realunit_wallet/packages/service/app_store.dart';
import 'package:realunit_wallet/packages/service/dfx/dfx_brokerbot_service.dart';
import 'package:realunit_wallet/packages/service/dfx/models/payment/buy/buy_payment_info.dart';
import 'package:realunit_wallet/packages/service/dfx/models/payment/payment_info_error.dart';
import 'package:realunit_wallet/packages/service/dfx/real_unit_buy_payment_info_service.dart';
import 'package:realunit_wallet/screens/buy/buy_page.dart';
import 'package:realunit_wallet/screens/buy/cubits/buy_converter/buy_converter_cubit.dart';
import 'package:realunit_wallet/screens/buy/cubits/buy_payment_info/buy_payment_info_cubit.dart';
import 'package:realunit_wallet/screens/buy/widgets/payment_action_required.dart';
import 'package:realunit_wallet/screens/buy/widgets/payment_converter.dart';
import 'package:realunit_wallet/screens/buy/widgets/payment_information.dart';
import 'package:realunit_wallet/screens/buy/widgets/payment_information_details.dart';
import 'package:realunit_wallet/styles/currency.dart';

import '../../helper/helper.dart';

class MockBuyConverterCubit extends MockCubit<BuyConverterState> implements BuyConverterCubit {}

class MockBuyPaymentInfoCubit extends MockCubit<BuyPaymentInfoState>
    implements BuyPaymentInfoCubit {}

class MockDfxBrokerbotService extends Mock implements DfxBrokerbotService {}

class MockRealUnitBuyPaymentInfoService extends Mock implements RealUnitBuyPaymentInfoService {}

class MockApiConfig extends Mock implements ApiConfig {}

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
        currency: Currency.chf,
      ),
    ).thenAnswer((_) => Future.value());
  });

  void setupDependencyInjection() {
    final getIt = GetIt.instance;
    getIt.registerSingleton<AppStore>(AppStore(() => MockApiConfig()));
    getIt.registerSingleton<DfxBrokerbotService>(MockDfxBrokerbotService());
    getIt.registerSingleton<RealUnitBuyPaymentInfoService>(MockRealUnitBuyPaymentInfoService());
  }

  setUpAll(() {
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
          (Widget widget) => widget is FilledButton && widget.onPressed != null,
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
          (Widget widget) => widget is FilledButton && widget.onPressed != null,
        ),
        findsOne,
      );
    });

    testWidgets('renders correctly when min amount is not met', (tester) async {
      when(() => buyPaymentInfoCubit.state).thenReturn(
        const BuyPaymentInfoFailure(PaymentInfoError.minAmountNotMet),
      );

      await tester.pumpApp(buildSubject(const BuyView()));

      expect(find.byType(PaymentActionRequired), findsNothing);
      expect(find.byType(PaymentInformation), findsOne);
      expect(find.text(S.current.buyMinAmount), findsOne);
      expect(
        find.byWidgetPredicate(
          (Widget widget) => widget is FilledButton && widget.onPressed == null,
        ),
        findsOne,
      );
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
