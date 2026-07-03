import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:realunit_wallet/packages/service/biometric/biometric_auth_outcome.dart';
import 'package:realunit_wallet/packages/service/biometric_service.dart';
import 'package:realunit_wallet/packages/storage/secure_storage.dart';
import 'package:realunit_wallet/screens/pin/constants/pin_constants.dart';

part 'verify_pin_state.dart';

class VerifyPinCubit extends Cubit<VerifyPinState> {
  VerifyPinCubit(
    SecureStorage secureStorage,
    BiometricService biometricService, {
    this.enableLockout = true,
  }) : _secureStorage = secureStorage,
       _biometricService = biometricService,
       super(const VerifyPinState());

  final SecureStorage _secureStorage;
  final BiometricService _biometricService;
  final bool enableLockout;

  // In-flight guards. Two rapid triggers (a double-tap on the final digit, or a
  // re-prompt racing an auto-prompt) must not hit the storage counter twice or
  // fire two OS prompts — the pending future is shared/dropped instead.
  Future<void>? _checkPinInFlight;
  Future<void>? _promptInFlight;

  bool get _isInputBlocked =>
      state is VerifyPinTemporarilyLocked ||
      state is VerifyPinLocked ||
      state is VerifyPinUnverifiable;

  void addDigit(int digit) {
    if (_isInputBlocked) return;
    if (state.pin.length == pinLength) return;
    emit(state.copyWith(pin: '${state.pin}$digit'));
    if (state.pin.length == pinLength) checkPin();
  }

  void deleteDigit() {
    if (_isInputBlocked) return;
    if (state.pin.isEmpty) return;
    emit(state.copyWith(pin: state.pin.substring(0, state.pin.length - 1)));
  }

  /// Coalesces concurrent checks onto a single storage round-trip so a
  /// double-submit of the completing digit increments the failure counter at
  /// most once (audit F-01).
  Future<void> checkPin() =>
      _checkPinInFlight ??= _checkPin().whenComplete(() => _checkPinInFlight = null);

  Future<void> _checkPin() async {
    final pin = state.pin;
    final previousAttempts = state.failedAttempts;
    final biometricStatus = state.biometricStatus;
    _safeEmit(VerifyPinVerifying(
      pin: pin,
      failedAttempts: previousAttempts,
      biometricStatus: biometricStatus,
    ));
    try {
      final result = await _secureStorage.verifyPin(pin);
      if (isClosed) return;
      // A biometric prompt racing this check may already have unlocked the
      // wallet; don't overwrite that success or count a failed attempt on top
      // of it.
      if (state is VerifyPinSuccess) return;
      switch (result) {
        case PinVerificationResult.correct:
          if (enableLockout) await _secureStorage.resetPinLockout();
          _safeEmit(VerifyPinSuccess(biometricStatus: biometricStatus));
        case PinVerificationResult.notVerifiable:
          // No stored hash/salt: no input could ever match. Steer to recovery
          // instead of burning a lockout attempt on an unwinnable check.
          _safeEmit(VerifyPinUnverifiable(
            failedAttempts: previousAttempts,
            biometricStatus: biometricStatus,
          ));
        case PinVerificationResult.wrong:
          if (!enableLockout) {
            _safeEmit(VerifyPinFailure(failedAttempts: 0, biometricStatus: biometricStatus));
            return;
          }
          final attempts = await _secureStorage.getPinFailedAttempts() + 1;
          // A biometric prompt racing this check may have reset the lockout and
          // emitted VerifyPinSuccess between the guard on the correct/return path
          // above and here. Re-check after each await before touching the counter
          // or the state: otherwise setPinFailedAttempts writes a stale non-zero
          // count back over the reset and _emitLockState clobbers the success.
          if (isClosed || state is VerifyPinSuccess) return;
          await _secureStorage.setPinFailedAttempts(attempts);
          if (isClosed || state is VerifyPinSuccess) return;
          await _emitLockState(attempts);
      }
    } catch (_) {
      // A hash/storage failure must not strand the user on the spinner with no
      // number pad. Restore the input so they can retry instead of dead-ending.
      _safeEmit(VerifyPinState(
        failedAttempts: previousAttempts,
        biometricStatus: biometricStatus,
      ));
    }
  }

