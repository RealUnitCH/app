import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
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
    when(() => storage.readBiometricCryptoSentinel(any())).thenAnswer((_) async => 'sentinel');
    when(() => storage.writeBiometricCryptoSentinel(any(), any())).thenAnswer((_) async {});
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
      test('returns true with the expected prompt configuration', () async {
        final port = _FakeBiometricPort(authenticateResult: true);
        final service = BiometricService(storage, biometric: port);

        final result = await service.authenticate();

        expect(result.success, isTrue);
        expect(result.unwrappedSecret, 'sentinel');
        expect(port.authenticateCalls, 1);
        expect(port.lastReason, 'Authenticate to unlock your wallet');
        expect(port.lastBiometricOnly, isTrue);
        expect(port.lastPersistAcrossBackgrounding, isTrue);
      });

      test('returns false when the user cancels (port returns false)', () async {
        final port = _FakeBiometricPort(authenticateResult: false);
        final service = BiometricService(storage, biometric: port);

        final result = await service.authenticate();

        expect(result.success, isFalse);
        expect(result.unwrappedSecret, isNull);
      });

      test('returns false and swallows when the platform throws', () async {
        final port = _FakeBiometricPort(
          authenticateThrows: Exception('PlatformException(NotAvailable)'),
        );
        final service = BiometricService(storage, biometric: port);

        final result = await service.authenticate();

        expect(result.success, isFalse);
        expect(result.unwrappedSecret, isNull);
      });

      test('authenticateBoolean bridges to authenticate().success', () async {
        final port = _FakeBiometricPort(authenticateResult: true);
        final service = BiometricService(storage, biometric: port);

        expect(await service.authenticateBoolean(), isTrue);
        expect(port.authenticateCalls, 1);
      });
    });

    group('enable', () {
      test('persists the flag and returns true when authenticate succeeds', () async {
        when(
          () => storage.setIsBiometricEnabled(enabled: any(named: 'enabled')),
        ).thenAnswer((_) async {});
        final port = _FakeBiometricPort(authenticateResult: true);
        final service = BiometricService(storage, biometric: port);

        expect(await service.enable(), isTrue);
        verify(() => storage.setIsBiometricEnabled(enabled: true)).called(1);
      });

      test('seats a sentinel before persisting when none exists yet', () async {
        when(() => storage.readBiometricCryptoSentinel(any())).thenAnswer((_) async => null);
        when(
          () => storage.setIsBiometricEnabled(enabled: any(named: 'enabled')),
        ).thenAnswer((_) async {});
        final port = _FakeBiometricPort(authenticateResult: true);
        final service = BiometricService(storage, biometric: port);

        expect(await service.enable(), isTrue);
        verify(() => storage.writeBiometricCryptoSentinel(any(), any())).called(1);
        verify(() => storage.setIsBiometricEnabled(enabled: true)).called(1);
      });

      test('does not persist when authenticate fails', () async {
        final port = _FakeBiometricPort(authenticateResult: false);
        final service = BiometricService(storage, biometric: port);

        expect(await service.enable(), isFalse);
        verifyNever(() => storage.setIsBiometricEnabled(enabled: any(named: 'enabled')));
      });

      test('does not persist when the platform throws during authenticate', () async {
        final port = _FakeBiometricPort(authenticateThrows: Exception('boom'));
        final service = BiometricService(storage, biometric: port);

        expect(await service.enable(), isFalse);
        verifyNever(() => storage.setIsBiometricEnabled(enabled: any(named: 'enabled')));
      });
    });

    group('disable', () {
      test('clears the secure-storage flag', () async {
        when(
          () => storage.setIsBiometricEnabled(enabled: any(named: 'enabled')),
        ).thenAnswer((_) async {});
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

    test('BiometricAuthResult.forTesting exposes the provided payload', () {
      // ignore: prefer_const_constructors
      final result = BiometricAuthResult.forTesting(
        success: true,
        unwrappedSecret: 'test-secret',
      );

      expect(result.success, isTrue);
      expect(result.unwrappedSecret, 'test-secret');
    });
  });
}
