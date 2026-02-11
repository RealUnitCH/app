import 'dart:developer' as developer;

import 'package:local_auth/local_auth.dart';

class BiometricService {
  final LocalAuthentication _auth = LocalAuthentication();

  Future<bool> isAvailable() async {
    final canCheck = await _auth.canCheckBiometrics;
    final isSupported = await _auth.isDeviceSupported();
    return canCheck && isSupported;
  }

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
}
