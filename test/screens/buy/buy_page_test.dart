import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:mocktail/mocktail.dart';
import 'package:realunit_wallet/generated/i18n.dart';
import 'package:realunit_wallet/packages/service/app_store.dart';
import 'package:realunit_wallet/packages/service/dfx/dfx_allowlist_service.dart';
import 'package:realunit_wallet/packages/service/dfx/dfx_bank_details_service.dart';
import 'package:realunit_wallet/packages/service/dfx/dfx_brokerbot_service.dart';
import 'package:realunit_wallet/packages/service/dfx/models/payment/buy_payment_info.dart';
import 'package:realunit_wallet/packages/service/dfx/models/payment/buy_payment_info_error.dart';
import 'package:realunit_wallet/packages/service/dfx/real_unit_buy_payment_info_service.dart';
import 'package:realunit_wallet/screens/buy/buy_page.dart';
import 'package:realunit_wallet/screens/buy/cubits/buy_allowlist/buy_allowlist_cubit.dart';
import 'package:realunit_wallet/screens/buy/cubits/buy_bank_details/buy_bank_details_cubit.dart';
import 'package:realunit_wallet/screens/buy/cubits/buy_converter/buy_converter_cubit.dart';
import 'package:realunit_wallet/screens/buy/cubits/buy_payment_info/buy_payment_info_cubit.dart';
import 'package:realunit_wallet/screens/buy/widgets/payment_action_required.dart';
import 'package:realunit_wallet/screens/buy/widgets/payment_converter.dart';
import 'package:realunit_wallet/screens/buy/widgets/payment_information.dart';
import 'package:realunit_wallet/screens/buy/widgets/payment_information_details.dart';
import 'package:realunit_wallet/styles/currency.dart';

import '../../helper/helper.dart';

class MockBuyAllowlistCubit extends MockCubit<BuyAllowlistState> implements BuyAllowlistCubit {}

class MockBuyConverterCubit extends MockCubit<BuyConverterState> implements BuyConverterCubit {}

class MockBuyBankDetailsCubit extends MockCubit<BuyBankDetailsState>
    implements BuyBankDetailsCubit {}

class MockBuyPaymentInfoCubit extends MockCubit<BuyPaymentInfoState>
    implements BuyPaymentInfoCubit {}

class MockDfxAllowlistService extends Mock implements DfxAllowlistService {}

class MockDfxBrokerbotService extends Mock implements DfxBrokerbotService {}

class MockDfxBankDetailsService extends Mock implements DfxBankDetailsService {}

class MockRealUnitBuyPaymentInfoService extends Mock implements RealUnitBuyPaymentInfoService {}

void main() {
  late BuyAllowlistCubit allowlistCubit;
  late BuyConverterCubit converterCubit;
  late BuyBankDetailsCubit bankDetailsCubit;
  late BuyPaymentInfoCubit buyPaymentInfoCubit;

  setUp(() {
    allowlistCubit = MockBuyAllowlistCubit();
    converterCubit = MockBuyConverterCubit();
    bankDetailsCubit = MockBuyBankDetailsCubit();
    buyPaymentInfoCubit = MockBuyPaymentInfoCubit();

    when(() => allowlistCubit.state).thenReturn(const BuyAllowlistState());
    when(() => converterCubit.state).thenReturn(const BuyConverterState());
    when(() => bankDetailsCubit.state).thenReturn(const BuyBankDetailsState());
    when(() => buyPaymentInfoCubit.state).thenReturn(const BuyPaymentInfoInitial());
    when(
      () =>
          buyPaymentInfoCubit.getPaymentInfo(amount: any(named: 'amount'), currency: Currency.chf),
    ).thenAnswer((_) => Future.value());
  });

  void setupDependencyInjection() {
    final getIt = GetIt.instance;
    getIt.registerSingleton<AppStore>(AppStore());
    getIt.registerSingleton<DfxAllowlistService>(MockDfxAllowlistService());
    getIt.registerSingleton<DfxBrokerbotService>(MockDfxBrokerbotService());
    getIt.registerSingleton<DfxBankDetailsService>(MockDfxBankDetailsService());
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
      await tester.pumpApp(BuyPage());

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
              iban: "iban",
              bic: "bic",
              name: "name",
              street: "street",
              number: "number",
              zip: "zip",
              city: "city",
              country: "country",
              currency: Currency.chf),
        ),
      );

      await tester.pumpApp(buildSubject(const BuyView()));

      expect(find.byType(PaymentConverter), findsOne);
      expect(find.byType(PaymentInformationDetails), findsOne);
    });

    testWidgets('renders correctly when $BuyPaymentInfo is loading', (tester) async {
      when(() => buyPaymentInfoCubit.state).thenReturn(const BuyPaymentInfoLoading());

      await tester.pumpApp(buildSubject(const BuyView()));

      expect(find.byType(PaymentConverter), findsOne);
      expect(find.byType(CupertinoActivityIndicator), findsOne);
    });

    testWidgets('renders correctly when when registration is required', (tester) async {
      when(() => buyPaymentInfoCubit.state).thenReturn(
        const BuyPaymentInfoFailure(BuyPaymentInfoError.registrationRequired),
      );

      await tester.pumpApp(buildSubject(const BuyView()));

      expect(find.byType(PaymentActionRequired), findsOne);
      expect(find.byType(PaymentInformation), findsOne);
      expect(find.text('Registrierung erforderlich'), findsOne);
    });

    testWidgets('renders correctly when when kyc is required', (tester) async {
      when(() => buyPaymentInfoCubit.state).thenReturn(
        const BuyPaymentInfoFailure(BuyPaymentInfoError.kycRequired),
      );

      await tester.pumpApp(buildSubject(const BuyView()));

      expect(find.byType(PaymentActionRequired), findsOne);
      expect(find.byType(PaymentInformation), findsOne);
      expect(find.text(S.current.identity_check_required), findsOne);
    });

    testWidgets('updates controllers when $BuyConverterState changes', (tester) async {
      whenListen(
        converterCubit,
        Stream.fromIterable([
          const BuyConverterState(fiatText: "5.00", sharesText: "0.50"),
        ]),
        initialState: const BuyConverterState(fiatText: "1.00", sharesText: "0.10"),
      );

      await tester.pumpApp(buildSubject(const BuyView()));
      await tester.pumpAndSettle();

      final amountField = find.byType(TextField).first;
      final resultField = find.byType(TextField).last;

      TextField amount = tester.widget(amountField);
      TextField result = tester.widget(resultField);

      expect(amount.controller!.text, equals("5.00"));
      expect(result.controller!.text, equals("0.50"));
    });
  });
}
