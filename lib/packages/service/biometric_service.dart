import 'dart:developer' as developer;

import 'package:realunit_wallet/packages/service/biometric/biometric_port.dart';
import 'package:realunit_wallet/packages/service/biometric/biometric_service_adapter.dart';
import 'package:realunit_wallet/packages/storage/secure_storage.dart';

/// Service for handling biometric authentication.
///
/// All platform-channel work goes through a [BiometricPort]; production wiring
/// defaults to [BiometricServiceAdapter] (which talks to `local_auth`), tests
/// inject a fake.
class BiometricService {
  final BiometricPort _biometric;
  final SecureStorage _secureStorage;

  BiometricService(
    SecureStorage secureStorage, {
    BiometricPort? biometric,
  }) : _secureStorage = secureStorage,
       _biometric = biometric ?? BiometricServiceAdapter();

  Future<bool> isAvailable() async {
    final canCheck = await _biometric.canCheckBiometrics();
    final isSupported = await _biometric.isDeviceSupported();
    return canCheck && isSupported;
  }

  Future<bool> isEnabled() => _secureStorage.getIsBiometricEnabled();

  Future<bool> canUse() async => await isEnabled() && await isAvailable();

  Future<bool> authenticate() async {
    try {
      return await _biometric.authenticate(
        localizedReason: 'Authenticate to unlock your wallet',
        biometricOnly: true,
        persistAcrossBackgrounding: true,
      );
    } catch (e) {
      developer.log('Biometric authentication error: $e');
      return false;
    }
  }

  Future<bool> enable() async {
    final success = await authenticate();
    if (success) {
      await _secureStorage.setIsBiometricEnabled(enabled: true);
    }
    return success;
  }

  Future<void> disable() => _secureStorage.setIsBiometricEnabled(enabled: false);
}
