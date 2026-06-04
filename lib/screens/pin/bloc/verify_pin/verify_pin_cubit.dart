import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
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

  void addDigit(int digit) {
    if (state is VerifyPinTemporarilyLocked || state is VerifyPinLocked) return;
    if (state.pin.length == pinLength) return;
    emit(state.copyWith(pin: '${state.pin}$digit'));
    if (state.pin.length == pinLength) unawaited(checkPin());
  }

  void deleteDigit() {
    if (state is VerifyPinTemporarilyLocked || state is VerifyPinLocked) return;
    if (state.pin.isEmpty) return;
    emit(state.copyWith(pin: state.pin.substring(0, state.pin.length - 1)));
  }

  Future<void> checkPin() async {
    final isCorrect = await _secureStorage.verifyPin(state.pin);
    if (isCorrect) {
      if (enableLockout) await _secureStorage.resetPinLockout();
      emit(const VerifyPinSuccess());
    } else {
      if (!enableLockout) {
        emit(const VerifyPinFailure(failedAttempts: 0));
        return;
      }
      final attempts = await _secureStorage.getPinFailedAttempts() + 1;
      await _secureStorage.setPinFailedAttempts(attempts);
      await _emitLockState(attempts);
    }
  }

  void onLockExpired() {
    emit(VerifyPinState(failedAttempts: state.failedAttempts));
  }

  Future<void> checkBiometricAvailability() async {
    if (enableLockout) {
      final lockedUntil = await _secureStorage.getPinLockedUntil();
      if (lockedUntil != null) {
        if (DateTime.now().isBefore(lockedUntil)) {
          final attempts = await _secureStorage.getPinFailedAttempts();
          emit(VerifyPinTemporarilyLocked(failedAttempts: attempts, lockedUntil: lockedUntil));
          return;
        }
        await _secureStorage.setPinLockedUntil(null);
      }

      final attempts = await _secureStorage.getPinFailedAttempts();
      if (attempts >= permanentLockoutThreshold) {
        emit(VerifyPinLocked(failedAttempts: attempts));
        return;
      }
    }

    final canUse = await _biometricService.canUse();
    if (canUse) {
      final success = await _biometricService.authenticate();
      if (success) {
        if (enableLockout) await _secureStorage.resetPinLockout();
        emit(const VerifyPinSuccess());
      }
    }
  }

  Future<void> _emitLockState(int attempts) async {
    final duration = _lockoutDuration(attempts);
    if (duration == null) {
      emit(VerifyPinLocked(failedAttempts: attempts));
    } else if (duration > Duration.zero) {
      final lockedUntil = DateTime.now().add(duration);
      await _secureStorage.setPinLockedUntil(lockedUntil);
      emit(VerifyPinTemporarilyLocked(failedAttempts: attempts, lockedUntil: lockedUntil));
    } else {
      emit(VerifyPinFailure(failedAttempts: attempts));
    }
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
