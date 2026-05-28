import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:mocktail/mocktail.dart';
import 'package:realunit_wallet/packages/service/app_store.dart';
import 'package:realunit_wallet/packages/service/wallet_service.dart';
import 'package:realunit_wallet/screens/settings_seed/bloc/settings_seed_cubit.dart';
import 'package:realunit_wallet/screens/settings_seed/settings_seed_page.dart';
import 'package:realunit_wallet/screens/settings_seed/settings_seed_view.dart';

import '../../../helper/helper.dart';

class _MockSettingsSeedCubit extends MockCubit<SettingsSeedState> implements SettingsSeedCubit {}

class _MockWalletService extends Mock implements WalletService {}

void main() {
  const seed =
      'cheese trigger cannon mention judge hire snack sustain annual predict illness celery';

  late _MockSettingsSeedCubit settingsSeedCubit;
  final MockAppStore appStore = MockAppStore();
  final _MockWalletService walletService = _MockWalletService();

  setUp(() {
    settingsSeedCubit = _MockSettingsSeedCubit();
    when(() => settingsSeedCubit.state).thenReturn(const SettingsSeedState(seed));
    when(() => walletService.ensureCurrentWalletUnlocked()).thenAnswer((_) async {});
    when(() => walletService.lockCurrentWallet()).thenAnswer((_) async {});
  });

  setUpAll(() {
    stubNoScreenshotChannel();

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

    goldenTest(
      'revealed state with visible seed',
      fileName: 'settings_seed_page_revealed',
      constraints: phoneConstraints,
      builder: () {
        when(
          () => settingsSeedCubit.state,
        ).thenReturn(const SettingsSeedState(seed, showSeed: true));
        return wrapForGolden(
          BlocProvider<SettingsSeedCubit>.value(
            value: settingsSeedCubit,
            child: const SettingsSeedView(),
          ),
        );
      },
    );
  });
}
