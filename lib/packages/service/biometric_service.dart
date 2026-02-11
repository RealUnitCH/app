import 'dart:developer' as developer;

import 'package:local_auth/local_auth.dart';
import 'package:realunit_wallet/packages/repository/settings_repository.dart';

/// Service for handling biometric authentication.
class BiometricService {
  final LocalAuthentication _auth = LocalAuthentication();

  BiometricService(this._settingsRepository);

  final SettingsRepository _settingsRepository;

  Future<bool> isAvailable() async {
    final canCheck = await _auth.canCheckBiometrics;
    final isSupported = await _auth.isDeviceSupported();
    return canCheck && isSupported;
  }

  bool get isEnabled => _settingsRepository.isBiometricEnabled;

  Future<bool> canUse() async => isEnabled && await isAvailable();

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
      _settingsRepository.isBiometricEnabled = true;
    }
    return success;
  }

  void disable() => _settingsRepository.isBiometricEnabled = false;
}
