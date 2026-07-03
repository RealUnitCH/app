import 'dart:developer' as developer;

import 'package:local_auth/local_auth.dart';
import 'package:realunit_wallet/packages/service/biometric/biometric_auth_outcome.dart';
import 'package:realunit_wallet/packages/service/biometric/biometric_port.dart';
import 'package:realunit_wallet/packages/service/biometric/biometric_service_adapter.dart';
import 'package:realunit_wallet/packages/storage/secure_storage.dart';

/// Service for handling biometric authentication.
///
/// All platform-channel work goes through a [BiometricPort]; production wiring
/// defaults to [BiometricServiceAdapter] (which talks to `local_auth`), tests
/// inject a fake.
class BiometricService {
  final BiometricPort _biometric;
  final SecureStorage _secureStorage;

  BiometricService(
    SecureStorage secureStorage, {
    BiometricPort? biometric,
  }) : _secureStorage = secureStorage,
       _biometric = biometric ?? BiometricServiceAdapter();

  Future<bool> isAvailable() async {
    final canCheck = await _biometric.canCheckBiometrics();
    final isSupported = await _biometric.isDeviceSupported();
    return canCheck && isSupported;
  }

  Future<bool> isEnabled() => _secureStorage.getIsBiometricEnabled();

  Future<bool> canUse() async => await isEnabled() && await isAvailable();

  /// Triggers the OS-level biometric prompt and reports the reason the attempt
  /// did or did not succeed.
  ///
  /// `local_auth` 3.x returns `true`/`false` from `authenticate` only for the
  /// success / plain-failure (or user-cancel) cases and throws a typed
  /// [LocalAuthException] for everything else (lockout, missing enrollment,
  /// unavailable hardware, …). We fold both channels into a single
  /// [BiometricAuthOutcome] so the caller can decide between staying silent and
  /// showing a targeted hint — the old bare `false` collapsed all of these into
  /// one indistinguishable failure.
  // @no-integration-test: drives the local_auth OS biometric prompt and maps
  //   its platform LocalAuthException codes onto BiometricAuthOutcome — only
  //   verifiable on a real device; the unit test mocks the exception surface.
  Future<BiometricAuthOutcome> authenticate() async {
    try {
      final authenticated = await _biometric.authenticate(
        localizedReason: 'Authenticate to unlock your wallet',
        biometricOnly: true,
        persistAcrossBackgrounding: true,
      );
      return authenticated ? BiometricAuthOutcome.success : BiometricAuthOutcome.failed;
    } on LocalAuthException catch (e) {
      return _mapException(e);
    } catch (e) {
      // Anything outside the plugin's typed surface is unexpected — surface it
      // as unavailable and keep a diagnostic breadcrumb.
      developer.log('Biometric authentication error: $e');
      return BiometricAuthOutcome.unavailable;
    }
  }

  /// Maps a `local_auth` 3.x [LocalAuthExceptionCode] onto a
  /// [BiometricAuthOutcome].
  ///
  /// The plugin documents its exception codes as *non-exhaustive* (new codes
  /// may be added without a breaking-change bump), so the switch deliberately
  /// falls through to a `default` rather than enumerating every value: unknown
  /// and genuine device errors both resolve to [BiometricAuthOutcome.unavailable]
  /// with a log line.
  BiometricAuthOutcome _mapException(LocalAuthException e) {
    switch (e.code) {
      // User-driven or transient interruptions the UI treats as a silent no-op:
      // a manual retry or the next auto-prompt is expected to succeed.
      case LocalAuthExceptionCode.userCanceled:
      case LocalAuthExceptionCode.userRequestedFallback:
      case LocalAuthExceptionCode.timeout:
      case LocalAuthExceptionCode.systemCanceled:
      case LocalAuthExceptionCode.authInProgress:
        return BiometricAuthOutcome.failed;

      // Too many failed attempts; recovers on its own once the device is
      // unlocked with the passcode.
      case LocalAuthExceptionCode.temporaryLockout:
        return BiometricAuthOutcome.temporarilyLocked;

      // Biometrics stay locked until a stronger auth (device passcode) succeeds.
      case LocalAuthExceptionCode.biometricLockout:
        return BiometricAuthOutcome.permanentlyLocked;

      // Nothing enrolled the OS could match against.
      case LocalAuthExceptionCode.noBiometricsEnrolled:
      case LocalAuthExceptionCode.noCredentialsSet:
        return BiometricAuthOutcome.notEnrolled;

      // Hardware missing / occupied, or the OS could not present its prompt.
      case LocalAuthExceptionCode.noBiometricHardware:
      case LocalAuthExceptionCode.biometricHardwareTemporarilyUnavailable:
      case LocalAuthExceptionCode.uiUnavailable:
        return BiometricAuthOutcome.unavailable;

      // deviceError, unknownError, and any future code the plugin adds: surface
      // as unavailable and keep the reason in the log.
      default:
        developer.log('Biometric authentication error: $e');
        return BiometricAuthOutcome.unavailable;
    }
  }

  /// Runs the OS prompt and, on success, persists the opt-in flag. Returns the
  /// full [BiometricAuthOutcome] so the caller can tell a deliberate cancel
  /// ([BiometricAuthOutcome.failed]) — which should stay silent — apart from a
  /// genuine error (lockout, missing enrollment, unavailable hardware) that
  /// warrants surfacing a hint.
  Future<BiometricAuthOutcome> enable() async {
    final outcome = await authenticate();
    if (outcome == BiometricAuthOutcome.success) {
      await _secureStorage.setIsBiometricEnabled(enabled: true);
    }
    return outcome;
  }

  Future<void> disable() => _secureStorage.setIsBiometricEnabled(enabled: false);
}