  Future<void> onLockExpired() async {
    // The countdown timer is the only caller. If a biometric unlock (or any
    // other transition) already moved us off the temporary lock, there is
    // nothing to release — and emitting here would clobber a VerifyPinSuccess
    // and re-fire the OS prompt after the wallet already unlocked.
    if (state is! VerifyPinTemporarilyLocked) return;
    _safeEmit(VerifyPinState(
      failedAttempts: state.failedAttempts,
      biometricStatus: state.biometricStatus,
    ));
    // Biometrics were being offered before the lockout kicked in; re-offer them
    // the moment the timer clears so the user is not forced back to the pad.
    if (state.biometricStatus == BiometricStatus.available) {
      await promptBiometric();
    }
  }

  Future<void> checkBiometricAvailability() async {
    final biometricStatus = await _resolveBiometricStatus();
    await _emitLockOrIdle(biometricStatus);
    // Biometrics are OS-bound and cannot be brute-forced through the app, so we
    // auto-prompt even while the PIN lockout is active — a successful scan is
    // the deliberate escape hatch out of the lockout trap.
    if (biometricStatus == BiometricStatus.available) {
      await promptBiometric();
    }
  }

  Future<BiometricStatus> _resolveBiometricStatus() async {
    if (!await _biometricService.isEnabled()) return BiometricStatus.disabled;
    if (!await _biometricService.isAvailable()) return BiometricStatus.unavailable;
    return BiometricStatus.available;
  }

  /// Emits the current lock state (temporary / permanent) or a plain idle state,
  /// each carrying the resolved [biometricStatus]. Unlike the old flow it never
  /// returns before the biometric path, so a locked-out user can still unlock
  /// with biometrics.
  Future<void> _emitLockOrIdle(BiometricStatus biometricStatus) async {
    if (!enableLockout) {
      _safeEmit(state.copyWith(biometricStatus: biometricStatus));
      return;
    }

    final lockedUntil = await _secureStorage.getPinLockedUntil();
    if (lockedUntil != null) {
      if (DateTime.now().isBefore(lockedUntil)) {
        final attempts = await _secureStorage.getPinFailedAttempts();
        _safeEmit(VerifyPinTemporarilyLocked(
          failedAttempts: attempts,
          lockedUntil: lockedUntil,
          biometricStatus: biometricStatus,
        ));
        return;
      }
      await _secureStorage.setPinLockedUntil(null);
    }

    final attempts = await _secureStorage.getPinFailedAttempts();
    if (attempts >= permanentLockoutThreshold) {
      _safeEmit(VerifyPinLocked(failedAttempts: attempts, biometricStatus: biometricStatus));
      return;
    }
    // Preserve digits typed while the availability check awaited the storage
    // reads (copyWith keeps state.pin) instead of clobbering them with a fresh
    // state — matching the !enableLockout branch above.
    _safeEmit(state.copyWith(failedAttempts: attempts, biometricStatus: biometricStatus));
  }

  /// Triggers the OS biometric prompt and maps its outcome. Public so both the
  /// auto-prompt on page load and the manual button use the same guarded path.
  Future<void> promptBiometric() =>
      _promptInFlight ??= _promptBiometric().whenComplete(() => _promptInFlight = null);

