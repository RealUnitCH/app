import 'package:local_auth/local_auth.dart';
import 'package:realunit_wallet/packages/service/biometric/biometric_port.dart';

/// Production [BiometricPort] implementation backed by `package:local_auth`.
///
/// Every method forwards directly to a [LocalAuthentication] instance — no
/// behaviour is added, so swapping this adapter for a fake in tests preserves
/// the runtime contract that [BiometricService] depends on.
class BiometricServiceAdapter implements BiometricPort {
  final LocalAuthentication _auth;

  BiometricServiceAdapter([LocalAuthentication? auth]) : _auth = auth ?? LocalAuthentication();

  @override
  Future<bool> canCheckBiometrics() => _auth.canCheckBiometrics;

  @override
  Future<bool> isDeviceSupported() => _auth.isDeviceSupported();

  @override
  Future<bool> authenticate({
    required String localizedReason,
    required bool biometricOnly,
    required bool persistAcrossBackgrounding,
  }) => _auth.authenticate(
    localizedReason: localizedReason,
    biometricOnly: biometricOnly,
    persistAcrossBackgrounding: persistAcrossBackgrounding,
  );
}
