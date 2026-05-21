import 'dart:developer' as developer;
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

  /// The draft wallet handed in by `CreateWalletCubit`. Until [verify]
  /// succeeds and `WalletService.commitGeneratedWallet` lands the row, the
  /// id is the `0` sentinel — it must NOT be passed to
  /// `setCurrentWallet` directly; commit first, use the returned id.
  SoftwareWallet _wallet;
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
    // Re-entrancy guard. The button's `onPressed` is fire-and-forget, so a
    // second tap can land while the first commit is still in flight (or
    // already done). A second commit would also trip
    // `commitGeneratedWallet`'s `assert(draft.id == 0)` on the now-committed
    // `_wallet`. Bail out and let the first call own the transition.
    if (state.isVerifying || state.isVerified) return false;

    final seedWords = _wallet.seed.seedWords;

    for (int i = 0; i < state.wordIndices.length; i++) {
      final expectedWord = seedWords[state.wordIndices.elementAt(i)].toLowerCase();
      final enteredWord = state.enteredWords.elementAt(i).toLowerCase();

      if (expectedWord != enteredWord) {
        emit(state.copyWith(hasError: true));
        return false;
      }
    }

    // Commit the draft mnemonic to disk BEFORE marking it current — the
    // wallet handed in by `CreateWalletCubit` is the in-memory-only draft
    // produced by `WalletService.generateUncommittedSeedWallet` (id == 0).
    // Persisting at confirm time means a regenerate triggered by an
    // app-hidden cycle in the create flow never leaves an orphan row in
    // `walletInfos`. The user only reaches this branch by typing the four
    // requested words correctly, so the seed they kept is the seed we
    // store.
    emit(state.copyWith(isVerifying: true, commitFailed: false));
    try {
      final committed = await _walletService.commitGeneratedWallet(_wallet);
      // Async-tail guard: the AppBar back button on the verify-seed screen
      // stays enabled while `isVerifying` is true, so the user can pop the
      // page (closing the cubit) before the commit resolves. A post-close
      // `emit` would throw `StateError`. Matches the
      // `connect_bitbox_cubit` / `create_wallet_cubit` / `kyc_cubit`
      // pattern. The committed row is already persisted at this point —
      // dropping the success emission is acceptable; the user simply
      // restarts onboarding and re-uses the existing wallet.
      if (isClosed) return false;
      _wallet = committed;
      await _walletService.setCurrentWallet(committed.id);
      if (isClosed) return false;
      emit(
        state.copyWith(
          isVerifying: false,
          isVerified: true,
          committedWallet: committed,
        ),
      );
      return true;
    } catch (e, stack) {
      // Persisting the wallet failed or hung-then-threw. Surface a retry
      // affordance instead of leaving the screen stuck on a plain
      // "Bestätigen" with no feedback — `verify` must never resolve into a
      // state that is neither success nor a visible error.
      developer.log(
        'Failed to commit verified wallet',
        error: e,
        stackTrace: stack,
      );
      if (isClosed) return false;
      emit(state.copyWith(isVerifying: false, commitFailed: true));
      return false;
    }
  }
}
