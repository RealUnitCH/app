import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:realunit_wallet/packages/repository/settings_repository.dart';
import 'package:realunit_wallet/packages/service/biometric_service.dart';
import 'package:realunit_wallet/packages/storage/secure_storage.dart';
import 'package:realunit_wallet/screens/pin/constants/pin_constants.dart';

part 'verify_pin_state.dart';

class VerifyPinCubit extends Cubit<VerifyPinState> {
  VerifyPinCubit(
    this._secureStorage,
    this._settingsRepository,
    this._biometricService,
  ) : super(const VerifyPinState(pin: '', isBiometricAvailable: false));

  final SecureStorage _secureStorage;
  final SettingsRepository _settingsRepository;
  final BiometricService _biometricService;

  void addDigit(int digit) {
    if (state.pin.length == pinLength) return;
    emit(state.copyWith(pin: '${state.pin}$digit'));
    if (state.pin.length == pinLength) checkPin();
  }

  void deleteDigit() {
    if (state.pin.isEmpty) return;
    emit(state.copyWith(pin: state.pin.substring(0, state.pin.length - 1)));
  }

  Future<void> checkPin() async {
    final storedHash = await _secureStorage.getPinHash();
    final enteredHash = SecureStorage.hashPin(state.pin);
    final isCorrect = storedHash == enteredHash;

    if (isCorrect) {
      emit(const VerifyPinSuccess());
    } else {
      emit(const VerifyPinFailure());
    }
  }

  Future<void> checkBiometricAvailability() async {
    final isBiometricEnabled = _settingsRepository.isBiometricEnabled;
    if (!isBiometricEnabled) {
      emit(state.copyWith(isBiometricAvailable: false));
      return;
    }

    final isAvailable = await _biometricService.isAvailable();
    emit(state.copyWith(isBiometricAvailable: isAvailable));

    if (isAvailable) {
      await authenticateWithBiometrics();
    }
  }

  Future<void> authenticateWithBiometrics() async {
    final success = await _biometricService.authenticate();
    if (success) {
      emit(const VerifyPinSuccess());
    }
  }
}
