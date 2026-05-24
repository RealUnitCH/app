import 'dart:developer' as developer;
import 'dart:math';

import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:realunit_wallet/packages/service/wallet_service.dart';
import 'package:realunit_wallet/packages/wallet/wallet.dart';

part 'verify_seed_state.dart';

class VerifySeedCubit extends Cubit<VerifySeedState> with WidgetsBindingObserver {
  VerifySeedCubit(SeedDraft draft, WalletService walletService)
    : _draft = draft,
      _walletService = walletService,
      super(const VerifySeedState()) {
    // Lifecycle observer for BL-023 — when the user backgrounds the
    // app mid-verify, the SeedDraft is disposed and the cubit emits
    // `VerifySeedAborted` so the screen can route back to the create
    // flow on resume. The legacy behaviour leaked the mnemonic for the
    // full duration of the verify-seed screen even after app hide;
    // post-Initiative-IV the draft is gone within one event-loop turn
    // of `hidden`.
    WidgetsBinding.instance.addObserver(this);
    _initVerification();
  }

  /// The transient seed-bearing value handed in by `CreateWalletCubit`.
  /// Held only for the verify-quiz window; disposed on successful
  /// commit (the commit path adopts the plaintext into the wallet
  /// isolate) or on app-hidden via [didChangeAppLifecycleState].
  ///
  /// SECURITY: BIP39 lifetime — see BL-018. The draft's mnemonic is
  /// the only main-isolate `String` carrying the user's seed while the
  /// quiz is on screen; disposing it removes the only reachable
  /// reference outside the isolate.
  final SeedDraft _draft;
  final WalletService _walletService;

  void _initVerification() {
    final indices = <int>{};
    if (_draft.isDisposed) {
      // Cubit was constructed against a draft that has already been
      // disposed (e.g. by a parallel lifecycle handler). Surface as
      // aborted so the view doesn't attempt to render an empty quiz.
      emit(state.copyWith(aborted: true));
      return;
    }
    final words = _draft.seedWords;
    while (indices.length < 4) {
      indices.add(Random().nextInt(words.length));
    }
    final sortedIndices = indices.toList()..sort();

    emit(
      state.copyWith(
        wordIndices: sortedIndices,
        // `flutter test` always runs in `kDebugMode == true`, so the
        // release-mode branch below cannot be exercised from a unit test
        // without forking the test process into a release VM (which the
        // coverage tool does not collect from). The two branches differ
        // only in the seed value of `enteredWords` — release ships empty
        // slots, debug pre-fills them so devs can tap through quickly.
        // Marking the release branch as `coverage:ignore-line` keeps the
        // file at 100 % of the lines that unit tests can actually reach.
        enteredWords:
            kDebugMode // Pre-fill words in debug mode
            ? sortedIndices.map((i) => _wallet.seed.seedWords[i]).toList()
            : List.filled(4, ''), // coverage:ignore-line
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
    // `commitGeneratedWallet`'s draft-disposed assertion. Bail out and
    // let the first call own the transition.
    if (state.isVerifying || state.isVerified || state.aborted) return false;
    if (_draft.isDisposed) {
      emit(state.copyWith(aborted: true));
      return false;
    }

    final seedWords = _draft.seedWords;

    for (int i = 0; i < state.wordIndices.length; i++) {
      final expectedWord = seedWords[state.wordIndices.elementAt(i)].toLowerCase();
      final enteredWord = state.enteredWords.elementAt(i).toLowerCase();

      if (expectedWord != enteredWord) {
        emit(state.copyWith(hasError: true));
        return false;
      }
    }

    // Commit the draft mnemonic to disk BEFORE marking it current —
    // the draft handed in by `CreateWalletCubit` is the in-memory-only
    // value produced by `WalletService.generateUncommittedSeedDraft`.
    // Persisting at confirm time means a regenerate triggered by an
    // app-hidden cycle in the create flow never leaves an orphan row
    // in `walletInfos`. The user only reaches this branch by typing
    // the four requested words correctly, so the seed they kept is the
    // seed we store. `commitGeneratedWallet` adopts the plaintext into
    // the wallet isolate as part of the commit and disposes the
    // draft, so by the time this method returns the only string copy
    // of the mnemonic outside the isolate is gone.
    emit(state.copyWith(isVerifying: true, commitFailed: false));
    try {
      final committed = await _walletService.commitGeneratedWallet(_draft);
      // Async-tail guard: the AppBar back button on the verify-seed screen
      // stays enabled while `isVerifying` is true, so the user can pop the
      // page (closing the cubit) before the commit resolves. A post-close
      // `emit` would throw `StateError`. Matches the
      // `connect_bitbox_cubit` / `create_wallet_cubit` / `kyc_cubit`
      // pattern. The committed row is already persisted at this point —
      // dropping the success emission is acceptable; the user simply
      // restarts onboarding and re-uses the existing wallet.
      if (isClosed) return false;
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

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // BL-023: drop the draft as soon as the user backgrounds the app.
    // `hidden` fires before `paused` on every platform; using `hidden`
    // gives the earliest reaction window, which matters for the iOS
    // app-suspend snapshot (taken on transition to inactive/paused).
    if (state == AppLifecycleState.hidden ||
        state == AppLifecycleState.paused) {
      _disposeDraft();
    }
  }

  void _disposeDraft() {
    if (_draft.isDisposed) return;
    _draft.dispose();
    if (isClosed) return;
    emit(state.copyWith(aborted: true));
  }

  @override
  Future<void> close() {
    WidgetsBinding.instance.removeObserver(this);
    _disposeDraft();
    return super.close();
  }
}
