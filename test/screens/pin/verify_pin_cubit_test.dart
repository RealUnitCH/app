import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:realunit_wallet/packages/service/biometric/biometric_auth_outcome.dart';
import 'package:realunit_wallet/packages/service/biometric_service.dart';
import 'package:realunit_wallet/packages/storage/secure_storage.dart';
import 'package:realunit_wallet/screens/pin/bloc/verify_pin/verify_pin_cubit.dart';
import 'package:realunit_wallet/screens/pin/constants/pin_constants.dart';

class _MockSecureStorage extends Mock implements SecureStorage {}

class _MockBiometricService extends Mock implements BiometricService {}

void main() {
  late _MockSecureStorage secureStorage;
  late _MockBiometricService biometricService;

  setUpAll(() {
    registerFallbackValue(DateTime(2026));
  });

  setUp(() {
    secureStorage = _MockSecureStorage();
    biometricService = _MockBiometricService();
    when(() => secureStorage.resetPinLockout()).thenAnswer((_) async {});
    when(() => secureStorage.setPinFailedAttempts(any())).thenAnswer((_) async {});
    when(() => secureStorage.setPinLockedUntil(any())).thenAnswer((_) async {});
    when(() => secureStorage.getPinFailedAttempts()).thenAnswer((_) async => 0);
    when(() => secureStorage.getPinLockedUntil()).thenAnswer((_) async => null);
    // Biometrics off by default; each biometric test opts in explicitly.
    when(() => biometricService.isEnabled()).thenAnswer((_) async => false);
    when(() => biometricService.isAvailable()).thenAnswer((_) async => false);
    when(() => biometricService.authenticate())
        .thenAnswer((_) async => BiometricAuthOutcome.failed);
  });

  VerifyPinCubit build({bool enableLockout = true}) => VerifyPinCubit(
        secureStorage,
        biometricService,
        enableLockout: enableLockout,
      );

  void addPin(VerifyPinCubit cubit, String pin) {
    for (final c in pin.split('')) {
      cubit.addDigit(int.parse(c));
    }
  }

  group('$VerifyPinCubit', () {
    test('initial state is empty pin, zero failed attempts, unknown biometrics', () {
      final cubit = build();

      expect(cubit.state.pin, '');
      expect(cubit.state.failedAttempts, 0);
      expect(cubit.state.biometricStatus, BiometricStatus.unknown);
    });

    group('digit input', () {
      blocTest<VerifyPinCubit, VerifyPinState>(
        'addDigit appends to the pin',
        build: build,
        act: (cubit) {
          cubit.addDigit(1);
          cubit.addDigit(2);
        },
        expect: () => [
          const VerifyPinState(pin: '1'),
          const VerifyPinState(pin: '12'),
        ],
      );

      blocTest<VerifyPinCubit, VerifyPinState>(
        'deleteDigit removes the last character',
        build: build,
        seed: () => const VerifyPinState(pin: '123'),
        act: (cubit) => cubit.deleteDigit(),
        expect: () => [const VerifyPinState(pin: '12')],
      );

      blocTest<VerifyPinCubit, VerifyPinState>(
        'deleteDigit on empty pin is a no-op',
        build: build,
        act: (cubit) => cubit.deleteDigit(),
        expect: () => [],
      );

      blocTest<VerifyPinCubit, VerifyPinState>(
        'addDigit ignored while temporarily locked',
        build: build,
        seed: () => VerifyPinTemporarilyLocked(
          failedAttempts: 5,
          lockedUntil: DateTime(2030),
        ),
        act: (cubit) => cubit.addDigit(1),
        expect: () => [],
      );

      blocTest<VerifyPinCubit, VerifyPinState>(
        'addDigit ignored while permanently locked',
        build: build,
        seed: () => const VerifyPinLocked(failedAttempts: 9),
        act: (cubit) => cubit.addDigit(1),
        expect: () => [],
      );

      blocTest<VerifyPinCubit, VerifyPinState>(
        'addDigit ignored while unverifiable',
        build: build,
        seed: () => const VerifyPinUnverifiable(),
        act: (cubit) => cubit.addDigit(1),
        expect: () => [],
      );

      blocTest<VerifyPinCubit, VerifyPinState>(
        'deleteDigit ignored while unverifiable',
        build: build,
        seed: () => const VerifyPinUnverifiable(),
        act: (cubit) => cubit.deleteDigit(),
        expect: () => [],
      );
    });

    group('checkPin (auto-triggered after 6 digits)', () {
      test('correct pin resets lockout counter and emits VerifyPinSuccess', () async {
        when(() => secureStorage.verifyPin(any()))
            .thenAnswer((_) async => PinVerificationResult.correct);
        final cubit = build();
        final success = cubit.stream.firstWhere((s) => s is VerifyPinSuccess);

        addPin(cubit, '123456');
        await success.timeout(const Duration(seconds: 30));

        expect(cubit.state, isA<VerifyPinSuccess>());
        verify(() => secureStorage.resetPinLockout()).called(1);
      });

      blocTest<VerifyPinCubit, VerifyPinState>(
        'emits VerifyPinVerifying (carrying the full pin) before VerifyPinSuccess',
        build: build,
        setUp: () => when(() => secureStorage.verifyPin(any()))
            .thenAnswer((_) async => PinVerificationResult.correct),
        act: (cubit) => addPin(cubit, '123456'),
        expect: () => [
          const VerifyPinState(pin: '1'),
          const VerifyPinState(pin: '12'),
          const VerifyPinState(pin: '123'),
          const VerifyPinState(pin: '1234'),
          const VerifyPinState(pin: '12345'),
          const VerifyPinState(pin: '123456'),
          const VerifyPinVerifying(pin: '123456'),
          const VerifyPinSuccess(),
        ],
      );

      test('wrong pin (1st attempt) with lockout on emits VerifyPinFailure', () async {
        when(() => secureStorage.verifyPin(any()))
            .thenAnswer((_) async => PinVerificationResult.wrong);
        when(() => secureStorage.getPinFailedAttempts()).thenAnswer((_) async => 0);
        final cubit = build();
        final failure = cubit.stream.firstWhere((s) => s is VerifyPinFailure);

        addPin(cubit, '999999');
        await failure.timeout(const Duration(seconds: 30));

        expect(cubit.state, isA<VerifyPinFailure>());
        expect((cubit.state as VerifyPinFailure).failedAttempts, 1);
        verify(() => secureStorage.setPinFailedAttempts(1)).called(1);
        verifyNever(() => secureStorage.setPinLockedUntil(any()));
      });

      test('wrong pin with lockout disabled never persists attempts', () async {
        when(() => secureStorage.verifyPin(any()))
            .thenAnswer((_) async => PinVerificationResult.wrong);
        final cubit = build(enableLockout: false);
        final failure = cubit.stream.firstWhere((s) => s is VerifyPinFailure);

        addPin(cubit, '999999');
        await failure.timeout(const Duration(seconds: 30));

        expect(cubit.state, isA<VerifyPinFailure>());
        expect((cubit.state as VerifyPinFailure).failedAttempts, 0);
        verifyNever(() => secureStorage.getPinFailedAttempts());
        verifyNever(() => secureStorage.setPinFailedAttempts(any()));
      });

      test('5th wrong attempt triggers a 1-minute temporary lockout', () async {
        when(() => secureStorage.verifyPin(any()))
            .thenAnswer((_) async => PinVerificationResult.wrong);
        when(() => secureStorage.getPinFailedAttempts()).thenAnswer((_) async => 4);
        final cubit = build();
        final locked = cubit.stream.firstWhere((s) => s is VerifyPinTemporarilyLocked);

        addPin(cubit, '999999');
        await locked.timeout(const Duration(seconds: 30));

        expect(cubit.state, isA<VerifyPinTemporarilyLocked>());
        expect(cubit.state.failedAttempts, 5);
        verify(() => secureStorage.setPinFailedAttempts(5)).called(1);
        verify(() => secureStorage.setPinLockedUntil(any())).called(1);
      });

      test('reaching permanentLockoutThreshold emits VerifyPinLocked', () async {
        when(() => secureStorage.verifyPin(any()))
            .thenAnswer((_) async => PinVerificationResult.wrong);
        when(() => secureStorage.getPinFailedAttempts())
            .thenAnswer((_) async => permanentLockoutThreshold - 1);
        final cubit = build();
        final locked = cubit.stream.firstWhere((s) => s is VerifyPinLocked);

        addPin(cubit, '999999');
        await locked.timeout(const Duration(seconds: 30));

        expect(cubit.state, isA<VerifyPinLocked>());
        expect(cubit.state.failedAttempts, permanentLockoutThreshold);
        verify(() => secureStorage.setPinFailedAttempts(permanentLockoutThreshold)).called(1);
        verifyNever(() => secureStorage.setPinLockedUntil(any()));
      });

      test('notVerifiable emits VerifyPinUnverifiable and counts no attempt', () async {
        when(() => secureStorage.verifyPin(any()))
            .thenAnswer((_) async => PinVerificationResult.notVerifiable);
        final cubit = build();
        final unverifiable = cubit.stream.firstWhere((s) => s is VerifyPinUnverifiable);

        addPin(cubit, '123456');
        await unverifiable.timeout(const Duration(seconds: 30));

        expect(cubit.state, isA<VerifyPinUnverifiable>());
        // Storage fault must never touch the lockout counter.
        verifyNever(() => secureStorage.getPinFailedAttempts());
        verifyNever(() => secureStorage.setPinFailedAttempts(any()));
        verifyNever(() => secureStorage.setPinLockedUntil(any()));
      });

      test('concurrent checkPin calls coalesce to a single counter increment (F-01)', () async {
        // Gate the verification so a second checkPin arrives while the first is
        // still in flight — the guard must fold it onto the same round-trip.
        final gate = Completer<PinVerificationResult>();
        when(() => secureStorage.verifyPin(any())).thenAnswer((_) => gate.future);
        when(() => secureStorage.getPinFailedAttempts()).thenAnswer((_) async => 0);
        final cubit = build();
        final failure = cubit.stream.firstWhere((s) => s is VerifyPinFailure);

        addPin(cubit, '999999'); // 6th digit fires the first checkPin (awaiting gate)
        final second = cubit.checkPin(); // must coalesce, not start a new check
        gate.complete(PinVerificationResult.wrong);
        await second;
        await failure.timeout(const Duration(seconds: 30));

        verify(() => secureStorage.verifyPin(any())).called(1);
        verify(() => secureStorage.getPinFailedAttempts()).called(1);
        verify(() => secureStorage.setPinFailedAttempts(1)).called(1);
      });

      test('a verifyPin failure recovers to a usable state instead of a stuck spinner', () async {
        when(() => secureStorage.verifyPin(any())).thenThrow(Exception('hash failure'));
        final cubit = build();
        final recovered =
            cubit.stream.firstWhere((s) => s.runtimeType == VerifyPinState && s.pin.isEmpty);

        addPin(cubit, '123456');
        await recovered.timeout(const Duration(seconds: 30));

        expect(cubit.state.runtimeType, VerifyPinState);
        expect(cubit.state.pin, isEmpty);
      });
    });

    group('onLockExpired', () {
      blocTest<VerifyPinCubit, VerifyPinState>(
        'returns to a plain state preserving the failedAttempts count',
        build: build,
        seed: () => VerifyPinTemporarilyLocked(
          failedAttempts: 5,
          lockedUntil: DateTime(2030),
        ),
        act: (cubit) => cubit.onLockExpired(),
        expect: () => [const VerifyPinState(failedAttempts: 5)],
      );

      blocTest<VerifyPinCubit, VerifyPinState>(
        're-prompts biometrics when they are available after the lock clears',
        build: build,
        setUp: () => when(() => biometricService.authenticate())
            .thenAnswer((_) async => BiometricAuthOutcome.failed),
        seed: () => VerifyPinTemporarilyLocked(
          failedAttempts: 5,
          lockedUntil: DateTime(2030),
          biometricStatus: BiometricStatus.available,
        ),
        act: (cubit) => cubit.onLockExpired(),
        verify: (_) {
          verify(() => biometricService.authenticate()).called(1);
        },
      );

      blocTest<VerifyPinCubit, VerifyPinState>(
        'does not re-prompt biometrics when they are not available',
        build: build,
        seed: () => VerifyPinTemporarilyLocked(
          failedAttempts: 5,
          lockedUntil: DateTime(2030),
          biometricStatus: BiometricStatus.unavailable,
        ),
        act: (cubit) => cubit.onLockExpired(),
        verify: (_) {
          verifyNever(() => biometricService.authenticate());
        },
      );

      blocTest<VerifyPinCubit, VerifyPinState>(
        'is a no-op once already unlocked (does not clobber success or re-prompt)',
        build: build,
        setUp: () => when(() => biometricService.authenticate())
            .thenAnswer((_) async => BiometricAuthOutcome.success),
        // A late timer tick after a biometric unlock during the lockout window.
        seed: () => const VerifyPinSuccess(biometricStatus: BiometricStatus.available),
        act: (cubit) => cubit.onLockExpired(),
        expect: () => [],
        verify: (_) {
          verifyNever(() => biometricService.authenticate());
        },
      );
    });

    group('checkBiometricAvailability', () {
      test('marks biometrics disabled when the feature is off', () async {
        when(() => biometricService.isEnabled()).thenAnswer((_) async => false);
        final cubit = build();

        await cubit.checkBiometricAvailability();

        expect(cubit.state.biometricStatus, BiometricStatus.disabled);
        verifyNever(() => biometricService.authenticate());
      });

      test('marks biometrics unavailable when enabled but the OS cannot present them', () async {
        when(() => biometricService.isEnabled()).thenAnswer((_) async => true);
        when(() => biometricService.isAvailable()).thenAnswer((_) async => false);
        final cubit = build();

        await cubit.checkBiometricAvailability();

        expect(cubit.state.biometricStatus, BiometricStatus.unavailable);
        verifyNever(() => biometricService.authenticate());
      });

      test('auto-prompts and unlocks when enabled and available', () async {
        when(() => biometricService.isEnabled()).thenAnswer((_) async => true);
        when(() => biometricService.isAvailable()).thenAnswer((_) async => true);
        when(() => biometricService.authenticate())
            .thenAnswer((_) async => BiometricAuthOutcome.success);
        final cubit = build();
        final success = cubit.stream.firstWhere((s) => s is VerifyPinSuccess);

        await cubit.checkBiometricAvailability();
        await success.timeout(const Duration(seconds: 1));

        expect(cubit.state, isA<VerifyPinSuccess>());
        verify(() => biometricService.authenticate()).called(1);
        verify(() => secureStorage.resetPinLockout()).called(1);
      });

      test('emits TemporarilyLocked but still auto-prompts biometrics during the lock', () async {
        final until = DateTime.now().add(const Duration(minutes: 5));
        when(() => secureStorage.getPinLockedUntil()).thenAnswer((_) async => until);
        when(() => secureStorage.getPinFailedAttempts()).thenAnswer((_) async => 5);
        when(() => biometricService.isEnabled()).thenAnswer((_) async => true);
        when(() => biometricService.isAvailable()).thenAnswer((_) async => true);
        when(() => biometricService.authenticate())
            .thenAnswer((_) async => BiometricAuthOutcome.failed);
        final cubit = build();
        final locked = cubit.stream.firstWhere((s) => s is VerifyPinTemporarilyLocked);

        await cubit.checkBiometricAvailability();
        await locked.timeout(const Duration(seconds: 1));

        // The lock is shown, yet biometrics were still offered — the escape hatch.
        verify(() => biometricService.authenticate()).called(1);
      });

      test('biometric success during a temporary lockout resets it and unlocks', () async {
        final until = DateTime.now().add(const Duration(minutes: 5));
        when(() => secureStorage.getPinLockedUntil()).thenAnswer((_) async => until);
        when(() => secureStorage.getPinFailedAttempts()).thenAnswer((_) async => 5);
        when(() => biometricService.isEnabled()).thenAnswer((_) async => true);
        when(() => biometricService.isAvailable()).thenAnswer((_) async => true);
        when(() => biometricService.authenticate())
            .thenAnswer((_) async => BiometricAuthOutcome.success);
        final cubit = build();
        final success = cubit.stream.firstWhere((s) => s is VerifyPinSuccess);

        await cubit.checkBiometricAvailability();
        await success.timeout(const Duration(seconds: 1));

        expect(cubit.state, isA<VerifyPinSuccess>());
        verify(() => secureStorage.resetPinLockout()).called(1);
      });

      test('emits VerifyPinLocked but still auto-prompts biometrics when available', () async {
        when(() => secureStorage.getPinFailedAttempts())
            .thenAnswer((_) async => permanentLockoutThreshold);
        when(() => biometricService.isEnabled()).thenAnswer((_) async => true);
        when(() => biometricService.isAvailable()).thenAnswer((_) async => true);
        when(() => biometricService.authenticate())
            .thenAnswer((_) async => BiometricAuthOutcome.failed);
        final cubit = build();
        final locked = cubit.stream.firstWhere((s) => s is VerifyPinLocked);

        await cubit.checkBiometricAvailability();
        await locked.timeout(const Duration(seconds: 1));

        verify(() => biometricService.authenticate()).called(1);
      });

      test('clears an expired lockout before resolving biometrics', () async {
        final past = DateTime.now().subtract(const Duration(minutes: 5));
        when(() => secureStorage.getPinLockedUntil()).thenAnswer((_) async => past);
        when(() => secureStorage.getPinFailedAttempts()).thenAnswer((_) async => 5);
        when(() => biometricService.isEnabled()).thenAnswer((_) async => false);
        final cubit = build();

        await cubit.checkBiometricAvailability();

        verify(() => secureStorage.setPinLockedUntil(null)).called(1);
      });

      test('with lockout disabled, resolves biometrics without touching lock storage', () async {
        when(() => biometricService.isEnabled()).thenAnswer((_) async => true);
        when(() => biometricService.isAvailable()).thenAnswer((_) async => false);
        final cubit = build(enableLockout: false);

        await cubit.checkBiometricAvailability();

        expect(cubit.state.biometricStatus, BiometricStatus.unavailable);
        verifyNever(() => secureStorage.getPinLockedUntil());
        verifyNever(() => secureStorage.getPinFailedAttempts());
      });

      test('preserves digits typed while the storage reads were in flight', () async {
        when(() => biometricService.isEnabled()).thenAnswer((_) async => false);
        final cubit = build();

        addPin(cubit, '12'); // partial entry, too short to auto-trigger a check
        await cubit.checkBiometricAvailability();

        // The idle emit must not reset the pad the user is mid-way through.
        expect(cubit.state.pin, '12');
        expect(cubit.state.biometricStatus, BiometricStatus.disabled);
      });
    });

    group('guard release across sequential cycles', () {
      test('a second checkPin verifies after the first attempt failed', () async {
        when(() => secureStorage.verifyPin(any()))
            .thenAnswer((_) async => PinVerificationResult.wrong);
        when(() => secureStorage.getPinFailedAttempts()).thenAnswer((_) async => 0);
        final cubit = build();
        final failure = cubit.stream.firstWhere((s) => s is VerifyPinFailure);

        addPin(cubit, '999999');
        await failure.timeout(const Duration(seconds: 30));

        // Same cubit instance: the in-flight guard must have released so the
        // next entry is actually checked (otherwise the unlock screen bricks).
        when(() => secureStorage.verifyPin(any()))
            .thenAnswer((_) async => PinVerificationResult.correct);
        final success = cubit.stream.firstWhere((s) => s is VerifyPinSuccess);
        addPin(cubit, '123456');
        await success.timeout(const Duration(seconds: 30));

        expect(cubit.state, isA<VerifyPinSuccess>());
        verify(() => secureStorage.verifyPin(any())).called(2);
      });

      test('a second promptBiometric fires after a failed outcome', () async {
        when(() => biometricService.authenticate())
            .thenAnswer((_) async => BiometricAuthOutcome.failed);
        final cubit = build();

        await cubit.promptBiometric();
        await cubit.promptBiometric();

        // The prompt guard must release after each attempt or the retry button
        // goes dead.
        verify(() => biometricService.authenticate()).called(2);
      });
    });

    group('checkPin × promptBiometric interleaving', () {
      test('a biometric unlock wins over a pending pin check without a failed attempt', () async {
        final pinGate = Completer<PinVerificationResult>();
        when(() => secureStorage.verifyPin(any())).thenAnswer((_) => pinGate.future);
        when(() => biometricService.authenticate())
            .thenAnswer((_) async => BiometricAuthOutcome.success);
        final cubit = build();

        addPin(cubit, '999999'); // → VerifyPinVerifying, verifyPin still pending
        await cubit.promptBiometric(); // biometric success unlocks first
        expect(cubit.state, isA<VerifyPinSuccess>());

        pinGate.complete(PinVerificationResult.wrong); // resolves after success
        await Future<void>.delayed(Duration.zero);

        // The late 'wrong' must neither overwrite success nor burn an attempt.
        expect(cubit.state, isA<VerifyPinSuccess>());
        verifyNever(() => secureStorage.setPinFailedAttempts(any()));
        verify(() => secureStorage.resetPinLockout()).called(1);
      });

      test('a biometric hint arriving mid-verification keeps the verifying state', () async {
        final pinGate = Completer<PinVerificationResult>();
        final authGate = Completer<BiometricAuthOutcome>();
        when(() => secureStorage.verifyPin(any())).thenAnswer((_) => pinGate.future);
        when(() => biometricService.authenticate()).thenAnswer((_) => authGate.future);
        final cubit = build();

        final prompt = cubit.promptBiometric(); // authenticate pending
        addPin(cubit, '999999'); // → VerifyPinVerifying, verifyPin pending
        expect(cubit.state, isA<VerifyPinVerifying>());

        authGate.complete(BiometricAuthOutcome.temporarilyLocked);
        await prompt;

        // The hint must attach to the state without flattening the spinner.
        expect(cubit.state, isA<VerifyPinVerifying>());
        expect(cubit.state.biometricStatus, BiometricStatus.temporarilyLocked);

        pinGate.complete(PinVerificationResult.wrong); // cleanup
        await Future<void>.delayed(Duration.zero);
      });

      test(
        'a biometric unlock landing in the wrong-branch window neither counts an '
        'attempt nor clobbers success (F-01 cross-guard)',
        () async {
          // Three gates let us pin the exact interleaving: the pin check resolves
          // WRONG, then the biometric prompt succeeds while the wrong branch is
          // suspended reading the failure counter, then the counter read resolves.
          final verifyGate = Completer<PinVerificationResult>();
          final attemptsGate = Completer<int>();
          final authGate = Completer<BiometricAuthOutcome>();
          when(() => secureStorage.verifyPin(any())).thenAnswer((_) => verifyGate.future);
          when(() => secureStorage.getPinFailedAttempts()).thenAnswer((_) => attemptsGate.future);
          when(() => biometricService.authenticate()).thenAnswer((_) => authGate.future);
          final cubit = build();
          final success = cubit.stream.firstWhere((s) => s is VerifyPinSuccess);

          final prompt = cubit.promptBiometric(); // authenticate() pending on authGate
          addPin(cubit, '999999'); // 6th digit → _checkPin → verifyPin pending on verifyGate

          // Resolve the pin check as WRONG: _checkPin enters the wrong branch and
          // suspends on getPinFailedAttempts (pending on attemptsGate).
          verifyGate.complete(PinVerificationResult.wrong);
          await pumpEventQueue();

          // Now the racing biometric prompt succeeds: it resets the lockout and
          // emits VerifyPinSuccess right inside the window the wrong branch is
          // suspended in.
          authGate.complete(BiometricAuthOutcome.success);
          await prompt;
          await success.timeout(const Duration(seconds: 30));
          expect(cubit.state, isA<VerifyPinSuccess>());

          // Release the wrong branch's counter read AFTER the biometric success.
          attemptsGate.complete(0);
          await pumpEventQueue();

          // The cross-guard must short-circuit the wrong branch: no stale counter
          // written back over the reset, and the success left intact. Without the
          // guard, setPinFailedAttempts would run and _emitLockState would clobber
          // the success with a failure/lock state.
          expect(cubit.state, isA<VerifyPinSuccess>());
          verifyNever(() => secureStorage.setPinFailedAttempts(any()));
        },
      );
    });

    group('promptBiometric outcome mapping', () {
      test('success resets the lockout and emits VerifyPinSuccess', () async {
        when(() => biometricService.authenticate())
            .thenAnswer((_) async => BiometricAuthOutcome.success);
        final cubit = build();

        await cubit.promptBiometric();

        expect(cubit.state, isA<VerifyPinSuccess>());
        verify(() => secureStorage.resetPinLockout()).called(1);
      });

      blocTest<VerifyPinCubit, VerifyPinState>(
        'failed leaves the status untouched and emits nothing',
        build: build,
        setUp: () => when(() => biometricService.authenticate())
            .thenAnswer((_) async => BiometricAuthOutcome.failed),
        seed: () => const VerifyPinState(biometricStatus: BiometricStatus.available),
        act: (cubit) => cubit.promptBiometric(),
        expect: () => [],
      );

      const mapping = <BiometricAuthOutcome, BiometricStatus>{
        BiometricAuthOutcome.temporarilyLocked: BiometricStatus.temporarilyLocked,
        BiometricAuthOutcome.permanentlyLocked: BiometricStatus.permanentlyLocked,
        BiometricAuthOutcome.notEnrolled: BiometricStatus.notEnrolled,
        BiometricAuthOutcome.unavailable: BiometricStatus.unavailable,
      };

      for (final entry in mapping.entries) {
        test('${entry.key.name} sets biometricStatus.${entry.value.name}', () async {
          when(() => biometricService.authenticate()).thenAnswer((_) async => entry.key);
          final cubit = build();

          await cubit.promptBiometric();

          expect(cubit.state.biometricStatus, entry.value);
        });
      }

      test('concurrent promptBiometric calls fire the OS prompt only once', () async {
        final gate = Completer<BiometricAuthOutcome>();
        when(() => biometricService.authenticate()).thenAnswer((_) => gate.future);
        final cubit = build();

        final first = cubit.promptBiometric();
        final second = cubit.promptBiometric();
        gate.complete(BiometricAuthOutcome.failed);
        await Future.wait([first, second]);

        verify(() => biometricService.authenticate()).called(1);
      });
    });

    group('promptBiometric keeps the current display state while attaching the hint', () {
      blocTest<VerifyPinCubit, VerifyPinState>(
        'temporary lockout is preserved (pad stays disabled, hint added)',
        build: build,
        setUp: () => when(() => biometricService.authenticate())
            .thenAnswer((_) async => BiometricAuthOutcome.temporarilyLocked),
        seed: () => VerifyPinTemporarilyLocked(
          failedAttempts: 5,
          lockedUntil: DateTime(2030),
          biometricStatus: BiometricStatus.available,
        ),
        act: (cubit) => cubit.promptBiometric(),
        verify: (cubit) {
          expect(cubit.state, isA<VerifyPinTemporarilyLocked>());
          expect(cubit.state.biometricStatus, BiometricStatus.temporarilyLocked);
          expect((cubit.state as VerifyPinTemporarilyLocked).lockedUntil, DateTime(2030));
        },
      );

      blocTest<VerifyPinCubit, VerifyPinState>(
        'permanent lockout is preserved',
        build: build,
        setUp: () => when(() => biometricService.authenticate())
            .thenAnswer((_) async => BiometricAuthOutcome.notEnrolled),
        seed: () => const VerifyPinLocked(
          failedAttempts: 9,
          biometricStatus: BiometricStatus.available,
        ),
        act: (cubit) => cubit.promptBiometric(),
        verify: (cubit) {
          expect(cubit.state, isA<VerifyPinLocked>());
          expect(cubit.state.biometricStatus, BiometricStatus.notEnrolled);
        },
      );

      blocTest<VerifyPinCubit, VerifyPinState>(
        'unverifiable is preserved (pad stays disabled)',
        build: build,
        setUp: () => when(() => biometricService.authenticate())
            .thenAnswer((_) async => BiometricAuthOutcome.unavailable),
        seed: () => const VerifyPinUnverifiable(
          biometricStatus: BiometricStatus.available,
        ),
        act: (cubit) => cubit.promptBiometric(),
        verify: (cubit) {
          expect(cubit.state, isA<VerifyPinUnverifiable>());
          expect(cubit.state.biometricStatus, BiometricStatus.unavailable);
        },
      );

      blocTest<VerifyPinCubit, VerifyPinState>(
        'failure is preserved',
        build: build,
        setUp: () => when(() => biometricService.authenticate())
            .thenAnswer((_) async => BiometricAuthOutcome.temporarilyLocked),
        seed: () => const VerifyPinFailure(
          failedAttempts: 1,
          biometricStatus: BiometricStatus.available,
        ),
        act: (cubit) => cubit.promptBiometric(),
        verify: (cubit) {
          expect(cubit.state, isA<VerifyPinFailure>());
          expect(cubit.state.biometricStatus, BiometricStatus.temporarilyLocked);
        },
      );

      blocTest<VerifyPinCubit, VerifyPinState>(
        'success is preserved when a late non-success outcome arrives',
        build: build,
        setUp: () => when(() => biometricService.authenticate())
            .thenAnswer((_) async => BiometricAuthOutcome.temporarilyLocked),
        seed: () => const VerifyPinSuccess(biometricStatus: BiometricStatus.available),
        act: (cubit) => cubit.promptBiometric(),
        verify: (cubit) {
          // Must not flatten the terminal success back to a plain pad state.
          expect(cubit.state, isA<VerifyPinSuccess>());
          expect(cubit.state.biometricStatus, BiometricStatus.temporarilyLocked);
        },
      );
    });
  });
}
