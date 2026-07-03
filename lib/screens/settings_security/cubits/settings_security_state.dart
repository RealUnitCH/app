part of 'settings_security_cubit.dart';

/// One-shot signal for the view to surface a transient failure (SnackBar).
/// Carried as a non-persisting field on [SettingsSecurityState]; see
/// [SettingsSecurityState.copyWith].
enum SettingsSecurityError { biometricEnableFailed }

class SettingsSecurityState extends Equatable {
  /// Biometric hardware is present and enrolled on this device.
  final bool biometricSupported;

  /// The user has opted into biometric unlock (persisted flag).
  final bool biometricEnabled;

  /// An enable/disable round-trip is in flight.
  final bool isBusy;

  /// Transient error signal for the UI. Deliberately not carried across emits:
  /// any [copyWith] that does not re-set it clears the signal, so an identical
  /// failure re-fires the view's listener.
  final SettingsSecurityError? error;

  const SettingsSecurityState({
    this.biometricSupported = false,
    this.biometricEnabled = false,
    this.isBusy = false,
    this.error,
  });

  SettingsSecurityState copyWith({
    bool? biometricSupported,
    bool? biometricEnabled,
    bool? isBusy,
    SettingsSecurityError? error,
  }) => SettingsSecurityState(
    biometricSupported: biometricSupported ?? this.biometricSupported,
    biometricEnabled: biometricEnabled ?? this.biometricEnabled,
    isBusy: isBusy ?? this.isBusy,
    error: error,
  );

  @override
  List<Object?> get props => [biometricSupported, biometricEnabled, isBusy, error];
}