  Future<void> _promptBiometric() async {
    final outcome = await _biometricService.authenticate();
    if (isClosed) return;
    // A parallel PIN check may already have unlocked the wallet; don't emit a
    // second terminal/status state over that success — a re-emitted
    // VerifyPinSuccess re-fires onAuthenticated, a status change re-enables the
    // pad, and the lockout reset would run twice.
    if (state is VerifyPinSuccess) return;
    switch (outcome) {
      case BiometricAuthOutcome.success:
        if (enableLockout) await _secureStorage.resetPinLockout();
        _safeEmit(VerifyPinSuccess(biometricStatus: state.biometricStatus));
      case BiometricAuthOutcome.failed:
        // Plain scan failure or user cancel: stay silent, keep the button.
        break;
      case BiometricAuthOutcome.temporarilyLocked:
        _setBiometricStatus(BiometricStatus.temporarilyLocked);
      case BiometricAuthOutcome.permanentlyLocked:
        _setBiometricStatus(BiometricStatus.permanentlyLocked);
      case BiometricAuthOutcome.notEnrolled:
        _setBiometricStatus(BiometricStatus.notEnrolled);
      case BiometricAuthOutcome.unavailable:
        _setBiometricStatus(BiometricStatus.unavailable);
    }
  }

  // Equal states are deduped by bloc, so no manual short-circuit is needed.
  void _setBiometricStatus(BiometricStatus status) => _safeEmit(_withBiometricStatus(state, status));

  /// Rebuilds the current state with a new [biometricStatus] while preserving
  /// its concrete subclass (the base `copyWith` would flatten a locked,
  /// unverifiable or in-flight state back to a plain one and re-enable the pad).
  /// Every subclass a biometric prompt can race is enumerated; only the plain
  /// base state falls through to `copyWith`.
  VerifyPinState _withBiometricStatus(VerifyPinState current, BiometricStatus status) =>
      switch (current) {
        VerifyPinVerifying s => VerifyPinVerifying(
          pin: s.pin,
          failedAttempts: s.failedAttempts,
          biometricStatus: status,
        ),
        VerifyPinSuccess _ => VerifyPinSuccess(biometricStatus: status),
        VerifyPinTemporarilyLocked s => VerifyPinTemporarilyLocked(
          failedAttempts: s.failedAttempts,
          lockedUntil: s.lockedUntil,
          biometricStatus: status,
        ),
        VerifyPinLocked s =>
          VerifyPinLocked(failedAttempts: s.failedAttempts, biometricStatus: status),
        VerifyPinUnverifiable s =>
          VerifyPinUnverifiable(failedAttempts: s.failedAttempts, biometricStatus: status),
        VerifyPinFailure s =>
          VerifyPinFailure(failedAttempts: s.failedAttempts, biometricStatus: status),
        _ => current.copyWith(biometricStatus: status),
      };

  Future<void> _emitLockState(int attempts) async {
    final duration = _lockoutDuration(attempts);
    if (duration == null) {
      _safeEmit(VerifyPinLocked(failedAttempts: attempts, biometricStatus: state.biometricStatus));
    } else if (duration > Duration.zero) {
      final lockedUntil = DateTime.now().add(duration);
      await _secureStorage.setPinLockedUntil(lockedUntil);
      // A biometric unlock racing this write may already have landed
      // VerifyPinSuccess; don't clobber it with a lock state (completes the
      // wrong-branch cross-guard for the temporary-lock await point).
      if (isClosed || state is VerifyPinSuccess) return;
      _safeEmit(VerifyPinTemporarilyLocked(
        failedAttempts: attempts,
        lockedUntil: lockedUntil,
        biometricStatus: state.biometricStatus,
      ));
    } else {
      _safeEmit(VerifyPinFailure(failedAttempts: attempts, biometricStatus: state.biometricStatus));
    }
  }

  /// Guards every async-path emit. The OS biometric prompt (and the wallet load
  /// that follows a successful unlock) can outlive this cubit when the app
  /// re-locks and replaces the route; emitting on a closed cubit throws a
  /// StateError, so drop late emits instead.
  void _safeEmit(VerifyPinState state) {
    if (!isClosed) emit(state);
  }

  Duration? _lockoutDuration(int attempts) => switch (attempts) {
    5 => const Duration(minutes: 1),
    6 => const Duration(minutes: 2),
    7 => const Duration(minutes: 5),
    8 => const Duration(minutes: 10),
    _ when attempts >= permanentLockoutThreshold => null,
    _ => Duration.zero,
  };
}
