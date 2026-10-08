import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:mocktail/mocktail.dart';
import 'package:realunit_wallet/models/balance.dart';
import 'package:realunit_wallet/packages/config/api_config.dart';
import 'package:realunit_wallet/packages/config/network_mode.dart';
import 'package:realunit_wallet/packages/repository/balance_repository.dart';
import 'package:realunit_wallet/packages/service/app_store.dart';
import 'package:realunit_wallet/packages/service/dfx/models/referral/dto/referral_summary_dto.dart';
import 'package:realunit_wallet/packages/service/dfx/real_unit_referral_service.dart';
import 'package:realunit_wallet/packages/service/wallet_service.dart';
import 'package:realunit_wallet/packages/utils/default_assets.dart';
import 'package:realunit_wallet/packages/wallet/wallet.dart';
import 'package:realunit_wallet/screens/home/bloc/home_bloc.dart';
import 'package:realunit_wallet/screens/settings/bloc/settings_bloc.dart';
import 'package:realunit_wallet/screens/settings/settings_page.dart';

import '../../../helper/helper.dart';

void main() {
  late MockSettingsBloc settingsBloc;
  late MockHomeBloc homeBloc;
  late MockWalletService walletService;
  late MockBalanceRepository balanceRepository;

  final software = SoftwareViewWallet(
    1,
    'Software',
    '0x0000000000000000000000000000000000000001',
  );

  setUp(() {
    settingsBloc = MockSettingsBloc();
    homeBloc = MockHomeBloc();
    walletService = MockWalletService();
    balanceRepository = MockBalanceRepository();

    when(() => settingsBloc.state).thenReturn(const SettingsState());
    when(() => homeBloc.state).thenReturn(HomeState(openWallet: software));
    when(() => balanceRepository.getBalance(any(), any())).thenAnswer(
      (invocation) async => Balance(
        chainId: realUnitAsset.chainId,
        contractAddress: realUnitAsset.address,
        walletAddress: invocation.positionalArguments[1] as String,
        balance: BigInt.one,
        asset: realUnitAsset,
      ),
    );
  });

  setUpAll(() {
    registerFallbackValue(realUnitAsset);
    GetIt.instance.registerSingleton<SettingsBloc>(MockSettingsBloc());
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
    GetIt.instance.registerSingleton<RealUnitReferralService>(referral);
    GetIt.instance.registerSingleton<WalletService>(MockWalletService());
    GetIt.instance.registerSingleton<BalanceRepository>(MockBalanceRepository());
    final appStore = MockAppStore();
    when(() => appStore.apiConfig).thenReturn(
      const ApiConfig(networkMode: NetworkMode.mainnet),
    );
    GetIt.instance.registerSingleton<AppStore>(appStore);
  });

  tearDownAll(() async {
    await GetIt.instance.reset();
  });

  Widget buildSubject() {
    if (GetIt.instance.isRegistered<SettingsBloc>()) {
      GetIt.instance.unregister<SettingsBloc>();
    }
    GetIt.instance.registerSingleton<SettingsBloc>(settingsBloc);
    if (GetIt.instance.isRegistered<WalletService>()) {
      GetIt.instance.unregister<WalletService>();
    }
    GetIt.instance.registerSingleton<WalletService>(walletService);
    if (GetIt.instance.isRegistered<BalanceRepository>()) {
      GetIt.instance.unregister<BalanceRepository>();
    }
    GetIt.instance.registerSingleton<BalanceRepository>(balanceRepository);

    return wrapForGolden(
      BlocProvider<HomeBloc>.value(
        value: homeBloc,
        child: const SettingsPage(),
      ),
    );
  }

  group('$SettingsPage hardware rows', () {
    goldenTest(
      'hardware-wallet row when software balance is positive and no BitBox is paired',
      fileName: 'settings_hardware_wallet_row',
      constraints: const BoxConstraints.tightFor(width: 390, height: 844),
      builder: () {
        when(() => walletService.listWallets()).thenAnswer((_) async => [software]);
        return buildSubject();
      },
    );

    goldenTest(
      'move-balance row when both wallets exist',
      fileName: 'settings_move_balance_row',
      constraints: const BoxConstraints.tightFor(width: 390, height: 844),
      builder: () {
        final bitbox = MockBitboxWallet();
        when(() => bitbox.walletType).thenReturn(WalletType.bitbox);
        when(() => walletService.listWallets()).thenAnswer(
          (_) async => [software, bitbox],
        );
        return buildSubject();
      },
    );
  });
}
