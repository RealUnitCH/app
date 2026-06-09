import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:realunit_wallet/packages/service/wallet_service.dart';
import 'package:realunit_wallet/packages/wallet/wallet.dart';
import 'package:realunit_wallet/screens/verify_seed/cubit/verify_seed_cubit.dart';

import '../../../test_utils/fake_wallet_isolate.dart';

class _MockWalletService extends Mock implements WalletService {}

const _testMnemonic = 'test test test test test test test test test test test junk';
const _hardhatZero = '0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266';

SoftwareWallet _committedWallet({int id = 42, String name = 'Main'}) =>
    SoftwareWallet(id, name, _hardhatZero, FakeWalletIsolate());

void main() {
  late _MockWalletService service;
  late SeedDraft draft;

  setUpAll(() {
    registerFallbackValue(SeedDraft('fallback fallback fallback fallback'));
  });

  setUp(() {
    service = _MockWalletService();
    draft = SeedDraft(_testMnemonic, name: 'Main');
    when(() => service.setCurrentWallet(any())).thenAnswer((_) async {});
    when(() => service.commitGeneratedWallet(any())).thenAnswer(
      (_) async => _committedWallet(),
    );
  });

  group('$VerifySeedCubit', () {
    test('picks 4 distinct ascending word indices within seed length on init', () {
      final cubit = VerifySeedCubit(draft, service);

      expect(cubit.state.wordIndices, hasLength(4));
      // distinct
      expect(cubit.state.wordIndices.toSet().length, 4);
      // ascending
      final sorted = [...cubit.state.wordIndices]..sort();
      expect(cubit.state.wordIndices, sorted);
      // within bounds
      for (final i in cubit.state.wordIndices) {
        expect(i, inInclusiveRange(0, draft.seedWords.length - 1));
      }
    });

    test('initial enteredWords are populated in debug mode (4 entries non-empty)', () {
      // `kDebugMode` is true under `flutter test`, so the cubit pre-fills.
      final cubit = VerifySeedCubit(draft, service);

      expect(cubit.state.enteredWords, hasLength(4));
      expect(cubit.state.enteredWords.every((w) => w.isNotEmpty), isTrue);
    });

    test('constructing with an already disposed draft aborts immediately', () {
      draft.dispose();

      final cubit = VerifySeedCubit(draft, service);

      expect(cubit.state.aborted, isTrue);
      expect(cubit.state.wordIndices, isEmpty);
    });

    test('canVerify reflects whether all four slots are filled', () {
      final cubit = VerifySeedCubit(draft, service);

      // Debug-mode pre-fill leaves canVerify == true. Clear one to flip it.
      cubit.updateWord(0, '');
      expect(cubit.state.canVerify, isFalse);

      cubit.updateWord(0, 'anything');
      expect(cubit.state.canVerify, isTrue);
    });

    test(
      'verify returns true and marks the COMMITTED wallet current when all words match',
      () async {
        final cubit = VerifySeedCubit(draft, service);

        final result = await cubit.verify();

        expect(result, isTrue);
        expect(cubit.state.isVerified, isTrue);
        expect(cubit.state.isVerifying, isFalse);
        expect(cubit.state.hasError, isFalse);
        expect(cubit.state.commitFailed, isFalse);
        // The current wallet id must be the COMMITTED id (42), not 0.
        verify(() => service.setCurrentWallet(42)).called(1);
        verifyNever(() => service.setCurrentWallet(0));
      },
    );

    test('verify exposes the COMMITTED wallet on the success state', () async {
      final cubit = VerifySeedCubit(draft, service);

      await cubit.verify();

      expect(cubit.state.committedWallet, isNotNull);
      expect(cubit.state.committedWallet!.id, 42);
    });

    test(
      'verify calls commitGeneratedWallet and setCurrentWallet exactly once on success',
      () async {
        final cubit = VerifySeedCubit(draft, service);

        await cubit.verify();

        verify(() => service.commitGeneratedWallet(any())).called(1);
        verify(() => service.setCurrentWallet(any())).called(1);
      },
    );

    test('verify commits the draft BEFORE marking it current', () async {
      final calls = <String>[];
      when(() => service.commitGeneratedWallet(any())).thenAnswer((inv) async {
        calls.add('commit');
        return _committedWallet(id: 99);
      });
      when(() => service.setCurrentWallet(any())).thenAnswer((inv) async {
        calls.add('setCurrent(${inv.positionalArguments.single})');
      });

      final cubit = VerifySeedCubit(draft, service);
      await cubit.verify();

      expect(
        calls,
        ['commit', 'setCurrent(99)'],
        reason:
            'commit must land the row before `setCurrentWallet` points '
            'the settings repository at it',
      );
    });

    test('verify returns false, sets hasError, and does NOT commit on a wrong word', () async {
      final cubit = VerifySeedCubit(draft, service);
      cubit.updateWord(0, 'definitely-not-a-seed-word');

      final result = await cubit.verify();

      expect(result, isFalse);
      expect(cubit.state.hasError, isTrue);
      expect(cubit.state.isVerified, isFalse);
      expect(cubit.state.commitFailed, isFalse);
      expect(cubit.state.committedWallet, isNull);
      verifyNever(() => service.commitGeneratedWallet(any()));
      verifyNever(() => service.setCurrentWallet(any()));
    });

    test('verify ends in commitFailed (NOT hung, NOT verified) when the commit throws', () async {
      when(() => service.commitGeneratedWallet(any())).thenThrow(StateError('disk write failed'));

      final cubit = VerifySeedCubit(draft, service);
      final result = await cubit.verify();

      expect(result, isFalse);
      expect(cubit.state.commitFailed, isTrue);
      expect(cubit.state.isVerifying, isFalse);
      expect(cubit.state.isVerified, isFalse);
      expect(cubit.state.committedWallet, isNull);
      verifyNever(() => service.setCurrentWallet(any()));
    });

    test(
      'verify ends in commitFailed when setCurrentWallet throws after a successful commit',
      () async {
        when(() => service.setCurrentWallet(any())).thenThrow(StateError('settings write failed'));

        final cubit = VerifySeedCubit(draft, service);
        final result = await cubit.verify();

        expect(result, isFalse);
        expect(cubit.state.commitFailed, isTrue);
        expect(cubit.state.isVerifying, isFalse);
        expect(cubit.state.isVerified, isFalse);
      },
    );

    test('verify is re-entrancy-safe: a second rapid call commits exactly once', () async {
      // Make the commit slow so the second `verify()` lands while the first
      // is still in flight.
      final completer = Completer<SoftwareWallet>();
      when(() => service.commitGeneratedWallet(any())).thenAnswer((_) => completer.future);

      final cubit = VerifySeedCubit(draft, service);
      final first = cubit.verify();
      final second = cubit.verify(); // re-entrant — must bail out immediately

      completer.complete(_committedWallet());
      final results = await Future.wait([first, second]);

      expect(results, [true, false]);
      verify(() => service.commitGeneratedWallet(any())).called(1);
      verify(() => service.setCurrentWallet(any())).called(1);
      expect(cubit.state.isVerified, isTrue);
    });

    test('verify is a no-op once already verified', () async {
      final cubit = VerifySeedCubit(draft, service);
      await cubit.verify();
      expect(cubit.state.isVerified, isTrue);

      final result = await cubit.verify();

      expect(result, isFalse);
      verify(() => service.commitGeneratedWallet(any())).called(1);
    });

    test('verify does not emit after the cubit is closed mid-commit', () async {
      final completer = Completer<SoftwareWallet>();
      when(() => service.commitGeneratedWallet(any())).thenAnswer((_) => completer.future);

      final cubit = VerifySeedCubit(draft, service);
      final pending = cubit.verify();

      await cubit.close();
      completer.complete(_committedWallet());
      final result = await pending;

      expect(result, isFalse);
      verifyNever(() => service.setCurrentWallet(any()));
    });

    group('lifecycle / BL-023', () {
      // Pre-Initiative-IV the cubit had no `WidgetsBindingObserver`,
      // so backgrounding the app left the mnemonic in memory for the
      // full duration of the verify-seed screen. BL-023 wires a
      // lifecycle observer that disposes the draft on `hidden`.

      testWidgets('hidden mid-verify disposes the draft and emits aborted', (tester) async {
        final cubit = VerifySeedCubit(draft, service);
        expect(cubit.state.aborted, isFalse);
        expect(draft.isDisposed, isFalse);

        // Simulate the platform-channel notification that drives
        // WidgetsBindingObserver. `pumpFrames` flushes any pending
        // microtask so the emit from the observer is observed.
        tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
        await tester.pump();

        expect(
          draft.isDisposed,
          isTrue,
          reason:
              'BL-023: backgrounded mid-verify must dispose the draft '
              'within one event-loop turn so the mnemonic is not in the '
              'iOS app-suspend snapshot',
        );
        expect(
          cubit.state.aborted,
          isTrue,
          reason:
              'the cubit must surface an aborted state so the view '
              'can route back to the create-wallet entry point on resume',
        );

        await cubit.close();
      });

      testWidgets('paused (after hidden on platforms that emit both) disposes too', (tester) async {
        final cubit = VerifySeedCubit(draft, service);

        tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
        await tester.pump();

        expect(draft.isDisposed, isTrue);
        expect(cubit.state.aborted, isTrue);

        await cubit.close();
      });

      test('verify on an aborted cubit short-circuits without commit', () async {
        final cubit = VerifySeedCubit(draft, service);
        // Force the aborted state via dispose.
        draft.dispose();

        final result = await cubit.verify();

        expect(result, isFalse);
        expect(cubit.state.aborted, isTrue);
        verifyNever(() => service.commitGeneratedWallet(any()));
      });

      test('close() disposes the draft even without an explicit lifecycle event', () async {
        final cubit = VerifySeedCubit(draft, service);
        expect(draft.isDisposed, isFalse);

        await cubit.close();

        expect(
          draft.isDisposed,
          isTrue,
          reason:
              'navigation away (close()) must also drop the mnemonic — '
              'lifecycle events only fire on app-level transitions',
        );
      });
    });
  });
}
