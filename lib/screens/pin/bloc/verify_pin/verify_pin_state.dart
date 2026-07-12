part of 'verify_pin_cubit.dart';

/// Availability of the biometric unlock path, tracked alongside the PIN state
/// so the page can decide whether to show the Face-ID/biometrics button and,
/// when the feature is enabled but unusable, which explanatory hint to render.
///
/// The old code offered biometrics exactly once on page build and silently
/// skipped them for any non-available reason, which stranded users behind the
/// lockout cascade. Carrying the reason as a distinct status lets the UI keep
/// the button offered whenever the OS can actually present it and surface a
/// targeted hint otherwise.
enum BiometricStatus {
  /// Not resolved yet (before the first availability check runs).
  unknown,

  /// The user has not turned biometric unlock on for this wallet.
  disabled,

  /// Enabled and the OS can present a prompt right now — show the button.
  available,

  /// Locked after too many biometric attempts; recovers once the device is
  /// unlocked with the passcode.
  temporarilyLocked,

  /// Locked until a stronger authentication (device passcode) succeeds.
  permanentlyLocked,

  /// Nothing enrolled the OS could match against anymore.
  notEnrolled,

  /// Momentarily unusable (no/occupied hardware or the OS could not present
  /// its prompt).
  unavailable,
}

class VerifyPinState extends Equatable {
  final String pin;
  final int failedAttempts;
  final BiometricStatus biometricStatus;

  const VerifyPinState({
    this.pin = '',
    this.failedAttempts = 0,
    this.biometricStatus = BiometricStatus.unknown,
  });

  VerifyPinState copyWith({
    String? pin,
    int? failedAttempts,
    BiometricStatus? biometricStatus,
  }) => VerifyPinState(
    pin: pin ?? this.pin,
    failedAttempts: failedAttempts ?? this.failedAttempts,
    biometricStatus: biometricStatus ?? this.biometricStatus,
  );

  @override
  List<Object?> get props => [pin, failedAttempts, biometricStatus];
}

class VerifyPinVerifying extends VerifyPinState {
  const VerifyPinVerifying({
    required super.pin,
    super.failedAttempts,
    super.biometricStatus,
  });
}

class VerifyPinSuccess extends VerifyPinState {
  const VerifyPinSuccess({super.biometricStatus}) : super(pin: '');
}

class VerifyPinFailure extends VerifyPinState {
  const VerifyPinFailure({
    required super.failedAttempts,
    super.biometricStatus,
  }) : super(pin: '');
}

class VerifyPinTemporarilyLocked extends VerifyPinState {
  final DateTime lockedUntil;

  const VerifyPinTemporarilyLocked({
    required super.failedAttempts,
    required this.lockedUntil,
    super.biometricStatus,
  }) : super(pin: '');

  @override
  List<Object?> get props => [...super.props, lockedUntil];
}

class VerifyPinLocked extends VerifyPinState {
  const VerifyPinLocked({
    required super.failedAttempts,
    super.biometricStatus,
  }) : super(pin: '');
}

/// The stored PIN hash/salt is missing, so no entered PIN can ever match. This
/// is a storage fault, not a wrong guess: the pad is disabled and no failed
/// attempt is counted. Recovery is the "Forgot PIN?" flow; biometrics, if
/// enabled, still unlock — they authenticate against the OS, not the stored hash.
class VerifyPinUnverifiable extends VerifyPinState {
  const VerifyPinUnverifiable({
    super.failedAttempts,
    super.biometricStatus,
  }) : super(pin: '');
}
