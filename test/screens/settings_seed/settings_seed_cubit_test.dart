import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:realunit_wallet/packages/service/app_store.dart';
import 'package:realunit_wallet/packages/wallet/wallet.dart';
import 'package:realunit_wallet/screens/settings_seed/bloc/settings_seed_cubit.dart';

class _MockAppStore extends Mock implements AppStore {}

// Canonical BIP39 test mnemonic — recommended fixture for any wallet code
// path that needs a deterministic, well-known seed.
const _testSeed =
    'abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon about';

void main() {
  late SoftwareWallet wallet;
  late _MockAppStore appStore;

  setUp(() {
    wallet = SoftwareWallet(1, 'Test', _testSeed);
    appStore = _MockAppStore();
    when(() => appStore.ensureUnlocked()).thenAnswer((_) async {});
    when(() => appStore.wallet).thenReturn(wallet);
  });

  group('$SettingsSeedCubit', () {
    test('initial state surfaces the wallet seed; ensureUnlocked is invoked', () async {
      final cubit = SettingsSeedCubit(appStore);
      // For a wallet that is already a SoftwareWallet the seed is in initial
      // state. `_loadSeed()` still runs and invokes ensureUnlocked — drain
      // the microtask queue so the call is observable to mocktail.
      await Future<void>.delayed(Duration.zero);

      expect(cubit.state.seed, _testSeed);
      expect(cubit.state.showSeed, isFalse);
      verify(() => appStore.ensureUnlocked()).called(1);
    });

    blocTest<SettingsSeedCubit, SettingsSeedState>(
      'toggleShowSeed flips showSeed and keeps seed unchanged',
      build: () => SettingsSeedCubit(appStore),
      act: (c) => c.toggleShowSeed(),
      verify: (c) {
        expect(c.state.seed, _testSeed);
        expect(c.state.showSeed, isTrue);
      },
    );

    blocTest<SettingsSeedCubit, SettingsSeedState>(
      'toggleShowSeed twice returns to showSeed=false',
      build: () => SettingsSeedCubit(appStore),
      act: (c) => c
        ..toggleShowSeed()
        ..toggleShowSeed(),
      verify: (c) {
        expect(c.state.seed, _testSeed);
        expect(c.state.showSeed, isFalse);
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
