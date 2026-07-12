import 'package:local_auth/local_auth.dart';
import 'package:realunit_wallet/packages/service/biometric/biometric_port.dart';

/// Production [BiometricPort] implementation backed by `package:local_auth`.
///
/// Every method forwards directly to a [LocalAuthentication] instance — no
/// behaviour is added, so swapping this adapter for a fake in tests preserves
/// the runtime contract that [BiometricService] depends on.
///
/// The forwarding bodies themselves cannot be reached from `flutter test`
/// without a real `local_auth_platform_interface` fake: the boundary the
/// adapter abstracts away IS the platform channel. The forwarders are
/// therefore excluded from line coverage with a block-level
/// `coverage:ignore` — Bug-class risk is zero (1:1 delegation).
// @no-integration-test: thin 1:1 wrapper around `package:local_auth`;
//   no behaviour to verify beyond what the SDK already guarantees.
class BiometricServiceAdapter implements BiometricPort {
  final LocalAuthentication _auth;

  BiometricServiceAdapter([LocalAuthentication? auth]) : _auth = auth ?? LocalAuthentication();

  // coverage:ignore-start
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
  // coverage:ignore-end
}
