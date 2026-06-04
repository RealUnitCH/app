import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:realunit_wallet/packages/service/biometric_service.dart';
import 'package:realunit_wallet/packages/storage/secure_storage.dart';
import 'package:realunit_wallet/screens/pin/constants/pin_constants.dart';

part 'setup_pin_state.dart';

class SetupPinCubit extends Cubit<SetupPinState> {
  SetupPinCubit(
    SecureStorage secureStorage,
    BiometricService biometricService,
  ) : _secureStorage = secureStorage,
      _biometricService = biometricService,
      super(const SetupPinState());

  final SecureStorage _secureStorage;
  final BiometricService _biometricService;

  String? _createPin;

  void addDigit(int digit) {
    if (state.currentPin.length >= pinLength) return;

    final newPin = '${state.currentPin}$digit';
    emit(state.copyWith(currentPin: newPin, mismatch: false));

    if (newPin.length == pinLength) {
      _onPinComplete(newPin);
    }
  }

  void deleteDigit() {
    if (state.currentPin.isEmpty) return;
    emit(
      state.copyWith(
        currentPin: state.currentPin.substring(0, state.currentPin.length - 1),
        mismatch: false,
      ),
    );
  }

  void _onPinComplete(String pin) {
    switch (state.mode) {
      case SetupPinMode.create:
        _createPin = pin;
        emit(
          state.copyWith(
            mode: SetupPinMode.confirm,
            currentPin: '',
          ),
        );
        break;
      case SetupPinMode.confirm:
        unawaited(_confirmPin(pin));
        break;
    }
  }

  Future<void> _confirmPin(String confirmPin) async {
    if (confirmPin == _createPin) {
      final salt = SecureStorage.generatePinSalt();
      final hash = await SecureStorage.hashPinAsync(confirmPin, salt);
      await Future.wait([
        _secureStorage.setPinSalt(salt),
        _secureStorage.setPinHash(hash),
      ]);
      emit(state.copyWith(isComplete: true));
    } else {
      emit(
        state.copyWith(
          currentPin: '',
          mismatch: true,
        ),
      );
    }
  }

  void reset() => emit(const SetupPinState());

  Future<bool> isBiometricAvailable() => _biometricService.isAvailable();

  Future<bool> enableBiometrics() => _biometricService.enable();
}
