/// Thin boundary in front of the `local_auth` plugin so [BiometricService]
/// can be unit-tested without instantiating a platform channel.
///
/// The default production wiring is [BiometricServiceAdapter], which delegates
/// every call to a real [LocalAuthentication]. Tests inject a fake instead.
abstract class BiometricPort {
  /// Whether the device can perform biometric checks at all (hardware present
  /// and configured).
  Future<bool> canCheckBiometrics();

  /// Whether the operating system reports the device as supported by the
  /// `local_auth` plugin.
  Future<bool> isDeviceSupported();

  /// Triggers the OS-level biometric prompt. Returns `true` if the user
  /// authenticated successfully.
  ///
  /// `biometricOnly` and `persistAcrossBackgrounding` mirror the underlying
  /// `LocalAuthentication.authenticate` options that production wiring uses.
  Future<bool> authenticate({
    required String localizedReason,
    required bool biometricOnly,
    required bool persistAcrossBackgrounding,
  });
}
