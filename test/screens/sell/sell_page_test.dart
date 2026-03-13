import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:mocktail/mocktail.dart';
import 'package:realunit_wallet/packages/config/api_config.dart';
import 'package:realunit_wallet/packages/service/app_store.dart';
import 'package:realunit_wallet/packages/service/dfx/dfx_bank_account_service.dart';
import 'package:realunit_wallet/packages/service/dfx/dfx_brokerbot_service.dart';
import 'package:realunit_wallet/packages/service/dfx/models/bank_account/bank_account.dart';
import 'package:realunit_wallet/packages/service/dfx/real_unit_sell_payment_info_service.dart';
import 'package:realunit_wallet/screens/sell/cubits/sell_converter/sell_converter_cubit.dart';
import 'package:realunit_wallet/screens/sell/cubits/sell_payment_info/sell_payment_info_cubit.dart';
import 'package:realunit_wallet/screens/sell/cubits/sell_selected_bank_account/sell_selected_bank_account_cubit.dart';
import 'package:realunit_wallet/screens/sell/sell_page.dart';
import 'package:realunit_wallet/screens/sell/widgets/sell_add_bank_account_sheet.dart';
import 'package:realunit_wallet/screens/sell/widgets/sell_bank_account_field.dart';
import 'package:realunit_wallet/screens/sell/widgets/sell_button.dart';
import 'package:realunit_wallet/screens/sell/widgets/sell_converter.dart';
import 'package:realunit_wallet/styles/currency.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../helper/helper.dart';

class MockSellConverterCubit extends MockCubit<SellConverterState> implements SellConverterCubit {}

class MockSellPaymentInfoCubit extends MockCubit<SellPaymentInfoState>
    implements SellPaymentInfoCubit {}

class MockSellSelectedBankAccountCubit extends MockCubit<BankAccount?>
    implements SellSelectedBankAccountCubit {}

class MockDfxBrokerbotService extends Mock implements DfxBrokerbotService {}

class MockDfxBankAccountService extends Mock implements DfxBankAccountService {}

class MockRealUnitSellPaymentInfoService extends Mock implements RealUnitSellPaymentInfoService {}

class MockApiConfig extends Mock implements ApiConfig {}

void main() {
  late SellConverterCubit converterCubit;
  late SellPaymentInfoCubit sellPaymentInfoCubit;
  late SellSelectedBankAccountCubit sellSelectedBankAccountCubit;

  setUp(() {
    converterCubit = MockSellConverterCubit();
    sellPaymentInfoCubit = MockSellPaymentInfoCubit();
    sellSelectedBankAccountCubit = MockSellSelectedBankAccountCubit();

    when(() => converterCubit.state).thenReturn(const SellConverterState());
    when(() => sellPaymentInfoCubit.state).thenReturn(const SellPaymentInfoInitial());
    when(
      () => sellPaymentInfoCubit.getPaymentInfo(
        amount: any(named: 'amount'),
        iban: any(named: 'iban'),
        currency: Currency.chf,
      ),
    ).thenAnswer((_) => Future.value());
    when(() => sellSelectedBankAccountCubit.state).thenReturn(null);
  });

  Future<void> setupDependencyInjection() async {
    SharedPreferences.setMockInitialValues({});
    final getIt = GetIt.instance;
    getIt.registerSingleton<AppStore>(AppStore(() => MockApiConfig()));
    getIt.registerSingleton<DfxBrokerbotService>(MockDfxBrokerbotService());
    getIt.registerSingleton<DfxBankAccountService>(MockDfxBankAccountService());
    getIt.registerSingleton<RealUnitSellPaymentInfoService>(MockRealUnitSellPaymentInfoService());
    getIt.registerSingleton<SharedPreferences>(await SharedPreferences.getInstance());
  }

  setUpAll(() async => await setupDependencyInjection());

  tearDownAll(() async => await GetIt.instance.reset());

  Widget buildSubject(Widget child) {
    return MultiBlocProvider(
      providers: [
        BlocProvider.value(value: converterCubit),
        BlocProvider.value(value: sellPaymentInfoCubit),
        BlocProvider.value(value: sellSelectedBankAccountCubit),
      ],
      child: const SellView(),
    );
  }

  group('$SellPage', () {
    testWidgets('renders $SellView', (tester) async {
      await tester.pumpApp(const SellPage());

      expect(find.byType(SellView), findsOne);
    });
  });

  group('$SellView', () {
    testWidgets('renders initially correctly', (tester) async {
      await tester.pumpApp(buildSubject(const SellView()));

      expect(find.byType(SellConverter), findsOne);
      expect(find.byType(SellBankAccountField), findsOne);
      expect(find.byType(SellButton), findsOne);
    });

    testWidgets('$SellBankAccountField opens $SellAddBankAccountSheet', (tester) async {
      await tester.pumpApp(buildSubject(const SellView()));

      await tester.tap(find.byType(SellBankAccountField));
      await tester.pump();

      expect(find.byType(SellAddBankAccountSheet), findsOne);
    });

    group('$SellButton', () {
      testWidgets('is initially disabled button', (tester) async {
        when(() => sellPaymentInfoCubit.state).thenReturn(const SellPaymentInfoInitial());
        await tester.pumpApp(buildSubject(const SellView()));

        expect(
          find.byWidgetPredicate(
            (Widget widget) => widget is FilledButton && widget.onPressed == null,
          ),
          findsOne,
        );
      });

      testWidgets('shows loading state if SellPaymentInfoState is loading', (tester) async {
        when(() => sellPaymentInfoCubit.state).thenReturn(const SellPaymentInfoLoading());
        await tester.pumpApp(buildSubject(const SellView()));

        expect(find.byType(CircularProgressIndicator), findsOne);
      });

      testWidgets('is enabled button when amount and bankaccount are given', (tester) async {
        whenListen(
          converterCubit,
          Stream.fromIterable([
            const SellConverterState(fiatText: '5.00', sharesText: '0.10', loading: true),
            const SellConverterState(fiatText: '5.00', sharesText: '0.50', loading: false),
          ]),
          initialState: const SellConverterState(fiatText: '1.00', sharesText: '0.10'),
        );

        when(
          () => sellSelectedBankAccountCubit.state,
        ).thenReturn(const BankAccount(id: 1, iban: 'CH12 3456 7890 1234 5678 9'));

        await tester.pumpApp(buildSubject(const SellView()));
        await tester.pumpAndSettle();

        expect(
          find.byWidgetPredicate(
            (Widget widget) => widget is FilledButton && widget.onPressed != null,
          ),
          findsOne,
        );
      });
    });
  });
}
