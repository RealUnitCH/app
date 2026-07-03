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
    when(() => secureStorage.setPinSalt(any())).thenAnswer((_) async {});
    when(() => secureStorage.setPinHash(any())).thenAnswer((_) async {});
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

    test('matching confirm-pin persists salt + hash and emits isComplete=true', () async {
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
      // 600k iterations runs via `compute()`. On a Flutter-test isolate
      // shim this can take several seconds — generous timeout.
      await completed.timeout(const Duration(seconds: 30));

      expect(cubit.state.isComplete, isTrue);
      verify(() => secureStorage.setPinSalt(any())).called(1);
      verify(() => secureStorage.setPinHash(any())).called(1);
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
      verifyNever(() => secureStorage.setPinSalt(any()));
      verifyNever(() => secureStorage.setPinHash(any()));
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

    test('a delete+retype race during hashing writes the salt/hash pair exactly once (F-09)',
        () async {
      final cubit = build();
      final completed = cubit.stream.firstWhere((s) => s.isComplete);

      for (final d in [1, 2, 3, 4, 5, 6]) {
        cubit.addDigit(d);
      }
      for (final d in [1, 2, 3, 4, 5]) {
        cubit.addDigit(d);
      }
      // Complete the pin, then — while _confirmPin is suspended at the PBKDF2
      // hash — fire the real race the guard exists for: delete the last digit
      // and retype it. On the unguarded code delete would step back past the
      // length guard and the retype would spawn a SECOND concurrent _confirmPin
      // (a second write pair); the isSubmitting guard must drop both so the pair
      // is written exactly once.
      cubit.addDigit(6);
      cubit.deleteDigit();
      cubit.addDigit(6);
      // The blocked delete/retype must leave the completing pin untouched.
      expect(cubit.state.currentPin, '123456');
      await completed.timeout(const Duration(seconds: 30));
      // Let any erroneously-spawned second write settle before asserting once.
      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(cubit.state.isComplete, isTrue);
      verify(() => secureStorage.setPinSalt(any())).called(1);
      verify(() => secureStorage.setPinHash(any())).called(1);
    });

    test('a storage write failure returns to a usable pad with a retry hint', () async {
      when(() => secureStorage.setPinHash(any())).thenThrow(Exception('keychain unavailable'));
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
