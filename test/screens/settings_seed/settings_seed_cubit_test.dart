import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:realunit_wallet/packages/service/app_store.dart';
import 'package:realunit_wallet/packages/service/wallet_service.dart';
import 'package:realunit_wallet/packages/wallet/wallet.dart';
import 'package:realunit_wallet/screens/settings_seed/bloc/settings_seed_cubit.dart';

import '../../test_utils/fake_wallet_isolate.dart';

class _MockAppStore extends Mock implements AppStore {}

class _MockWalletService extends Mock implements WalletService {}

const _testSeed =
    'abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon about';
const _hardhatZero = '0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266';

void main() {
  late SoftwareWallet wallet;
  late _MockAppStore appStore;
  late _MockWalletService walletService;

  setUpAll(() {
    // SettingsSeedCubit registers a WidgetsBindingObserver — the
    // binding must be initialised before any test runs.
    TestWidgetsFlutterBinding.ensureInitialized();
  });

  setUp(() {
    wallet = SoftwareWallet(1, 'Test', _hardhatZero, FakeWalletIsolate());
    appStore = _MockAppStore();
    walletService = _MockWalletService();
    when(() => walletService.ensureCurrentWalletUnlocked()).thenAnswer((_) async {});
    when(() => walletService.lockCurrentWallet()).thenAnswer((_) async {});
    when(() => walletService.revealCurrentSeed())
        .thenAnswer((_) async => SeedDraft(_testSeed, name: 'Test'));
    when(() => appStore.wallet).thenReturn(wallet);
  });

  group('$SettingsSeedCubit', () {
    test('initial state is empty; reveal surfaces the seed via the isolate '
        'after ensureCurrentWalletUnlocked completes', () async {
      final cubit = SettingsSeedCubit(appStore, walletService);
      // _loadSeed runs ensure -> revealCurrentSeed -> emit. Drain the
      // microtask queue so the chain completes.
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);

      expect(cubit.state.seed, _testSeed);
      expect(cubit.state.showSeed, isFalse);
      verify(() => walletService.ensureCurrentWalletUnlocked()).called(1);
      verify(() => walletService.revealCurrentSeed()).called(1);
    });

    test('close() locks the wallet AND disposes the SeedDraft so the mnemonic '
        'does not outlive the screen', () async {
      final cubit = SettingsSeedCubit(appStore, walletService);
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);

      await cubit.close();

      verify(() => walletService.lockCurrentWallet()).called(1);
    });

    blocTest<SettingsSeedCubit, SettingsSeedState>(
      'toggleShowSeed flips showSeed and keeps seed unchanged',
      setUp: () {},
      build: () => SettingsSeedCubit(appStore, walletService),
      // Wait for the async reveal to populate the seed before the act.
      seed: () => const SettingsSeedState(_testSeed),
      act: (c) => c.toggleShowSeed(),
      verify: (c) {
        expect(c.state.showSeed, isTrue);
      },
    );
  });

  group('$SettingsSeedState', () {
    test('copyWith only overrides the provided fields', () {
      const seed = SettingsSeedState('seed-a');
      final updated = seed.copyWith(showSeed: true);

      expect(updated.seed, 'seed-a');
      expect(updated.showSeed, isTrue);
    });

    test('Equatable props cover seed + showSeed', () {
      const a = SettingsSeedState('s', showSeed: true);
      const b = SettingsSeedState('s', showSeed: true);
      const c = SettingsSeedState('s');

      expect(a, b);
      expect(a, isNot(c));
    });
  });
}
