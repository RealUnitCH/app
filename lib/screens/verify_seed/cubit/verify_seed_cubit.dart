import 'dart:math';

import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:realunit_wallet/packages/service/wallet_service.dart';
import 'package:realunit_wallet/packages/wallet/wallet.dart';
import 'package:realunit_wallet/widgets/mnemonic_field.dart';

part 'verify_seed_state.dart';

class VerifySeedCubit extends Cubit<VerifySeedState> {
  VerifySeedCubit(SoftwareWallet wallet, WalletService walletService)
    : _wallet = wallet,
      _walletService = walletService,
      super(const VerifySeedState()) {
    _initVerification();
  }

  final SoftwareWallet _wallet;
  final WalletService _walletService;

  void _initVerification() {
    final indices = <int>{};
    final seedLength = _wallet.seed.seedWords.length;
    while (indices.length < 4) {
      indices.add(Random().nextInt(seedLength));
    }
    final sortedIndices = indices.toList()..sort();

    emit(
      state.copyWith(
        wordIndices: sortedIndices,
        enteredWords:
            kDebugMode // Pre-fill words in debug mode
            ? sortedIndices.map((i) => _wallet.seed.seedWords[i]).toList()
            : List.filled(4, ''),
      ),
    );
  }

  void updateWord(int verificationIndex, String word) {
    final updatedWords = List<String>.from(state.enteredWords);
    updatedWords[verificationIndex] = word.trim().toLowerCase();
    emit(
      state.copyWith(
        enteredWords: updatedWords,
        hasError: false,
      ),
    );
  }

  Future<bool> verify() async {
    final seedWords = _wallet.seed.seedWords;

    for (int i = 0; i < state.wordIndices.length; i++) {
      final expectedWord = seedWords[state.wordIndices.elementAt(i)].toLowerCase();
      final enteredWord = state.enteredWords.elementAt(i).toLowerCase();

      if (expectedWord != enteredWord) {
        emit(state.copyWith(hasError: true));
        return false;
      }
    }

    await _walletService.setCurrentWallet(_wallet.id);
    emit(state.copyWith(isVerified: true));
    return true;
  }
}
