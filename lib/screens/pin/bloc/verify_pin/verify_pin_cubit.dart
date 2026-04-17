import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:realunit_wallet/packages/repository/settings_repository.dart';
import 'package:realunit_wallet/packages/service/biometric_service.dart';
import 'package:realunit_wallet/packages/storage/secure_storage.dart';
import 'package:realunit_wallet/screens/pin/constants/pin_constants.dart';

part 'verify_pin_state.dart';

class VerifyPinCubit extends Cubit<VerifyPinState> {
  VerifyPinCubit(
    SecureStorage secureStorage,
    SettingsRepository settingsRepository,
    BiometricService biometricService, {
    this.enableLockout = false,
  }) : _secureStorage = secureStorage,
       _settingsRepository = settingsRepository,
       _biometricService = biometricService,
       super(const VerifyPinState());

  final SecureStorage _secureStorage;
  final SettingsRepository _settingsRepository;
  final BiometricService _biometricService;
  final bool enableLockout;

  void addDigit(int digit) {
    if (state is VerifyPinTemporarilyLocked || state is VerifyPinLocked) return;
    if (state.pin.length == pinLength) return;
    emit(state.copyWith(pin: '${state.pin}$digit'));
    if (state.pin.length == pinLength) checkPin();
  }

  void deleteDigit() {
    if (state is VerifyPinTemporarilyLocked || state is VerifyPinLocked) return;
    if (state.pin.isEmpty) return;
    emit(state.copyWith(pin: state.pin.substring(0, state.pin.length - 1)));
  }

  Future<void> checkPin() async {
    final isCorrect = await _secureStorage.verifyPin(state.pin);
    if (isCorrect) {
      if (enableLockout) _settingsRepository.resetPinLockout();
      emit(const VerifyPinSuccess());
    } else {
      if (!enableLockout) {
        emit(const VerifyPinFailure(failedAttempts: 0));
        return;
      }
      final attempts = _settingsRepository.pinFailedAttempts + 1;
      _settingsRepository.pinFailedAttempts = attempts;
      _emitLockState(attempts);
    }
  }

  void onLockExpired() {
    emit(VerifyPinState(failedAttempts: state.failedAttempts));
  }

  Future<void> checkBiometricAvailability() async {
    if (enableLockout) {
      final lockedUntil = _settingsRepository.pinLockedUntil;
      if (lockedUntil != null) {
        if (DateTime.now().isBefore(lockedUntil)) {
          final attempts = _settingsRepository.pinFailedAttempts;
          emit(VerifyPinTemporarilyLocked(failedAttempts: attempts, lockedUntil: lockedUntil));
          return;
        }
        _settingsRepository.pinLockedUntil = null;
      }

      final attempts = _settingsRepository.pinFailedAttempts;
      if (attempts >= permanentLockoutThreshold) {
        emit(VerifyPinLocked(failedAttempts: attempts));
        return;
      }
    }

    final canUse = await _biometricService.canUse();
    if (canUse) {
      final success = await _biometricService.authenticate();
      if (success) {
        emit(const VerifyPinSuccess());
      }
    }
  }

  void _emitLockState(int attempts) {
    final duration = _lockoutDuration(attempts);
    if (duration == null) {
      emit(VerifyPinLocked(failedAttempts: attempts));
    } else if (duration > Duration.zero) {
      final lockedUntil = DateTime.now().add(duration);
      _settingsRepository.pinLockedUntil = lockedUntil;
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
