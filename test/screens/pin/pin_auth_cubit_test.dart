import 'package:bloc_test/bloc_test.dart';
import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:realunit_wallet/packages/storage/secure_storage.dart';
import 'package:realunit_wallet/screens/pin/bloc/auth/pin_auth_cubit.dart';
import 'package:realunit_wallet/screens/pin/constants/pin_constants.dart';

class _MockSecureStorage extends Mock implements SecureStorage {}

void main() {
  late _MockSecureStorage storage;

  setUp(() {
    storage = _MockSecureStorage();
  });

  PinAuthCubit build() => PinAuthCubit(storage);

  group('$PinAuthCubit initial state', () {
    test('isPinSetup=false and isPinVerified=false', () {
      expect(build().state, const PinAuthState());
    });
  });

  group('initialize', () {
    blocTest<PinAuthCubit, PinAuthState>(
      'PIN is set: emits isPinSetup=true and keeps isPinVerified=false',
      setUp: () => when(() => storage.hasPinHash()).thenAnswer((_) async => true),
      build: build,
      act: (c) => c.initialize(),
      expect: () => const [
        PinAuthState(isPinSetup: true),
      ],
    );

    blocTest<PinAuthCubit, PinAuthState>(
      'no PIN set: emits isPinSetup=false and isPinVerified=true (auto-pass)',
      setUp: () => when(() => storage.hasPinHash()).thenAnswer((_) async => false),
      build: build,
      act: (c) => c.initialize(),
      expect: () => const [
        PinAuthState(isPinVerified: true),
      ],
    );
  });

  group('verification helpers', () {
    blocTest<PinAuthCubit, PinAuthState>(
      'onPinSetupComplete sets both flags true',
      build: build,
      act: (c) => c.onPinSetupComplete(),
      expect: () => const [
        PinAuthState(isPinSetup: true, isPinVerified: true),
      ],
    );

    blocTest<PinAuthCubit, PinAuthState>(
      'onPinVerified flips isPinVerified true and preserves isPinSetup',
      seed: () => const PinAuthState(isPinSetup: true),
      build: build,
      act: (c) => c.onPinVerified(),
      expect: () => const [
        PinAuthState(isPinSetup: true, isPinVerified: true),
      ],
    );
  });

  group('background / resume lockout', () {
    test('onAppResumed without onAppHidden is a no-op (no emit)', () {
      final cubit = build();
      final before = cubit.state;
      cubit.onAppResumed();
      expect(cubit.state, before);
    });

    test('onAppResumed when PIN not setup is a no-op (no emit)', () async {
      final cubit = build()..onAppHidden();
      final before = cubit.state;
      cubit.onAppResumed();
      expect(cubit.state, before);
    });

    test(
      'short hide → resume keeps isPinVerified true (elapsed < lockoutDuration)',
      () async {
        final cubit = build()..onPinSetupComplete();
        expect(cubit.state.isPinVerified, isTrue);

        // The lockout check uses wall-clock time, so we exercise the
        // elapsed-too-small branch by hiding and resuming back-to-back.
        // The elapsed-too-large branch is implicitly covered by the
        // lockoutDuration constant pin below — flipping that constant or the
        // comparator surfaces in the auth flow's own tests.
        cubit
          ..onAppHidden()
          ..onAppResumed();

        expect(cubit.state.isPinVerified, isTrue);
      },
    );

    test(
      'long hide → resume flips isPinVerified back to false (elapsed >= lockoutDuration)',
      () {
        // The lockout branch reads wallclock `DateTime.now()`, so we drive
        // virtual time with fake_async to step past the 5-minute threshold
        // deterministically — no sleeps, no flakiness.
        fakeAsync((async) {
          final cubit = build()..onPinSetupComplete();
          expect(cubit.state.isPinVerified, isTrue);

          cubit.onAppHidden();
          async.elapse(lockoutDuration + const Duration(seconds: 1));
          cubit.onAppResumed();

          expect(cubit.state.isPinVerified, isFalse);
          // Background timestamp is consumed: a second hide→resume cycle is
          // a no-op until a new `onAppHidden()` lands.
          cubit.onAppResumed();
          expect(cubit.state.isPinVerified, isFalse);

          cubit.close();
        });
      },
    );

    test('lockoutDuration constant is 5 minutes (boundary pin)', () {
      // The behaviour depends on this exact constant — pin it so changes
      // surface in this file rather than only in the auth flow.
      expect(lockoutDuration, const Duration(minutes: 5));
    });
  });

  group('reset', () {
    blocTest<PinAuthCubit, PinAuthState>(
      'wipes pin hash + biometric + lockout and emits the initial state',
      setUp: () {
        when(() => storage.deletePinHash()).thenAnswer((_) async {});
        when(() => storage.deleteBiometricEnabled()).thenAnswer((_) async {});
        when(() => storage.resetPinLockout()).thenAnswer((_) async {});
      },
      seed: () => const PinAuthState(isPinSetup: true, isPinVerified: true),
      build: build,
      act: (c) => c.reset(),
      verify: (_) {
        verify(() => storage.deletePinHash()).called(1);
        verify(() => storage.deleteBiometricEnabled()).called(1);
        verify(() => storage.resetPinLockout()).called(1);
      },
      expect: () => const [PinAuthState()],
    );
  });
}
