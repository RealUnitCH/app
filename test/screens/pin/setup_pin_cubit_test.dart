import 'dart:typed_data';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
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
      when(() => biometricService.enable()).thenAnswer((_) async => true);

      final result = await build().enableBiometrics();

      expect(result, isTrue);
      verify(() => biometricService.enable()).called(1);
    });

    group('concurrency (F-09: salt/hash setup race)', () {
      test('confirm re-typed during the in-flight hash writes one atomic salt+hash', () async {
        Uint8List? savedSalt;
        String? savedHash;
        when(() => secureStorage.setPinSalt(any())).thenAnswer((inv) async {
          savedSalt = inv.positionalArguments.first as Uint8List;
        });
        when(() => secureStorage.setPinHash(any())).thenAnswer((inv) async {
          savedHash = inv.positionalArguments.first as String;
        });
        final cubit = build();
        final completed = cubit.stream.firstWhere((s) => s.isComplete);

        // Create the pin -> confirm mode (with _createPin set).
        for (final d in [1, 2, 3, 4, 5, 6]) {
          cubit.addDigit(d);
        }
        // Confirm the pin -> fires _confirmPin #1 (in-flight on the slow PBKDF2
        // compute()). currentPin stays '123456', so the field still looks full.
        for (final d in [1, 2, 3, 4, 5, 6]) {
          cubit.addDigit(d);
        }
        // An impatient user backspaces and re-types the last digit while the
        // hash is still computing -> fires _confirmPin #2 concurrently.
        cubit.deleteDigit();
        cubit.addDigit(6);

        await completed.timeout(const Duration(seconds: 30));
        await pumpEventQueue();

        // Single-effect + atomic: exactly one salt and one hash persisted, and
        // the persisted hash must be PBKDF2(pin, persisted salt) — i.e. salt and
        // hash provably come from the SAME run. At HEAD two interleaved runs
        // write twice and can tear the pair (saltB + hashA) -> RED.
        verify(() => secureStorage.setPinSalt(any())).called(1);
        verify(() => secureStorage.setPinHash(any())).called(1);
        expect(savedSalt, isNotNull);
        expect(savedHash, SecureStorage.hashPin('123456', savedSalt!));
      });
    });
  });
}
