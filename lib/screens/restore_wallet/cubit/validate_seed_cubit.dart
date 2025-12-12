import 'package:bip39/bip39.dart' as bip39;
// ignore: implementation_imports
import 'package:bip39/src/wordlists/english.dart' as wordlist;
import 'package:flutter_bloc/flutter_bloc.dart';

class ValidateSeedCubit extends Cubit<ValidateSeedState> {
  ValidateSeedCubit() : super(ValidateSeedState.uncomplete);

  void checkSeedLength(String seed) {
    final seedWords = seed.split(" ").where((element) => element.isNotEmpty);
    if (seedWords.length == 12 && _containsAll(wordlist.WORDLIST, seedWords)) {
      emit(ValidateSeedState.complete);
    } else {
      emit(ValidateSeedState.uncomplete);
    }
  }

  void validateSeed(String seed) {
    if (bip39.validateMnemonic(seed)) {
      emit(ValidateSeedState.valid);
      return;
    } else {
      emit(ValidateSeedState.invalid);
      return;
    }
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
  invalid,
  complete,
  uncomplete,
}
