import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:get_it/get_it.dart';
import 'package:mocktail/mocktail.dart';
import 'package:realunit_wallet/models/balance.dart';
import 'package:realunit_wallet/models/portfolio_value_point.dart';
import 'package:realunit_wallet/models/price_point.dart';
import 'package:realunit_wallet/packages/config/api_config.dart';
import 'package:realunit_wallet/packages/repository/balance_repository.dart';
import 'package:realunit_wallet/packages/service/app_store.dart';
import 'package:realunit_wallet/packages/service/dfx/dfx_price_service.dart';
import 'package:realunit_wallet/packages/service/dfx/models/referral/dto/referral_summary_dto.dart';
import 'package:realunit_wallet/packages/service/dfx/models/transactions/dto/transactions_dto.dart';
import 'package:realunit_wallet/packages/service/dfx/real_unit_account_service.dart';
import 'package:realunit_wallet/packages/service/dfx/real_unit_referral_service.dart';
import 'package:realunit_wallet/packages/service/transaction_history_service.dart';
import 'package:realunit_wallet/packages/service/wallet_service.dart';
import 'package:realunit_wallet/packages/utils/default_assets.dart';
import 'package:realunit_wallet/packages/wallet/wallet.dart';
import 'package:realunit_wallet/screens/dashboard/dashboard_page.dart';
import 'package:realunit_wallet/screens/home/bloc/home_bloc.dart';
import 'package:realunit_wallet/screens/settings/bloc/settings_bloc.dart';
import 'package:realunit_wallet/styles/currency.dart';

import '../../../helper/helper.dart';

class _MockDfxPriceService extends Mock implements DFXPriceService {}

class _MockRealUnitAccountService extends Mock implements RealUnitAccountService {}

class _MockTransactionHistoryService extends Mock implements TransactionHistoryService {}

class _MockApiConfig extends Mock implements ApiConfig {}

void main() {
  late MockSettingsBloc settingsBloc;
  late MockHomeBloc homeBloc;
  late MockWalletService walletService;

  final software = SoftwareViewWallet(
    1,
    'Software',
    '0x0000000000000000000000000000000000000001',
  );

  setUpAll(() {
    registerFallbackValue(realUnitAsset);
    registerFallbackValue(Currency.chf);
    registerFallbackValue(
      Balance(
        chainId: realUnitAsset.chainId,
        contractAddress: realUnitAsset.address,
        walletAddress: '0x0',
        balance: BigInt.zero,
        asset: realUnitAsset,
      ),
    );

    final getIt = GetIt.instance;
    final apiConfig = _MockApiConfig();
    final appStore = MockAppStore();
    when(() => apiConfig.asset).thenReturn(realUnitAsset);
    when(() => appStore.apiConfig).thenReturn(apiConfig);
    when(() => appStore.primaryAddress).thenReturn('0x0');
    getIt.registerSingleton<AppStore>(appStore);

    walletService = MockWalletService();
    getIt.registerSingleton<WalletService>(walletService);

    final priceService = _MockDfxPriceService();
    when(() => priceService.getPriceOfAsset(any(), any())).thenAnswer((_) async => BigInt.zero);
    when(() => priceService.getPriceChart(any(), any())).thenAnswer((_) async => <PricePoint>[]);
    getIt.registerSingleton<DFXPriceService>(priceService);

    final accountService = _MockRealUnitAccountService();
    when(() => accountService.getPortfolioHistory(any())).thenAnswer(
      (_) async => <PortfolioValuePoint>[],
    );
    getIt.registerSingleton<RealUnitAccountService>(accountService);

    final balanceRepository = MockBalanceRepository();
    when(() => balanceRepository.watchBalance(any())).thenAnswer(
      (_) => const Stream<Balance>.empty(),
    );
    getIt.registerSingleton<BalanceRepository>(balanceRepository);

    final transactionHistory = _MockTransactionHistoryService();
    when(() => transactionHistory.fetchPendingTransactions()).thenAnswer(
      (_) async => <TransactionDto>[],
    );
    getIt.registerSingleton<TransactionHistoryService>(transactionHistory);

    final referral = MockRealUnitReferralService();
    when(() => referral.getSummary()).thenAnswer(
      (_) async => const ReferralSummaryDto(
        eligible: false,
        termsAccepted: false,
        openCount: 0,
        creditedCount: 0,
        realuSum: 0,
        chfSum: 0,
      ),
    );
    getIt.registerSingleton<RealUnitReferralService>(referral);
  });

  tearDownAll(() async => GetIt.instance.reset());

  setUp(() {
    settingsBloc = MockSettingsBloc();
    homeBloc = MockHomeBloc();

    when(() => settingsBloc.state).thenReturn(const SettingsState());
    whenListen(
      settingsBloc,
      const Stream<SettingsState>.empty(),
      initialState: const SettingsState(),
    );
    when(() => homeBloc.state).thenReturn(
      HomeState(
        hasWallet: true,
        openWallet: software,
      ),
    );
    whenListen(
      homeBloc,
      const Stream<HomeState>.empty(),
      initialState: HomeState(
        hasWallet: true,
        openWallet: software,
      ),
    );

    final bitbox = MockBitboxWallet();
    when(() => bitbox.walletType).thenReturn(WalletType.bitbox);
    when(() => bitbox.id).thenReturn(2);
    when(() => walletService.listWallets()).thenAnswer(
      (_) async => [software, bitbox],
    );
  });

  Widget buildSubject() => MultiBlocProvider(
    providers: [
      BlocProvider<SettingsBloc>.value(value: settingsBloc),
      BlocProvider<HomeBloc>.value(value: homeBloc),
    ],
    child: const DashboardPage(),
  );

  group('$DashboardPage wallet switcher', () {
    goldenTest(
      'two-segment control for software and BitBox',
      fileName: 'dashboard_wallet_switcher',
      constraints: const BoxConstraints.tightFor(width: 390, height: 844),
      builder: () => wrapForGolden(buildSubject()),
    );
  });
}
