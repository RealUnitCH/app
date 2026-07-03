/// Result of a single biometric authentication attempt.
///
/// Replaces the previous `Future<bool>` return of
/// `BiometricService.authenticate`: a bare boolean forced every non-success
/// reason (OS lockout, re-enrollment, missing hardware, user cancel) into an
/// indistinguishable `false`, so the UI could never explain why biometrics did
/// not unlock the wallet. The distinct outcomes below let the caller show a
/// targeted hint or stay silent.
enum BiometricAuthOutcome {
  /// The user authenticated successfully — unlock and clear the PIN lockout.
  success,

  /// The attempt did not succeed but carries no side effect the UI should
  /// surface: either the scan simply failed or the user dismissed/cancelled the
  /// prompt. Treated identically by the UI — stay silent, keep the button so a
  /// retry is one tap away.
  failed,

  /// Biometrics are locked after too many failed attempts and will recover on
  /// their own; unlocking the device once with the passcode clears it.
  temporarilyLocked,

  /// Biometrics are locked until a stronger authentication (the device
  /// passcode) succeeds; they will not recover from a biometric retry alone.
  permanentlyLocked,

  /// The device has no biometrics (or credentials) enrolled the OS could match
  /// against — the feature is configured in the app but no longer usable.
  notEnrolled,

  /// Biometrics are momentarily unusable for any other reason (no/occupied
  /// hardware, the OS could not present its prompt, or an unexpected error).
  unavailable,
}
