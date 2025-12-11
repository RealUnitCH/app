// ignore: implementation_imports
import 'package:bip39/src/wordlists/english.dart' as wordlist;
import 'package:flutter_bloc/flutter_bloc.dart';

class ValidateSeedCubit extends Cubit<ValidateSeedState> {
  ValidateSeedCubit() : super(ValidateSeedState.uncomplete);

  void validateSeed(String seed) {
    final seedWords = seed.split(" ").where((element) => element.isNotEmpty);
    if (seedWords.length == 12 && _containsAll(wordlist.WORDLIST, seedWords)) {
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

  bool _containsAll(Iterable a, Iterable b) {
    for (final element in b) {
      if (!a.contains(element)) return false;
    }
    return true;
  }
}

enum ValidateSeedState {
  valid,
  uncomplete,
}
