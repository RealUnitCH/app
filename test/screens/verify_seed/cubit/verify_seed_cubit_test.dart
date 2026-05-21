import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:realunit_wallet/packages/service/wallet_service.dart';
import 'package:realunit_wallet/packages/wallet/wallet.dart';
import 'package:realunit_wallet/screens/verify_seed/cubit/verify_seed_cubit.dart';
import 'package:realunit_wallet/widgets/mnemonic_field.dart';

class _MockWalletService extends Mock implements WalletService {}

const _testMnemonic =
    'test test test test test test test test test test test junk';

void main() {
  late _MockWalletService service;
  late SoftwareWallet wallet;

  setUpAll(() {
    // Needed for the `commitGeneratedWallet(any())` matcher.
    registerFallbackValue(SoftwareWallet(0, 'fallback', _testMnemonic));
  });

  setUp(() {
    service = _MockWalletService();
    // The cubit receives an uncommitted draft from `CreateWalletCubit`
    // (id == 0). `verify` is what lands the row, via
    // `WalletService.commitGeneratedWallet`. Mirror that contract here.
    wallet = SoftwareWallet(0, 'Main', _testMnemonic);
    when(() => service.setCurrentWallet(any())).thenAnswer((_) async {});
    when(() => service.commitGeneratedWallet(any())).thenAnswer(
      (_) async => SoftwareWallet(42, 'Main', _testMnemonic),
    );
  });

  group('$VerifySeedCubit', () {
    test('picks 4 distinct ascending word indices within seed length on init', () {
      final cubit = VerifySeedCubit(wallet, service);

      expect(cubit.state.wordIndices, hasLength(4));
      // distinct
      expect(cubit.state.wordIndices.toSet().length, 4);
      // ascending
      final sorted = [...cubit.state.wordIndices]..sort();
      expect(cubit.state.wordIndices, sorted);
      // within bounds
      for (final i in cubit.state.wordIndices) {
        expect(i, inInclusiveRange(0, _testMnemonic.seedWords.length - 1));
      }
    });

    test('initial enteredWords are populated in debug mode (4 entries non-empty)', () {
      // `kDebugMode` is true under `flutter test`, so the cubit pre-fills.
      final cubit = VerifySeedCubit(wallet, service);

      expect(cubit.state.enteredWords, hasLength(4));
      expect(cubit.state.enteredWords.every((w) => w.isNotEmpty), isTrue);
    });

    test('canVerify reflects whether all four slots are filled', () {
      final cubit = VerifySeedCubit(wallet, service);

      // Debug-mode pre-fill leaves canVerify == true. Clear one to flip it.
      cubit.updateWord(0, '');
      expect(cubit.state.canVerify, isFalse);

      cubit.updateWord(0, 'anything');
      expect(cubit.state.canVerify, isTrue);
    });

    test('updateWord trims and lowercases the entry and clears the error flag', () async {
      final cubit = VerifySeedCubit(wallet, service);
      // Force an error state first.
      await cubit.verify(); // pre-filled correct words → success, isVerified=true
      // The clean way: set up a fresh cubit and corrupt one word.
      final fresh = VerifySeedCubit(wallet, service);
      fresh.updateWord(0, 'WRONG');
      await fresh.verify();
      expect(fresh.state.hasError, isTrue);

      fresh.updateWord(0, '   HELLO   ');

      expect(fresh.state.enteredWords[0], 'hello');
      expect(fresh.state.hasError, isFalse);
    });

    test('verify returns true and marks the COMMITTED wallet current when all words match',
        () async {
      final cubit = VerifySeedCubit(wallet, service);

      final result = await cubit.verify();

      expect(result, isTrue);
      expect(cubit.state.isVerified, isTrue);
      expect(cubit.state.hasError, isFalse);
      // The current wallet id must be the COMMITTED id (42), not the
      // uncommitted draft's `0` sentinel. Closes the regression where a
      // future refactor passes `_wallet.id` directly to `setCurrentWallet`
      // and silently routes onboarding to a non-existent wallet row.
      verify(() => service.setCurrentWallet(42)).called(1);
      verifyNever(() => service.setCurrentWallet(0));
    });

    // Pin the ordering: commit must precede setCurrentWallet so the row
    // exists before any downstream `getCurrentWallet` call can resolve it.
    test('verify commits the draft BEFORE marking it current', () async {
      final calls = <String>[];
      when(() => service.commitGeneratedWallet(any())).thenAnswer((inv) async {
        calls.add('commit');
        return SoftwareWallet(99, 'Main', _testMnemonic);
      });
      when(() => service.setCurrentWallet(any())).thenAnswer((inv) async {
        calls.add('setCurrent(${inv.positionalArguments.single})');
      });

      final cubit = VerifySeedCubit(wallet, service);
      await cubit.verify();

      expect(calls, ['commit', 'setCurrent(99)'],
          reason: 'commit must land the row before `setCurrentWallet` points '
              'the settings repository at it');
    });

    test('verify returns false, sets hasError, and does NOT commit or mark current on a wrong word',
        () async {
      final cubit = VerifySeedCubit(wallet, service);
      cubit.updateWord(0, 'definitely-not-a-seed-word');

      final result = await cubit.verify();

      expect(result, isFalse);
      expect(cubit.state.hasError, isTrue);
      expect(cubit.state.isVerified, isFalse);
      // The disk-side guarantee for failure paths: no `walletInfos` row
      // is written for a rejected verification. Pairs with the
      // CreateWalletCubit "zero commits across regenerates" pin.
      verifyNever(() => service.commitGeneratedWallet(any()));
      verifyNever(() => service.setCurrentWallet(any()));
    });
  });
}
