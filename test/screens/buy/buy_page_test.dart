import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:mocktail/mocktail.dart';
import 'package:realunit_wallet/packages/service/app_store.dart';
import 'package:realunit_wallet/packages/service/dfx/dfx_allowlist_service.dart';
import 'package:realunit_wallet/packages/service/dfx/dfx_bank_details_service.dart';
import 'package:realunit_wallet/packages/service/dfx/dfx_brokerbot_service.dart';
import 'package:realunit_wallet/screens/buy/buy_page.dart';
import 'package:realunit_wallet/screens/buy/cubits/buy_allowlist/buy_allowlist_cubit.dart';
import 'package:realunit_wallet/screens/buy/cubits/buy_bank_details/buy_bank_details_cubit.dart';
import 'package:realunit_wallet/screens/buy/cubits/buy_converter/buy_converter_cubit.dart';
import 'package:realunit_wallet/screens/buy/widgets/payment_converter.dart';
import 'package:realunit_wallet/screens/buy/widgets/payment_information.dart';
import 'package:realunit_wallet/screens/buy/widgets/payment_not_possible_info.dart';
import 'package:realunit_wallet/screens/buy/widgets/payment_registration_required.dart';

import '../../helper/helper.dart';

class MockBuyAllowlistCubit extends MockCubit<BuyAllowlistState> implements BuyAllowlistCubit {}

class MockBuyConverterCubit extends MockCubit<BuyConverterState> implements BuyConverterCubit {}

class MockBuyBankDetailsCubit extends MockCubit<BuyBankDetailsState>
    implements BuyBankDetailsCubit {}

class MockDfxAllowlistService extends Mock implements DfxAllowlistService {}

class MockDfxBrokerbotService extends Mock implements DfxBrokerbotService {}

class MockDfxBankDetailsService extends Mock implements DfxBankDetailsService {}

void main() {
  late BuyAllowlistCubit allowlistCubit;
  late BuyConverterCubit converterCubit;
  late BuyBankDetailsCubit bankDetailsCubit;

  setUp(() {
    allowlistCubit = MockBuyAllowlistCubit();
    converterCubit = MockBuyConverterCubit();
    bankDetailsCubit = MockBuyBankDetailsCubit();

    when(() => allowlistCubit.state).thenReturn(const BuyAllowlistState());
    when(() => converterCubit.state).thenReturn(const BuyConverterState());
    when(() => bankDetailsCubit.state).thenReturn(const BuyBankDetailsState());
  });

  void setupDependencyInjection() {
    final getIt = GetIt.instance;
    getIt.registerSingleton<AppStore>(AppStore());
    getIt.registerSingleton<DfxAllowlistService>(MockDfxAllowlistService());
    getIt.registerSingleton<DfxBrokerbotService>(MockDfxBrokerbotService());
    getIt.registerSingleton<DfxBankDetailsService>(MockDfxBankDetailsService());
  }

  setUpAll(() {
    setupDependencyInjection();
  });

  tearDownAll(() async => await GetIt.instance.reset());

  Widget buildSubject(Widget child) {
    return MultiBlocProvider(
      providers: [
        BlocProvider.value(value: allowlistCubit),
        BlocProvider.value(value: converterCubit),
        BlocProvider.value(value: bankDetailsCubit),
      ],
      child: const BuyView(),
    );
  }

  group('$BuyPage', () {
    testWidgets('renders $BuyView', (tester) async {
      await tester.pumpApp(BuyPage());

      expect(find.byType(BuyView), findsOneWidget);
    });
  });

  group('$BuyView', () {
    testWidgets('renders correctly when allowlist is loading', (tester) async {
      when(() => allowlistCubit.state).thenReturn(const BuyAllowlistState(loading: true));

      await tester.pumpApp(buildSubject(const BuyView()));

      expect(find.byType(PaymentConverter), findsOneWidget);
      expect(find.byType(CupertinoActivityIndicator), findsOneWidget);
    });
    testWidgets('renders correctly when allowlist can not receive', (tester) async {
      when(() => allowlistCubit.state).thenReturn(const BuyAllowlistState(canReceive: false));

      await tester.pumpApp(buildSubject(const BuyView()));

      expect(find.byType(PaymentConverter), findsOneWidget);
      expect(find.byType(PaymentRegistrationRequired), findsOneWidget);
    });

    testWidgets('renders correctly when allowlist is forbidden', (tester) async {
      when(() => allowlistCubit.state)
          .thenReturn(const BuyAllowlistState(canReceive: true, isForbidden: true));

      await tester.pumpApp(buildSubject(const BuyView()));

      expect(find.byType(PaymentConverter), findsOneWidget);
      expect(find.byType(PaymentNotPossibleInfo), findsOneWidget);
    });

    testWidgets('renders correctly when allowlist is allowed', (tester) async {
      when(() => allowlistCubit.state)
          .thenReturn(const BuyAllowlistState(canReceive: true, isForbidden: false));

      await tester.pumpApp(buildSubject(const BuyView()));

      expect(find.byType(PaymentConverter), findsOneWidget);
      expect(find.byType(PaymentInformation), findsOneWidget);
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
