import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:realunit_wallet/packages/storage/secure_storage.dart';

part 'verify_pin_state.dart';

class VerifyPinCubit extends Cubit<VerifyPinState> {
  VerifyPinCubit(this._secureStorage) : super(const VerifyPinState(pin: ''));

  final SecureStorage _secureStorage;
  final int maxPinLength = 4;

  void addDigit(int digit) {
    if (state.pin.length == maxPinLength) return;
    emit(state.copyWith(pin: '${state.pin}$digit'));
    if (state.pin.length == maxPinLength) checkPin();
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
}
