// ignore: implementation_imports
import 'package:bip39/src/wordlists/english.dart' as wordlist;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:realunit_wallet/packages/service/wallet_service.dart';

part 'validate_seed_state.dart';

class ValidateSeedCubit extends Cubit<ValidateSeedState> {
  ValidateSeedCubit(this._service) : super(ValidateSeedState.uncomplete);

  final WalletService _service;

  void checkSeedLength(String seed) {
    final seedWords = seed.split(' ').where((element) => element.isNotEmpty);
    if (seedWords.length == 12 && _containsAll(wordlist.WORDLIST, seedWords)) {
      emit(ValidateSeedState.complete);
    } else {
      emit(ValidateSeedState.uncomplete);
    }
  }

  void validateSeed(String seed) {
    if (_service.validateSeed(seed)) {
      emit(ValidateSeedState.valid);
    } else {
      emit(ValidateSeedState.invalid);
    }
  }

  bool _containsAll(Iterable a, Iterable b) {
    for (final element in b) {
      if (!a.contains(element)) return false;
    }
    return true;
  }
}
