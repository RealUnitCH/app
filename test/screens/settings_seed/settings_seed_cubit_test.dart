import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:realunit_wallet/packages/wallet/wallet.dart';
import 'package:realunit_wallet/screens/settings_seed/bloc/settings_seed_cubit.dart';

// Canonical BIP39 test mnemonic — recommended fixture for any wallet code
// path that needs a deterministic, well-known seed.
const _testSeed =
    'abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon about';

void main() {
  late SoftwareWallet wallet;

  setUp(() {
    wallet = SoftwareWallet(1, 'Test', _testSeed);
  });

  group('$SettingsSeedCubit', () {
    test('initial state mirrors the wallet seed with showSeed=false', () {
      final cubit = SettingsSeedCubit(wallet);

      expect(cubit.state.seed, _testSeed);
      expect(cubit.state.showSeed, isFalse);
    });

    blocTest<SettingsSeedCubit, SettingsSeedState>(
      'toggleShowSeed flips showSeed and keeps seed unchanged',
      build: () => SettingsSeedCubit(wallet),
      act: (c) => c.toggleShowSeed(),
      expect: () => [
        const SettingsSeedState(_testSeed, showSeed: true),
      ],
    );

    blocTest<SettingsSeedCubit, SettingsSeedState>(
      'toggleShowSeed twice returns to showSeed=false',
      build: () => SettingsSeedCubit(wallet),
      act: (c) => c
        ..toggleShowSeed()
        ..toggleShowSeed(),
      expect: () => [
        const SettingsSeedState(_testSeed, showSeed: true),
        const SettingsSeedState(_testSeed),
      ],
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
