import 'package:alchemist/alchemist.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:mocktail/mocktail.dart';
import 'package:realunit_wallet/packages/service/app_store.dart';
import 'package:realunit_wallet/packages/service/wallet_service.dart';
import 'package:realunit_wallet/packages/wallet/wallet.dart';
import 'package:realunit_wallet/screens/settings_seed/bloc/settings_seed_cubit.dart';
import 'package:realunit_wallet/screens/settings_seed/settings_seed_page.dart';
import 'package:realunit_wallet/screens/settings_seed/settings_seed_view.dart';

import '../../../helper/helper.dart';

class _MockSettingsSeedCubit extends MockCubit<SettingsSeedState>
    implements SettingsSeedCubit {}

class _MockAppStore extends Mock implements AppStore {}

class _MockWalletService extends Mock implements WalletService {}

class _MockWallet extends Mock implements SoftwareWallet {}

void main() {
  const phoneConstraints = BoxConstraints.tightFor(width: 390, height: 844);
  const seed =
      'cheese trigger cannon mention judge hire snack sustain annual predict illness celery';

  late _MockSettingsSeedCubit settingsSeedCubit;
  final _MockAppStore appStore = _MockAppStore();
  final _MockWalletService walletService = _MockWalletService();
  final _MockWallet wallet = _MockWallet();

  setUp(() {
    settingsSeedCubit = _MockSettingsSeedCubit();
    when(() => settingsSeedCubit.state).thenReturn(const SettingsSeedState(seed));
    when(() => appStore.wallet).thenReturn(wallet);
    when(() => wallet.seed).thenReturn(seed);
    when(() => walletService.ensureCurrentWalletUnlocked()).thenAnswer((_) async {});
    when(() => walletService.lockCurrentWallet()).thenAnswer((_) async {});
  });

  setUpAll(() {
    // Stub the no_screenshot plugin's MethodChannel so screenshotOff/On calls
    // do not throw MissingPluginException in headless tests.
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('com.flutterplaza.no_screenshot_methods'),
      (call) async => true,
    );

    final getIt = GetIt.instance;
    getIt.registerSingleton<AppStore>(appStore);
    getIt.registerSingleton<WalletService>(walletService);
  });

  tearDownAll(() async {
    await GetIt.instance.reset();
  });

  group('$SettingsSeedPage', () {
    goldenTest(
      'default state with blurred seed',
      fileName: 'settings_seed_page_default',
      constraints: phoneConstraints,
      builder: () => wrapForGolden(
        BlocProvider<SettingsSeedCubit>.value(
          value: settingsSeedCubit,
          child: const SettingsSeedView(),
        ),
      ),
    );
  });
}
