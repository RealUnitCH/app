import 'package:realunit_wallet/packages/storage/database.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class PinState {
  final String pin;
  final bool wrongTry;

  PinState({required this.pin, required this.wrongTry});

  PinState copyWith({
    String? pin,
    bool? wrongTry,
  }) =>
      PinState(
        pin: pin ?? this.pin,
        wrongTry: wrongTry ?? this.wrongTry,
      );
}

class PinCubit extends Cubit<PinState> {
  PinCubit(this.maxPinLength, this.onSuccess) : super(PinState(pin: "", wrongTry: false));

  final int maxPinLength;
  final Function (String database) onSuccess;

  void amountAdd(int index) {
    if (state.pin.length == maxPinLength) return;
    emit(state.copyWith(pin: "${state.pin}$index", wrongTry: false));
    if (state.pin.length == maxPinLength) checkPin();
  }

  void amountDelete() =>
      emit(state.copyWith(pin: state.pin.substring(0, state.pin.length - 1)));

  Future<void> checkPin() async {
    final pin = state.pin;
    final isCorrectPin = await tryOpeningDatabase(pin);
    emit(state.copyWith(pin: "", wrongTry: !isCorrectPin));

    if(isCorrectPin) onSuccess.call(pin);
  }
}
