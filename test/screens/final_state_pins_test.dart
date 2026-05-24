import 'package:flutter_test/flutter_test.dart';
import 'package:realunit_wallet/packages/wallet/wallet.dart';
import 'package:realunit_wallet/screens/restore_wallet/cubit/restore_wallet/restore_wallet_cubit.dart';
import 'package:realunit_wallet/screens/restore_wallet/cubit/validate_seed/validate_seed_cubit.dart';
import 'package:realunit_wallet/screens/verify_seed/cubit/verify_seed_cubit.dart';

import '../test_utils/fake_wallet_isolate.dart';

void main() {
  group('$ValidateSeedState', () {
    test('enum has exactly four variants', () {
      expect(ValidateSeedState.values.toSet(), {
        ValidateSeedState.valid,
        ValidateSeedState.invalid,
        ValidateSeedState.complete,
        ValidateSeedState.uncomplete,
      });
    });
  });

  group('$RestoreWalletState', () {
    test('defaults: isLoading=false, wallet=null', () {
      const state = RestoreWalletState();
      expect(state.isLoading, isFalse);
      expect(state.wallet, isNull);
    });

    test('Equatable props pin (isLoading, wallet)', () {
      final wallet = SoftwareWallet(
        1,
        'Test',
        '0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266',
        FakeWalletIsolate(),
      );
      expect(
        const RestoreWalletState(),
        const RestoreWalletState(),
      );
      expect(
        const RestoreWalletState(),
        isNot(const RestoreWalletState(isLoading: true)),
      );
      expect(
        RestoreWalletState(wallet: wallet),
        isNot(const RestoreWalletState()),
      );
    });
  });

  group('$VerifySeedState helpers', () {
    test('defaults: empty wordIndices + enteredWords, !hasError, !isVerified', () {
      const state = VerifySeedState();
      expect(state.wordIndices, isEmpty);
      expect(state.enteredWords, isEmpty);
      expect(state.hasError, isFalse);
      expect(state.isVerified, isFalse);
      // canVerify needs length == 4 → defaults can't verify.
      expect(state.canVerify, isFalse);
    });

    test('canVerify=true only when all 4 words are non-empty', () {
      expect(
        const VerifySeedState(enteredWords: ['a', 'b', 'c', 'd']).canVerify,
        isTrue,
      );
      // 4 entries but one empty → false
      expect(
        const VerifySeedState(enteredWords: ['a', 'b', '', 'd']).canVerify,
        isFalse,
      );
      // 3 entries → false even if all non-empty
      expect(
        const VerifySeedState(enteredWords: ['a', 'b', 'c']).canVerify,
        isFalse,
      );
    });

    test('copyWith preserves untouched fields', () {
      const base = VerifySeedState(
        wordIndices: [0, 1, 2, 3],
        enteredWords: ['a', '', '', ''],
      );
      final next = base.copyWith(hasError: true);
      expect(next.wordIndices, base.wordIndices);
      expect(next.enteredWords, base.enteredWords);
      expect(next.hasError, isTrue);
    });

    test('Equatable props pin all four fields', () {
      const a = VerifySeedState(enteredWords: ['a', 'b', 'c', 'd']);
      const b = VerifySeedState(enteredWords: ['a', 'b', 'c', 'd']);
      const c = VerifySeedState(
        enteredWords: ['a', 'b', 'c', 'd'],
        hasError: true,
      );
      expect(a, b);
      expect(a, isNot(c));
    });
  });
}
