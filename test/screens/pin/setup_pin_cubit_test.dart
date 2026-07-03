import 'dart:async';
import 'dart:typed_data';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:realunit_wallet/packages/service/biometric/biometric_auth_outcome.dart';
import 'package:realunit_wallet/packages/service/biometric_service.dart';
import 'package:realunit_wallet/packages/storage/secure_storage.dart';
import 'package:realunit_wallet/screens/pin/bloc/setup_pin/setup_pin_cubit.dart';

class _MockSecureStorage extends Mock implements SecureStorage {}

class _MockBiometricService extends Mock implements BiometricService {}

void main() {
  late _MockSecureStorage secureStorage;
  late _MockBiometricService biometricService;

  setUpAll(() {
    // Uint8List is a restricted type; a Fake subclass is illegal, but mocktail
    // accepts a concrete instance as the registered fallback.
    registerFallbackValue(Uint8List(0));
  });

  setUp(() {
    secureStorage = _MockSecureStorage();
    biometricService = _MockBiometricService();
    // The confirmed PIN is now persisted as one atomic salt+hash credential.
    when(() => secureStorage.setPinCredential(any(), any())).thenAnswer((_) async {});
  });

  SetupPinCubit build() => SetupPinCubit(secureStorage, biometricService);

  group('$SetupPinCubit', () {
    test('initial state is create mode, empty pin, no mismatch, not complete', () {
      final cubit = build();

      expect(cubit.state.mode, SetupPinMode.create);
      expect(cubit.state.currentPin, '');
      expect(cubit.state.mismatch, isFalse);
      expect(cubit.state.isComplete, isFalse);
    });

    blocTest<SetupPinCubit, SetupPinState>(
      'addDigit appends a digit to the current pin',
      build: build,
      act: (cubit) {
        cubit.addDigit(1);
        cubit.addDigit(2);
      },
      expect: () => [
        const SetupPinState(currentPin: '1'),
        const SetupPinState(currentPin: '12'),
      ],
    );

    blocTest<SetupPinCubit, SetupPinState>(
      'addDigit ignored when the pin is already 6 digits long',
      build: build,
      seed: () => const SetupPinState(currentPin: '123456'),
      act: (cubit) => cubit.addDigit(7),
      expect: () => [],
    );

    blocTest<SetupPinCubit, SetupPinState>(
      'deleteDigit drops the last character and clears mismatch',
      build: build,
      seed: () => const SetupPinState(currentPin: '12', mismatch: true),
      act: (cubit) => cubit.deleteDigit(),
      expect: () => [const SetupPinState(currentPin: '1')],
    );

    blocTest<SetupPinCubit, SetupPinState>(
      'deleteDigit on an empty pin is a no-op',
      build: build,
      act: (cubit) => cubit.deleteDigit(),
      expect: () => [],
    );

    test('completing 6 digits in create mode switches to confirm with an empty pin', () async {
      final cubit = build();

      for (final d in [1, 2, 3, 4, 5, 6]) {
        cubit.addDigit(d);
      }

      expect(cubit.state.mode, SetupPinMode.confirm);
      expect(cubit.state.currentPin, '');
      expect(cubit.state.isComplete, isFalse);
    });

    test('matching confirm-pin persists the atomic credential and emits isComplete=true',
        () async {
      final cubit = build();
      // The cubit's stream is broadcast and does not replay past events —
      // subscribe BEFORE driving the digits so we don't race the emit.
      final completed = cubit.stream.firstWhere((s) => s.isComplete);

      for (final d in [1, 2, 3, 4, 5, 6]) {
        cubit.addDigit(d);
      }
      for (final d in [1, 2, 3, 4, 5, 6]) {
        cubit.addDigit(d);
      }
      // _onPinComplete fires _confirmPin without awaiting; PBKDF2 with
      // 250k iterations runs via `compute()`. On a Flutter-test isolate
      // shim this can take several seconds — generous timeout.
      await completed.timeout(const Duration(seconds: 30));

      expect(cubit.state.isComplete, isTrue);
      // One atomic write.
      verify(() => secureStorage.setPinCredential(any(), any())).called(1);
    });

    test('mismatching confirm-pin resets currentPin and sets mismatch=true', () async {
      final cubit = build();
      final mismatched = cubit.stream.firstWhere((s) => s.mismatch);

      for (final d in [1, 2, 3, 4, 5, 6]) {
        cubit.addDigit(d);
      }
      for (final d in [9, 9, 9, 9, 9, 9]) {
        cubit.addDigit(d);
      }
      await mismatched.timeout(const Duration(seconds: 1));

      expect(cubit.state.mismatch, isTrue);
      expect(cubit.state.currentPin, '');
      expect(cubit.state.isComplete, isFalse);
      verifyNever(() => secureStorage.setPinCredential(any(), any()));
    });

    test('confirming flips isSubmitting on during hashing and off on completion', () async {
      final cubit = build();
      final submitting = cubit.stream.firstWhere((s) => s.isSubmitting);
      final completed = cubit.stream.firstWhere((s) => s.isComplete);

      for (final d in [1, 2, 3, 4, 5, 6]) {
        cubit.addDigit(d);
      }
      for (final d in [1, 2, 3, 4, 5, 6]) {
        cubit.addDigit(d);
      }

      final submittingState = await submitting.timeout(const Duration(seconds: 30));
      expect(submittingState.isSubmitting, isTrue);
      expect(submittingState.isComplete, isFalse);

      final completedState = await completed.timeout(const Duration(seconds: 30));
      expect(completedState.isSubmitting, isFalse);
      expect(completedState.isComplete, isTrue);
    });

    test('a delete+retype race during the write persists the credential exactly once (F-09)',
        () async {
      // Gate the atomic write so it stays in flight (isSubmitting == true) while
      // we fire the race — deterministic, no wall-clock delay. `writeStarted`
      // fires the moment _confirmPin reaches the write, i.e. past the real
      // PBKDF2 hash, so we know the in-flight window is open.
      final writeGate = Completer<void>();
      final writeStarted = Completer<void>();
      when(() => secureStorage.setPinCredential(any(), any())).thenAnswer((_) async {
        if (!writeStarted.isCompleted) writeStarted.complete();
        await writeGate.future;
      });

      final cubit = build();
      final completed = cubit.stream.firstWhere((s) => s.isComplete);

      for (final d in [1, 2, 3, 4, 5, 6]) {
        cubit.addDigit(d);
      }
      for (final d in [1, 2, 3, 4, 5, 6]) {
        cubit.addDigit(d);
      }

      // Wait until the credential write is actually in flight.
      await writeStarted.future.timeout(const Duration(seconds: 30));

      // While the write is suspended, fire the real race the guard exists for:
      // delete the last digit and retype it. On the unguarded code delete would
      // step back past the length guard and the retype would spawn a SECOND
      // concurrent _confirmPin (a second write); the isSubmitting guard must drop
      // both so the credential is written exactly once.
      cubit.deleteDigit();
      cubit.addDigit(6);
      // Flush any microtasks the blocked re-entry might have scheduled instead of
      // waiting on the wall clock.
      await pumpEventQueue();

      // The blocked delete/retype must leave the completing pin untouched.
      expect(cubit.state.currentPin, '123456');

      // Release the gated write so the single _confirmPin completes.
      writeGate.complete();
      await completed.timeout(const Duration(seconds: 30));

      expect(cubit.state.isComplete, isTrue);
      verify(() => secureStorage.setPinCredential(any(), any())).called(1);
    });

    test('a storage write failure returns to a usable pad with a retry hint', () async {
      when(() => secureStorage.setPinCredential(any(), any()))
          .thenThrow(Exception('keychain unavailable'));
      final cubit = build();
      final failed = cubit.stream.firstWhere((s) => s.storeFailed);

      for (final d in [1, 2, 3, 4, 5, 6]) {
        cubit.addDigit(d);
      }
      for (final d in [1, 2, 3, 4, 5, 6]) {
        cubit.addDigit(d);
      }
      await failed.timeout(const Duration(seconds: 30));

      // Must not strand the user on the spinner: pad returns, error surfaced.
      expect(cubit.state.isSubmitting, isFalse);
      expect(cubit.state.storeFailed, isTrue);
      expect(cubit.state.currentPin, '');
      expect(cubit.state.isComplete, isFalse);
    });

    blocTest<SetupPinCubit, SetupPinState>(
      'addDigit ignored while submitting',
      build: build,
      seed: () => const SetupPinState(
        mode: SetupPinMode.confirm,
        currentPin: '12',
        isSubmitting: true,
      ),
      act: (cubit) => cubit.addDigit(3),
      expect: () => [],
    );

    blocTest<SetupPinCubit, SetupPinState>(
      'deleteDigit ignored while submitting',
      build: build,
      seed: () => const SetupPinState(
        mode: SetupPinMode.confirm,
        currentPin: '12',
        isSubmitting: true,
      ),
      act: (cubit) => cubit.deleteDigit(),
      expect: () => [],
    );

    blocTest<SetupPinCubit, SetupPinState>(
      'reset returns to the initial state',
      build: build,
      seed: () => const SetupPinState(
        mode: SetupPinMode.confirm,
        currentPin: '123',
        mismatch: true,
      ),
      act: (cubit) => cubit.reset(),
      expect: () => [const SetupPinState()],
    );

    test('isBiometricAvailable delegates to BiometricService.isAvailable', () async {
      when(() => biometricService.isAvailable()).thenAnswer((_) async => true);

      final result = await build().isBiometricAvailable();

      expect(result, isTrue);
      verify(() => biometricService.isAvailable()).called(1);
    });

    test('enableBiometrics delegates to BiometricService.enable', () async {
      when(() => biometricService.enable())
          .thenAnswer((_) async => BiometricAuthOutcome.success);

      final result = await build().enableBiometrics();

      expect(result, BiometricAuthOutcome.success);
      verify(() => biometricService.enable()).called(1);
    });
  });
}
