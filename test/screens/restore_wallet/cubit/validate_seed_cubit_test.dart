import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:realunit_wallet/packages/service/wallet_service.dart';
import 'package:realunit_wallet/screens/restore_wallet/cubit/validate_seed/validate_seed_cubit.dart';

class _MockWalletService extends Mock implements WalletService {}

const _validMnemonic =
    'test test test test test test test test test test test junk';

void main() {
  late _MockWalletService service;

  setUp(() {
    service = _MockWalletService();
  });

  group('$ValidateSeedCubit', () {
    test('initial state is uncomplete', () {
      expect(ValidateSeedCubit(service).state, ValidateSeedState.uncomplete);
    });

    group('checkSeedLength', () {
      blocTest<ValidateSeedCubit, ValidateSeedState>(
        'emits complete when 12 words are all in the bip39 english wordlist',
        build: () => ValidateSeedCubit(service),
        act: (cubit) => cubit.checkSeedLength(_validMnemonic),
        expect: () => [ValidateSeedState.complete],
      );

      blocTest<ValidateSeedCubit, ValidateSeedState>(
        'emits uncomplete when fewer than 12 words',
        build: () => ValidateSeedCubit(service),
        seed: () => ValidateSeedState.complete,
        act: (cubit) => cubit.checkSeedLength('test test test'),
        expect: () => [ValidateSeedState.uncomplete],
      );

      blocTest<ValidateSeedCubit, ValidateSeedState>(
        'emits uncomplete when 12 words but at least one is not in the wordlist',
        build: () => ValidateSeedCubit(service),
        act: (cubit) => cubit.checkSeedLength(
          'test test test test test test test test test test test notaword',
        ),
        expect: () => [ValidateSeedState.uncomplete],
      );

      blocTest<ValidateSeedCubit, ValidateSeedState>(
        'tolerates extra whitespace between words',
        build: () => ValidateSeedCubit(service),
        act: (cubit) =>
            // Extra inner whitespace is filtered out by the where-isNotEmpty.
            cubit.checkSeedLength('test  test  test  test  test  test  test  test  test  test  test  junk'),
        expect: () => [ValidateSeedState.complete],
      );
    });

    group('validateSeed', () {
      blocTest<ValidateSeedCubit, ValidateSeedState>(
        'emits valid when the underlying wallet service accepts the seed',
        build: () {
          when(() => service.validateSeed(any())).thenReturn(true);
          return ValidateSeedCubit(service);
        },
        act: (cubit) => cubit.validateSeed(_validMnemonic),
        expect: () => [ValidateSeedState.valid],
        verify: (_) {
          verify(() => service.validateSeed(_validMnemonic)).called(1);
        },
      );

      blocTest<ValidateSeedCubit, ValidateSeedState>(
        'emits invalid when the underlying wallet service rejects the seed',
        build: () {
          when(() => service.validateSeed(any())).thenReturn(false);
          return ValidateSeedCubit(service);
        },
        act: (cubit) => cubit.validateSeed('garbage'),
        expect: () => [ValidateSeedState.invalid],
      );
    });
  });
}
