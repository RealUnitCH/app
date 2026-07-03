import 'package:flutter_test/flutter_test.dart';
import 'package:local_auth/local_auth.dart';
import 'package:mocktail/mocktail.dart';
import 'package:realunit_wallet/packages/service/biometric/biometric_auth_outcome.dart';
import 'package:realunit_wallet/packages/service/biometric/biometric_port.dart';
import 'package:realunit_wallet/packages/service/biometric_service.dart';
import 'package:realunit_wallet/packages/storage/secure_storage.dart';

class _MockSecureStorage extends Mock implements SecureStorage {}

/// In-memory [BiometricPort] driven by per-test stubs. Each method records the
/// arguments it received so individual assertions can verify wiring.
class _FakeBiometricPort implements BiometricPort {
  _FakeBiometricPort({
    this.canCheck = true,
    this.deviceSupported = true,
    this.authenticateResult = true,
    this.authenticateThrows,
  });

  bool canCheck;
  bool deviceSupported;
  bool authenticateResult;
  Object? authenticateThrows;

  int canCheckCalls = 0;
  int deviceSupportedCalls = 0;
  int authenticateCalls = 0;
  String? lastReason;
  bool? lastBiometricOnly;
  bool? lastPersistAcrossBackgrounding;

  @override
  Future<bool> canCheckBiometrics() async {
    canCheckCalls++;
    return canCheck;
  }

  @override
  Future<bool> isDeviceSupported() async {
    deviceSupportedCalls++;
    return deviceSupported;
  }

  @override
  Future<bool> authenticate({
    required String localizedReason,
    required bool biometricOnly,
    required bool persistAcrossBackgrounding,
  }) async {
    authenticateCalls++;
    lastReason = localizedReason;
    lastBiometricOnly = biometricOnly;
    lastPersistAcrossBackgrounding = persistAcrossBackgrounding;
    if (authenticateThrows != null) {
      throw authenticateThrows!;
    }
    return authenticateResult;
  }
}

