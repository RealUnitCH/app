import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
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
    test('initial state is empty pin, zero failed attempts', () {
      final cubit = build();

      expect(cubit.state.pin, '');
      expect(cubit.state.failedAttempts, 0);
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
    });

    group('checkPin (auto-triggered after 6 digits)', () {
      test('correct pin resets lockout counter and emits VerifyPinSuccess', () async {
        when(() => secureStorage.verifyPin(any())).thenAnswer((_) async => true);
        final cubit = build();
        final success = cubit.stream.firstWhere((s) => s is VerifyPinSuccess);

        addPin(cubit, '123456');
        await success.timeout(const Duration(seconds: 30));

        expect(cubit.state, isA<VerifyPinSuccess>());
        verify(() => secureStorage.resetPinLockout()).called(1);
      });

      test('wrong pin (1st attempt) with lockout on emits VerifyPinFailure', () async {
        when(() => secureStorage.verifyPin(any())).thenAnswer((_) async => false);
        when(() => secureStorage.getPinFailedAttempts()).thenAnswer((_) async => 0);
        final cubit = build();
        final failure = cubit.stream.firstWhere((s) => s is VerifyPinFailure);

        addPin(cubit, '999999');
        await failure.timeout(const Duration(seconds: 30));

        expect(cubit.state, isA<VerifyPinFailure>());
        expect((cubit.state as VerifyPinFailure).failedAttempts, 1);
        verify(() => secureStorage.setPinFailedAttempts(1)).called(1);
        // First attempt → no temporary lockout written.
        verifyNever(() => secureStorage.setPinLockedUntil(any()));
      });

      test('wrong pin with lockout disabled never persists attempts', () async {
        when(() => secureStorage.verifyPin(any())).thenAnswer((_) async => false);
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
        when(() => secureStorage.verifyPin(any())).thenAnswer((_) async => false);
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
        when(() => secureStorage.verifyPin(any())).thenAnswer((_) async => false);
        when(() => secureStorage.getPinFailedAttempts())
            .thenAnswer((_) async => permanentLockoutThreshold - 1);
        final cubit = build();
        final locked = cubit.stream.firstWhere((s) => s is VerifyPinLocked);

        addPin(cubit, '999999');
        await locked.timeout(const Duration(seconds: 30));

        expect(cubit.state, isA<VerifyPinLocked>());
        expect(cubit.state.failedAttempts, permanentLockoutThreshold);
        verify(() => secureStorage.setPinFailedAttempts(permanentLockoutThreshold)).called(1);
        // Permanent lockout does NOT write a temporary lockedUntil.
        verifyNever(() => secureStorage.setPinLockedUntil(any()));
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
    });

    group('checkBiometricAvailability', () {
      test('returns early as TemporarilyLocked when within lockedUntil window', () async {
        final until = DateTime.now().add(const Duration(minutes: 5));
        when(() => secureStorage.getPinLockedUntil()).thenAnswer((_) async => until);
        when(() => secureStorage.getPinFailedAttempts()).thenAnswer((_) async => 5);
        final cubit = build();
        final locked = cubit.stream.firstWhere((s) => s is VerifyPinTemporarilyLocked);

        await cubit.checkBiometricAvailability();
        await locked.timeout(const Duration(seconds: 1));

        expect(cubit.state, isA<VerifyPinTemporarilyLocked>());
        verifyNever(() => biometricService.canUse());
      });

      test('clears expired lockout and proceeds to biometric path', () async {
        final past = DateTime.now().subtract(const Duration(minutes: 5));
        when(() => secureStorage.getPinLockedUntil()).thenAnswer((_) async => past);
        when(() => secureStorage.getPinFailedAttempts()).thenAnswer((_) async => 5);
        when(() => biometricService.canUse()).thenAnswer((_) async => false);
        final cubit = build();

        await cubit.checkBiometricAvailability();

        verify(() => secureStorage.setPinLockedUntil(null)).called(1);
        verify(() => biometricService.canUse()).called(1);
      });

      test('emits VerifyPinLocked when persisted attempts reach the threshold', () async {
        when(() => secureStorage.getPinFailedAttempts())
            .thenAnswer((_) async => permanentLockoutThreshold);
        final cubit = build();
        final locked = cubit.stream.firstWhere((s) => s is VerifyPinLocked);

        await cubit.checkBiometricAvailability();
        await locked.timeout(const Duration(seconds: 1));

        expect(cubit.state, isA<VerifyPinLocked>());
        verifyNever(() => biometricService.canUse());
      });

      test('successful biometric unlock resets lockout and emits VerifyPinSuccess', () async {
        when(() => biometricService.canUse()).thenAnswer((_) async => true);
        when(() => biometricService.authenticate()).thenAnswer((_) async => true);
        final cubit = build();
        final success = cubit.stream.firstWhere((s) => s is VerifyPinSuccess);

        await cubit.checkBiometricAvailability();
        await success.timeout(const Duration(seconds: 1));

        expect(cubit.state, isA<VerifyPinSuccess>());
        verify(() => secureStorage.resetPinLockout()).called(1);
      });

      test('failed biometric authenticate does NOT emit success', () async {
        when(() => biometricService.canUse()).thenAnswer((_) async => true);
        when(() => biometricService.authenticate()).thenAnswer((_) async => false);
        final cubit = build();

        await cubit.checkBiometricAvailability();

        expect(cubit.state, isNot(isA<VerifyPinSuccess>()));
        verifyNever(() => secureStorage.resetPinLockout());
      });

      test('biometrics unavailable is a quiet no-op', () async {
        when(() => biometricService.canUse()).thenAnswer((_) async => false);
        final cubit = build();

        await cubit.checkBiometricAvailability();

        expect(cubit.state, isA<VerifyPinState>());
        expect(cubit.state, isNot(isA<VerifyPinSuccess>()));
        verifyNever(() => biometricService.authenticate());
      });
    });

    group('concurrency (F-01: PIN-lockout under-count race)', () {
      test('two parallel checkPin of one submission advance the counter once', () async {
        when(() => secureStorage.verifyPin(any())).thenAnswer((_) async => false);
        when(() => secureStorage.getPinFailedAttempts()).thenAnswer((_) async => 0);
        final cubit = build();

        // The PIN is fixed for the lifetime of a submission, so concurrent
        // checkPin() calls always verify the SAME pin — one logical attempt
        // double-fired. The 6th digit auto-fires checkPin() #1; a second
        // checkPin() races it against the read-modify-write failure counter.
        addPin(cubit, '99999');
        cubit.addDigit(9); // 6th digit -> auto checkPin() #1 (in-flight)
        final second = cubit.checkPin(); // checkPin() #2, same state.pin

        await second.timeout(const Duration(seconds: 30));
        await pumpEventQueue();

        // Single-effect: the counter must advance to exactly 1, written once.
        // At HEAD both reads see 0 and both write 1 -> called twice (RED).
        verify(() => secureStorage.setPinFailedAttempts(1)).called(1);
        verifyNever(() => secureStorage.setPinFailedAttempts(2));
        expect(cubit.state.failedAttempts, 1);
      });
    });
  });
}
