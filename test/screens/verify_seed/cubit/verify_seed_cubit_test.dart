import 'dart:async';

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
      expect(cubit.state.isVerifying, isFalse);
      expect(cubit.state.hasError, isFalse);
      expect(cubit.state.commitFailed, isFalse);
      // The current wallet id must be the COMMITTED id (42), not the
      // uncommitted draft's `0` sentinel. Closes the regression where a
      // future refactor passes `_wallet.id` directly to `setCurrentWallet`
      // and silently routes onboarding to a non-existent wallet row.
      verify(() => service.setCurrentWallet(42)).called(1);
      verifyNever(() => service.setCurrentWallet(0));
    });

    test('verify exposes the COMMITTED wallet on the success state', () async {
      // The success state must carry the committed wallet so the page can
      // pass it to `LoadWalletEvent` — `HomeBloc` needs the real row (and
      // sets `hasWallet: true`) to route onboarding forward instead of
      // looping back to welcome.
      final cubit = VerifySeedCubit(wallet, service);

      await cubit.verify();

      expect(cubit.state.committedWallet, isNotNull);
      expect(cubit.state.committedWallet!.id, 42);
      expect(cubit.state.committedWallet!.id, isNot(0));
    });

    test('verify emits isVerifying before resolving to isVerified', () async {
      final cubit = VerifySeedCubit(wallet, service);
      final verifyingSeen = <bool>[];
      final sub = cubit.stream.listen((s) => verifyingSeen.add(s.isVerifying));

      await cubit.verify();
      await Future<void>.delayed(Duration.zero);
      await sub.cancel();

      // The in-progress flag must be raised at least once so the button can
      // surface a loading indicator and disable a second tap.
      expect(verifyingSeen, contains(true));
      expect(cubit.state.isVerifying, isFalse);
      expect(cubit.state.isVerified, isTrue);
    });

    test('verify calls commitGeneratedWallet and setCurrentWallet exactly once on success',
        () async {
      final cubit = VerifySeedCubit(wallet, service);

      await cubit.verify();

      verify(() => service.commitGeneratedWallet(any())).called(1);
      verify(() => service.setCurrentWallet(any())).called(1);
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
      expect(cubit.state.commitFailed, isFalse);
      // No committed wallet leaks onto a failed state — `committedWallet`
      // is only ever set together with `isVerified: true`.
      expect(cubit.state.committedWallet, isNull);
      // The disk-side guarantee for failure paths: no `walletInfos` row
      // is written for a rejected verification. Pairs with the
      // CreateWalletCubit "zero commits across regenerates" pin.
      verifyNever(() => service.commitGeneratedWallet(any()));
      verifyNever(() => service.setCurrentWallet(any()));
    });

    test('verify ends in commitFailed (NOT hung, NOT verified) when the commit throws',
        () async {
      // The bug this guards: a throwing/hanging commit used to leave the
      // cubit emitting neither isVerified nor an error — the verify-seed
      // screen stuck forever with no feedback and no retry.
      when(() => service.commitGeneratedWallet(any()))
          .thenThrow(StateError('disk write failed'));

      final cubit = VerifySeedCubit(wallet, service);
      final result = await cubit.verify();

      expect(result, isFalse);
      expect(cubit.state.commitFailed, isTrue);
      expect(cubit.state.isVerifying, isFalse);
      expect(cubit.state.isVerified, isFalse);
      // A failed commit carries no committed wallet.
      expect(cubit.state.committedWallet, isNull);
      verifyNever(() => service.setCurrentWallet(any()));
    });

    test('verify ends in commitFailed when setCurrentWallet throws after a successful commit',
        () async {
      when(() => service.setCurrentWallet(any()))
          .thenThrow(StateError('settings write failed'));

      final cubit = VerifySeedCubit(wallet, service);
      final result = await cubit.verify();

      expect(result, isFalse);
      expect(cubit.state.commitFailed, isTrue);
      expect(cubit.state.isVerifying, isFalse);
      expect(cubit.state.isVerified, isFalse);
    });

    test('verify is re-entrancy-safe: a second rapid call commits exactly once',
        () async {
      // Make the commit slow so the second `verify()` lands while the first
      // is still in flight. A second commit would also trip
      // `commitGeneratedWallet`'s `assert(draft.id == 0)`.
      final completer = Completer<SoftwareWallet>();
      when(() => service.commitGeneratedWallet(any()))
          .thenAnswer((_) => completer.future);

      final cubit = VerifySeedCubit(wallet, service);
      final first = cubit.verify();
      final second = cubit.verify(); // re-entrant — must bail out immediately

      completer.complete(SoftwareWallet(42, 'Main', _testMnemonic));
      final results = await Future.wait([first, second]);

      expect(results, [true, false]);
      verify(() => service.commitGeneratedWallet(any())).called(1);
      verify(() => service.setCurrentWallet(any())).called(1);
      expect(cubit.state.isVerified, isTrue);
    });

    test('verify is a no-op once already verified', () async {
      final cubit = VerifySeedCubit(wallet, service);
      await cubit.verify();
      expect(cubit.state.isVerified, isTrue);

      final result = await cubit.verify();

      expect(result, isFalse);
      // No second commit — that would hit the already-committed-draft assert.
      verify(() => service.commitGeneratedWallet(any())).called(1);
    });

    test('retrying after commitFailed succeeds and clears the failure flag',
        () async {
      var attempts = 0;
      when(() => service.commitGeneratedWallet(any())).thenAnswer((_) async {
        attempts++;
        if (attempts == 1) throw StateError('transient disk failure');
        return SoftwareWallet(42, 'Main', _testMnemonic);
      });

      final cubit = VerifySeedCubit(wallet, service);

      final first = await cubit.verify();
      expect(first, isFalse);
      expect(cubit.state.commitFailed, isTrue);
      expect(cubit.state.isVerified, isFalse);

      // Retry — the re-entrancy guard allows it (not verifying, not verified)
      // and the `commitFailed` flag is reset at the start of the attempt.
      final second = await cubit.verify();

      expect(second, isTrue);
      expect(cubit.state.commitFailed, isFalse);
      expect(cubit.state.isVerified, isTrue);
      verify(() => service.commitGeneratedWallet(any())).called(2);
    });

    test('verify does not emit after the cubit is closed mid-commit',
        () async {
      // The AppBar back button stays enabled on the verify-seed page while
      // the commit is in flight, so the cubit can be closed before
      // `commitGeneratedWallet` resolves. A post-close `emit` would throw
      // `StateError` — the same async-tail bug `create_wallet_cubit` /
      // `connect_bitbox_cubit` / `kyc_cubit` guard against with `isClosed`.
      final completer = Completer<SoftwareWallet>();
      when(() => service.commitGeneratedWallet(any()))
          .thenAnswer((_) => completer.future);

      final cubit = VerifySeedCubit(wallet, service);
      final pending = cubit.verify();

      await cubit.close();
      completer.complete(SoftwareWallet(42, 'Main', _testMnemonic));
      final result = await pending;

      // No StateError thrown from the post-close emit path, and
      // setCurrentWallet is skipped once the cubit is closed.
      expect(result, isFalse);
      verifyNever(() => service.setCurrentWallet(any()));
    });

    test('verify does not emit when the cubit is closed between commit and setCurrentWallet',
        () async {
      // Cover the second async boundary too: `setCurrentWallet` is awaited
      // *after* a successful commit. If the user pops the page during that
      // gap, the success emission must be skipped — not throw.
      final commitDone = Completer<SoftwareWallet>();
      final setCurrentStarted = Completer<void>();
      final setCurrentFinish = Completer<void>();
      when(() => service.commitGeneratedWallet(any()))
          .thenAnswer((_) => commitDone.future);
      when(() => service.setCurrentWallet(any())).thenAnswer((_) {
        setCurrentStarted.complete();
        return setCurrentFinish.future;
      });

      final cubit = VerifySeedCubit(wallet, service);
      final pending = cubit.verify();
      commitDone.complete(SoftwareWallet(42, 'Main', _testMnemonic));
      await setCurrentStarted.future;

      // Close the cubit while `setCurrentWallet` is still pending — the
      // success `emit` that follows must be skipped.
      await cubit.close();
      setCurrentFinish.complete();
      final result = await pending;

      expect(result, isFalse);
    });
  });
}