void main() {
  late _MockSecureStorage storage;

  setUp(() {
    storage = _MockSecureStorage();
  });

  group('$BiometricService', () {
    group('isAvailable', () {
      test('returns true when device can check biometrics and is supported', () async {
        final port = _FakeBiometricPort(canCheck: true, deviceSupported: true);
        final service = BiometricService(storage, biometric: port);

        expect(await service.isAvailable(), isTrue);
        expect(port.canCheckCalls, 1);
        expect(port.deviceSupportedCalls, 1);
      });

      test('returns false when device cannot check biometrics', () async {
        final port = _FakeBiometricPort(canCheck: false, deviceSupported: true);
        final service = BiometricService(storage, biometric: port);

        expect(await service.isAvailable(), isFalse);
      });

      test('returns false when device is not supported', () async {
        final port = _FakeBiometricPort(canCheck: true, deviceSupported: false);
        final service = BiometricService(storage, biometric: port);

        expect(await service.isAvailable(), isFalse);
      });
    });

    group('isEnabled', () {
      test('forwards to secure storage', () async {
        when(() => storage.getIsBiometricEnabled()).thenAnswer((_) async => true);
        final service = BiometricService(storage, biometric: _FakeBiometricPort());

        expect(await service.isEnabled(), isTrue);
        verify(() => storage.getIsBiometricEnabled()).called(1);
      });

      test('returns false when secure storage says disabled', () async {
        when(() => storage.getIsBiometricEnabled()).thenAnswer((_) async => false);
        final service = BiometricService(storage, biometric: _FakeBiometricPort());

        expect(await service.isEnabled(), isFalse);
      });
    });

    group('canUse', () {
      test('true only when both enabled and available', () async {
        when(() => storage.getIsBiometricEnabled()).thenAnswer((_) async => true);
        final port = _FakeBiometricPort(canCheck: true, deviceSupported: true);
        final service = BiometricService(storage, biometric: port);

        expect(await service.canUse(), isTrue);
      });

      test('false when enabled but unavailable (canCheck false)', () async {
        when(() => storage.getIsBiometricEnabled()).thenAnswer((_) async => true);
        final port = _FakeBiometricPort(canCheck: false, deviceSupported: true);
        final service = BiometricService(storage, biometric: port);

        expect(await service.canUse(), isFalse);
      });

      test('false when available but not enabled (short-circuits)', () async {
        when(() => storage.getIsBiometricEnabled()).thenAnswer((_) async => false);
        final port = _FakeBiometricPort(canCheck: true, deviceSupported: true);
        final service = BiometricService(storage, biometric: port);

        expect(await service.canUse(), isFalse);
        // canUse short-circuits on the disabled flag, so the port is never
        // queried.
        expect(port.canCheckCalls, 0);
        expect(port.deviceSupportedCalls, 0);
      });
    });

    group('authenticate', () {
      test('is success with the expected prompt configuration', () async {
        final port = _FakeBiometricPort(authenticateResult: true);
        final service = BiometricService(storage, biometric: port);

        expect(await service.authenticate(), BiometricAuthOutcome.success);
        expect(port.authenticateCalls, 1);
        expect(port.lastReason, 'Authenticate to unlock your wallet');
        expect(port.lastBiometricOnly, isTrue);
        expect(port.lastPersistAcrossBackgrounding, isTrue);
      });

      test('is failed when the port returns false (plain scan failure)', () async {
        final port = _FakeBiometricPort(authenticateResult: false);
        final service = BiometricService(storage, biometric: port);

        expect(await service.authenticate(), BiometricAuthOutcome.failed);
      });

      test('is unavailable when a non-plugin error is thrown', () async {
        final port = _FakeBiometricPort(
          authenticateThrows: Exception('unexpected'),
        );
        final service = BiometricService(storage, biometric: port);

        expect(await service.authenticate(), BiometricAuthOutcome.unavailable);
      });

      // Full mapping of the `local_auth` 3.x exception surface. Each code is
      // pinned so a plugin-side semantic change (or a wrong grouping here)
      // trips a test rather than silently mis-handling a lockout / enrollment
      // state at the unlock screen.
      const mapping = <LocalAuthExceptionCode, BiometricAuthOutcome>{
        LocalAuthExceptionCode.userCanceled: BiometricAuthOutcome.failed,
        LocalAuthExceptionCode.userRequestedFallback: BiometricAuthOutcome.failed,
        LocalAuthExceptionCode.timeout: BiometricAuthOutcome.failed,
        LocalAuthExceptionCode.systemCanceled: BiometricAuthOutcome.failed,
        LocalAuthExceptionCode.authInProgress: BiometricAuthOutcome.failed,
        LocalAuthExceptionCode.temporaryLockout: BiometricAuthOutcome.temporarilyLocked,
        LocalAuthExceptionCode.biometricLockout: BiometricAuthOutcome.permanentlyLocked,
        LocalAuthExceptionCode.noBiometricsEnrolled: BiometricAuthOutcome.notEnrolled,
        LocalAuthExceptionCode.noCredentialsSet: BiometricAuthOutcome.notEnrolled,
        LocalAuthExceptionCode.noBiometricHardware: BiometricAuthOutcome.unavailable,
        LocalAuthExceptionCode.biometricHardwareTemporarilyUnavailable:
            BiometricAuthOutcome.unavailable,
        LocalAuthExceptionCode.uiUnavailable: BiometricAuthOutcome.unavailable,
        LocalAuthExceptionCode.deviceError: BiometricAuthOutcome.unavailable,
        LocalAuthExceptionCode.unknownError: BiometricAuthOutcome.unavailable,
      };

      for (final entry in mapping.entries) {
        test('LocalAuthException(${entry.key.name}) maps to ${entry.value.name}', () async {
          final port = _FakeBiometricPort(
            authenticateThrows: LocalAuthException(code: entry.key),
          );
          final service = BiometricService(storage, biometric: port);

          expect(await service.authenticate(), entry.value);
        });
      }
    });

    group('enable', () {
      test('persists the flag and returns success when authenticate succeeds', () async {
        when(() => storage.setIsBiometricEnabled(enabled: any(named: 'enabled')))
            .thenAnswer((_) async {});
        final port = _FakeBiometricPort(authenticateResult: true);
        final service = BiometricService(storage, biometric: port);

        expect(await service.enable(), BiometricAuthOutcome.success);
        verify(() => storage.setIsBiometricEnabled(enabled: true)).called(1);
      });

      test('returns failed and does not persist on a plain scan failure / cancel', () async {
        final port = _FakeBiometricPort(authenticateResult: false);
        final service = BiometricService(storage, biometric: port);

        expect(await service.enable(), BiometricAuthOutcome.failed);
        verifyNever(() => storage.setIsBiometricEnabled(enabled: any(named: 'enabled')));
      });

      test('returns unavailable and does not persist when the platform throws', () async {
        final port = _FakeBiometricPort(authenticateThrows: Exception('boom'));
        final service = BiometricService(storage, biometric: port);

        expect(await service.enable(), BiometricAuthOutcome.unavailable);
        verifyNever(() => storage.setIsBiometricEnabled(enabled: any(named: 'enabled')));
      });
    });

    group('disable', () {
      test('clears the secure-storage flag', () async {
        when(() => storage.setIsBiometricEnabled(enabled: any(named: 'enabled')))
            .thenAnswer((_) async {});
        final service = BiometricService(storage, biometric: _FakeBiometricPort());

        await service.disable();
        verify(() => storage.setIsBiometricEnabled(enabled: false)).called(1);
      });
    });

    test('default constructor wires up the production adapter without throwing', () {
      // Sanity-check that the production-default path still constructs.
      // No port method is called here — the platform-channel adapter would
      // need a real device to do anything, but the constructor itself stays
      // pure.
      expect(BiometricService(storage), isNotNull);
    });
  });
}
