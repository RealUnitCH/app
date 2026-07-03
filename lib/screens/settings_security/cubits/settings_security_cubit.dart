import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:realunit_wallet/packages/service/biometric/biometric_auth_outcome.dart';
import 'package:realunit_wallet/packages/service/biometric_service.dart';

part 'settings_security_state.dart';

/// Backs the Security settings page: exposes whether biometric unlock is
/// available on this device and whether the user has opted into it, and
/// drives the enable/disable toggle through [BiometricService].
class SettingsSecurityCubit extends Cubit<SettingsSecurityState> {
  final BiometricService _biometricService;

  SettingsSecurityCubit(BiometricService biometricService)
    : _biometricService = biometricService,
      super(const SettingsSecurityState());

  /// Hydrates hardware support (present + enrolled) and the persisted opt-in
  /// flag so the view can decide whether to show the toggle and its position.
  Future<void> init() async {
    final supported = await _biometricService.isAvailable();
    final enabled = await _biometricService.isEnabled();
    if (isClosed) return;
    emit(state.copyWith(biometricSupported: supported, biometricEnabled: enabled));
  }

  /// Turns biometric unlock on or off. Enabling triggers the OS prompt via
  /// [BiometricService.enable]. A deliberate cancel ([BiometricAuthOutcome.failed])
  /// rolls the toggle back silently — the user chose not to; only a genuine
  /// failure (lockout, missing enrollment, unavailable hardware) raises a
  /// one-shot [SettingsSecurityError] for the view to surface.
  ///
  /// Guards against re-entrancy: a tap while a previous round-trip is still in
  /// flight is ignored so the OS prompt is not stacked.
  Future<void> toggleBiometrics({required bool enabled}) async {
    if (state.isBusy) return;
    emit(state.copyWith(isBusy: true));
    try {
      if (enabled) {
        final outcome = await _biometricService.enable();
        if (isClosed) return;
        final success = outcome == BiometricAuthOutcome.success;
        // A plain cancel/scan failure stays silent; anything else is a real fault.
        final failedSilently = outcome == BiometricAuthOutcome.failed;
        emit(
          state.copyWith(
            biometricEnabled: success,
            isBusy: false,
            error: success || failedSilently ? null : SettingsSecurityError.biometricEnableFailed,
          ),
        );
      } else {
        await _biometricService.disable();
        if (isClosed) return;
        emit(state.copyWith(biometricEnabled: false, isBusy: false));
      }
    } catch (_) {
      // A keychain write failure must not strand the toggle on the spinner with
      // the re-entrancy guard (isBusy) latched — clear it and surface the fault
      // instead of dead-ending, mirroring the PIN cubits' storage-failure path.
      if (isClosed) return;
      emit(state.copyWith(isBusy: false, error: SettingsSecurityError.biometricEnableFailed));
    }
  }
}
