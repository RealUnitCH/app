import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:mocktail/mocktail.dart';
import 'package:realunit_wallet/packages/service/app_store.dart';
import 'package:realunit_wallet/packages/service/wallet_service.dart';
import 'package:realunit_wallet/packages/wallet/wallet.dart';
import 'package:realunit_wallet/screens/settings_seed/bloc/settings_seed_cubit.dart';
import 'package:realunit_wallet/screens/settings_seed/settings_seed_page.dart';
import 'package:realunit_wallet/screens/settings_seed/settings_seed_view.dart';
import 'package:realunit_wallet/widgets/mnemonic_field.dart';
import 'package:realunit_wallet/widgets/seed_blur_card.dart';

import '../../helper/helper.dart';

class MockSettingsSeedCubit extends MockCubit<SettingsSeedState> implements SettingsSeedCubit {}

class MockAppStore extends Mock implements AppStore {}

class MockWalletService extends Mock implements WalletService {}

class MockWallet extends Mock implements SoftwareWallet {}

void main() {
  late SettingsSeedCubit settingsSeedCubit;
  final AppStore appStore = MockAppStore();
  final WalletService walletService = MockWalletService();
  final SoftwareWallet wallet = MockWallet();

  setUp(() {
    settingsSeedCubit = MockSettingsSeedCubit();

    when(() => settingsSeedCubit.state).thenReturn(
      const SettingsSeedState(
        'cheese trigger cannon mention judge hire snack sustain annual predict illness celery',
      ),
    );
    when(() => appStore.wallet).thenReturn(wallet);
    when(() => wallet.seed).thenReturn(
      'cheese trigger cannon mention judge hire snack sustain annual predict illness celery',
    );
    // Page builds a real SettingsSeedCubit via BlocProvider(create: ...), which
    // calls WalletService.ensureCurrentWalletUnlocked() before reading the
    // seed and lockCurrentWallet() on close. Stub both so mocktail returns
    // real Future<void>s instead of null.
    when(() => walletService.ensureCurrentWalletUnlocked()).thenAnswer((_) async {});
    when(() => walletService.lockCurrentWallet()).thenAnswer((_) async {});
  });

  void setupDependencyInjection() {
    final getIt = GetIt.instance;
    getIt.registerSingleton<AppStore>(appStore);
    getIt.registerSingleton<WalletService>(walletService);
  }

  setUpAll(() {
    setupDependencyInjection();
  });

  Widget buildSubject(Widget child) {
    return BlocProvider.value(
      value: settingsSeedCubit,
      child: child,
    );
  }

  group('$SettingsSeedPage', () {
    testWidgets('renders $SettingsSeedView', (tester) async {
      await tester.pumpApp(const SettingsSeedPage());

      expect(find.byType(SettingsSeedView), findsOne);
    });
  });

  group('$SettingsSeedView', () {
    testWidgets('renders initially correctly', (tester) async {
      await tester.pumpApp(buildSubject(const SettingsSeedView()));

      expect(
        find.byWidgetPredicate((Widget widget) => widget is SvgPicture && widget.height == 124),
        findsOne,
      );
      expect(find.byType(SeedBlurCard), findsOne);
    });

    group('$MnemonicReadOnlyField', () {
      testWidgets('is blurred', (tester) async {
        when(() => settingsSeedCubit.state).thenReturn(
          const SettingsSeedState(
            'cheese trigger cannon mention judge hire snack sustain annual predict illness celery',
            showSeed: false,
          ),
        );

        await tester.pumpApp(buildSubject(const SettingsSeedView()));

        expect(
          find.byWidgetPredicate((Widget widget) => widget is SeedBlurCard && widget.blur == true),
          findsOne,
        );
      });

      testWidgets('is unblurred', (tester) async {
        when(() => settingsSeedCubit.state).thenReturn(
          const SettingsSeedState(
            'cheese trigger cannon mention judge hire snack sustain annual predict illness celery',
            showSeed: true,
          ),
        );

        await tester.pumpApp(buildSubject(const SettingsSeedView()));

        expect(
          find.byWidgetPredicate((Widget widget) => widget is SeedBlurCard && widget.blur == false),
          findsOne,
        );
      });
    });

    // Regression for the first-render crash that bypassed the mocked-cubit
    // tests above. In production the page boots with a [SoftwareViewWallet],
    // the real cubit's initial state has an empty seed, and the first frame
    // used to build SeedBlurCard → MnemonicReadOnlyField([]) which trips the
    // `length == 12` assert. The view must show a spinner until the unlock
    // completes, then rebuild with the 12-word seed.
    testWidgets('first render with SoftwareViewWallet shows spinner, then SeedBlurCard', (tester) async {
      const seed =
          'cheese trigger cannon mention judge hire snack sustain annual predict illness celery';
      final softwareViewWallet = SoftwareViewWallet(
        1,
        'Test',
        '0x0000000000000000000000000000000000000001',
      );
      final softwareWallet = SoftwareWallet(1, 'Test', seed);
      final unlockCompleter = Completer<void>();
      // Cycle wallet from view → unlocked the same way the real
      // WalletService.ensureCurrentWalletUnlocked does.
      AWallet currentWallet = softwareViewWallet;
      when(() => appStore.wallet).thenAnswer((_) => currentWallet);
      when(() => walletService.ensureCurrentWalletUnlocked()).thenAnswer((_) async {
        await unlockCompleter.future;
        currentWallet = softwareWallet;
      });
      when(() => walletService.lockCurrentWallet()).thenAnswer((_) async {});

      // Drive a real SettingsSeedCubit — the production path — so the empty
      // initial seed actually shows up in the first frame.
      await tester.pumpApp(
        BlocProvider(
          create: (_) => SettingsSeedCubit(appStore, walletService),
          child: const SettingsSeedView(),
        ),
      );

      // First frame: cubit state.seed is still '', view must not crash.
      expect(find.byType(CupertinoActivityIndicator), findsOne);
      expect(find.byType(SeedBlurCard), findsNothing);

      // Unlock resolves; the cubit emits the 12-word seed.
      unlockCompleter.complete();
      await tester.pumpAndSettle();

      expect(find.byType(CupertinoActivityIndicator), findsNothing);
      expect(find.byType(SeedBlurCard), findsOne);
    });
  });
}
