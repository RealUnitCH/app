import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:realunit_wallet/packages/service/biometric/biometric_auth_outcome.dart';
import 'package:realunit_wallet/packages/service/biometric_service.dart';
import 'package:realunit_wallet/screens/settings_security/cubits/settings_security_cubit.dart';

class _MockBiometricService extends Mock implements BiometricService {}

void main() {
  late _MockBiometricService biometricService;

  setUp(() {
    biometricService = _MockBiometricService();
  });

  SettingsSecurityCubit build() => SettingsSecurityCubit(biometricService);

  group('initial state', () {
    test('is a default $SettingsSecurityState', () {
      expect(build().state, const SettingsSecurityState());
    });
  });

  group('init', () {
    blocTest<SettingsSecurityCubit, SettingsSecurityState>(
      'hydrates support + enabled flag when both are true',
      setUp: () {
        when(() => biometricService.isAvailable()).thenAnswer((_) async => true);
        when(() => biometricService.isEnabled()).thenAnswer((_) async => true);
      },
      build: build,
      act: (cubit) => cubit.init(),
      expect: () => const [
        SettingsSecurityState(biometricSupported: true, biometricEnabled: true),
      ],
    );

    blocTest<SettingsSecurityCubit, SettingsSecurityState>(
      'reports unsupported + disabled when hardware is missing',
      setUp: () {
        when(() => biometricService.isAvailable()).thenAnswer((_) async => false);
        when(() => biometricService.isEnabled()).thenAnswer((_) async => false);
      },
      build: build,
      act: (cubit) => cubit.init(),
      expect: () => const [
        SettingsSecurityState(biometricSupported: false, biometricEnabled: false),
      ],
    );
  });

  group('toggleBiometrics', () {
    blocTest<SettingsSecurityCubit, SettingsSecurityState>(
      'enable success → busy then enabled, no error',
      setUp: () => when(() => biometricService.enable())
          .thenAnswer((_) async => BiometricAuthOutcome.success),
      build: build,
      act: (cubit) => cubit.toggleBiometrics(enabled: true),
      expect: () => const [
        SettingsSecurityState(isBusy: true),
        SettingsSecurityState(biometricEnabled: true),
      ],
      verify: (_) => verify(() => biometricService.enable()).called(1),
    );

    blocTest<SettingsSecurityCubit, SettingsSecurityState>(
      'enable genuine failure → busy then rolled back with error signal',
      setUp: () => when(() => biometricService.enable())
          .thenAnswer((_) async => BiometricAuthOutcome.unavailable),
      build: build,
      act: (cubit) => cubit.toggleBiometrics(enabled: true),
      expect: () => const [
        SettingsSecurityState(isBusy: true),
        SettingsSecurityState(
          biometricEnabled: false,
          error: SettingsSecurityError.biometricEnableFailed,
        ),
      ],
    );

    blocTest<SettingsSecurityCubit, SettingsSecurityState>(
      'enable user-cancel (failed) → busy then rolled back WITHOUT an error signal',
      setUp: () => when(() => biometricService.enable())
          .thenAnswer((_) async => BiometricAuthOutcome.failed),
      build: build,
      act: (cubit) => cubit.toggleBiometrics(enabled: true),
      // A deliberate cancel is not an error — no red SnackBar, toggle stays off.
      expect: () => const [
        SettingsSecurityState(isBusy: true),
        SettingsSecurityState(biometricEnabled: false),
      ],
    );

    blocTest<SettingsSecurityCubit, SettingsSecurityState>(
      'disable → busy then flag off, disable() called',
      setUp: () => when(() => biometricService.disable()).thenAnswer((_) async {}),
      build: build,
      seed: () => const SettingsSecurityState(
        biometricSupported: true,
        biometricEnabled: true,
      ),
      act: (cubit) => cubit.toggleBiometrics(enabled: false),
      expect: () => const [
        SettingsSecurityState(
          biometricSupported: true,
          biometricEnabled: true,
          isBusy: true,
        ),
        SettingsSecurityState(biometricSupported: true, biometricEnabled: false),
      ],
      verify: (_) {
        verify(() => biometricService.disable()).called(1);
        verifyNever(() => biometricService.enable());
      },
    );

    blocTest<SettingsSecurityCubit, SettingsSecurityState>(
      'ignores a second toggle while a round-trip is in flight (no stacked OS prompt)',
      setUp: () {
        final completer = Completer<BiometricAuthOutcome>();
        when(() => biometricService.enable()).thenAnswer((_) => completer.future);
        // Store the completer where act can complete it after the guard fires.
        _pendingEnable = completer;
      },
      build: build,
      act: (cubit) async {
        final first = cubit.toggleBiometrics(enabled: true);
        // Second call sees isBusy == true (emitted synchronously) → early return.
        await cubit.toggleBiometrics(enabled: true);
        _pendingEnable.complete(BiometricAuthOutcome.success);
        await first;
      },
      expect: () => const [
        SettingsSecurityState(isBusy: true),
        SettingsSecurityState(biometricEnabled: true),
      ],
      verify: (_) => verify(() => biometricService.enable()).called(1),
    );

    blocTest<SettingsSecurityCubit, SettingsSecurityState>(
      'enable throwing (keychain write failure) clears busy and surfaces the error',
      setUp: () => when(() => biometricService.enable())
          .thenThrow(Exception('keychain unavailable')),
      build: build,
      act: (cubit) => cubit.toggleBiometrics(enabled: true),
      // Must NOT strand on the spinner (isBusy latched); clears busy + raises the
      // one-shot error instead.
      expect: () => const [
        SettingsSecurityState(isBusy: true),
        SettingsSecurityState(
          error: SettingsSecurityError.biometricEnableFailed,
        ),
      ],
    );

    test('a throwing enable does not latch isBusy — a later toggle can retry', () async {
      when(() => biometricService.enable()).thenThrow(Exception('keychain unavailable'));
      final cubit = build();

      await cubit.toggleBiometrics(enabled: true);
      expect(cubit.state.isBusy, isFalse);
      expect(cubit.state.error, SettingsSecurityError.biometricEnableFailed);

      // The re-entrancy guard (isBusy) must have released: a retry actually
      // reaches enable() again instead of being dropped as a stacked prompt.
      when(() => biometricService.enable()).thenAnswer((_) async => BiometricAuthOutcome.success);
      await cubit.toggleBiometrics(enabled: true);

      expect(cubit.state.biometricEnabled, isTrue);
      expect(cubit.state.isBusy, isFalse);
      expect(cubit.state.error, isNull);
      verify(() => biometricService.enable()).called(2);
    });

    blocTest<SettingsSecurityCubit, SettingsSecurityState>(
      'disable throwing (keychain write failure) clears busy and surfaces the error',
      setUp: () => when(() => biometricService.disable())
          .thenThrow(Exception('keychain unavailable')),
      build: build,
      seed: () => const SettingsSecurityState(
        biometricSupported: true,
        biometricEnabled: true,
      ),
      act: (cubit) => cubit.toggleBiometrics(enabled: false),
      expect: () => const [
        SettingsSecurityState(
          biometricSupported: true,
          biometricEnabled: true,
          isBusy: true,
        ),
        SettingsSecurityState(
          biometricSupported: true,
          biometricEnabled: true,
          error: SettingsSecurityError.biometricEnableFailed,
        ),
      ],
    );
  });
}

late Completer<BiometricAuthOutcome> _pendingEnable;
