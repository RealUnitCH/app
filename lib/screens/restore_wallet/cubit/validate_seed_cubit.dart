import 'package:flutter_bloc/flutter_bloc.dart';

class ValidateSeedCubit extends Cubit<ValidateSeedState> {
  ValidateSeedCubit() : super(ValidateSeedState.uncomplete);

  void validateSeed(String seed) {
    final seedWords = seed.split(" ").where((element) => element.isNotEmpty);
    if (seedWords.length == 12) {
      // if (bip39.validateMnemonic(seed)) {
      emit(ValidateSeedState.valid);
      return;
      // } else {
      //   emit(ValidateSeedState.unvalid);
      //   return;
      // }
    }
    emit(ValidateSeedState.uncomplete);
  }
}

enum ValidateSeedState {
  valid,
  uncomplete,
}
