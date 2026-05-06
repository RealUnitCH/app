import 'dart:developer' as developer;

import 'package:local_auth/local_auth.dart';
import 'package:realunit_wallet/packages/storage/secure_storage.dart';

/// Service for handling biometric authentication.
class BiometricService {
  final LocalAuthentication _auth = LocalAuthentication();

  BiometricService(
    SecureStorage secureStorage,
  ) : _secureStorage = secureStorage;

  final SecureStorage _secureStorage;

  Future<bool> isAvailable() async {
    final canCheck = await _auth.canCheckBiometrics;
    final isSupported = await _auth.isDeviceSupported();
    return canCheck && isSupported;
  }

  Future<bool> isEnabled() => _secureStorage.getIsBiometricEnabled();

  Future<bool> canUse() async => await isEnabled() && await isAvailable();

  Future<bool> authenticate() async {
    try {
      return await _auth.authenticate(
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
