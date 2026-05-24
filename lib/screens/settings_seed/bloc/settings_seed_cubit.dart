import 'package:equatable/equatable.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:realunit_wallet/packages/service/app_store.dart';
import 'package:realunit_wallet/packages/service/wallet_service.dart';
import 'package:realunit_wallet/packages/wallet/wallet.dart';

part 'settings_seed_state.dart';

class SettingsSeedCubit extends Cubit<SettingsSeedState> with WidgetsBindingObserver {
  final AppStore _appStore;
  final WalletService _walletService;

  /// Post-Initiative-IV the cubit fetches the mnemonic via
  /// `WalletService.revealCurrentSeed` — a typed IPC round trip
  /// through the dedicated wallet isolate that returns a transient
  /// [SeedDraft]. The draft is the only main-isolate holder of the
  /// plaintext while the user is on this screen; the cubit's
  /// `close()` + the lifecycle observer both dispose it.
  ///
  /// SECURITY: BIP39 lifetime — see BL-018. Holding the draft for the
  /// duration of the visible seed-reveal screen is Law-6's "clearly
  /// scoped" carve-out; the moment the user navigates away, the
  /// dispose chain runs.
  SeedDraft? _draft;

  SettingsSeedCubit(this._appStore, this._walletService)
      : super(const SettingsSeedState('')) {
    WidgetsBinding.instance.addObserver(this);
    _loadSeed();
  }

  Future<void> _loadSeed() async {
    // Revealing the recovery phrase needs the actual mnemonic in
    // memory — promote a view-wallet to its unlocked form so the
    // isolate has the slot to read from, then round-trip the seed
    // back through the channel.
    await _walletService.ensureCurrentWalletUnlocked();
    // The user can navigate away during DB decryption — emit() after close()
    // throws StateError as an unhandled async error, so bail before reading.
    if (isClosed) return;
    final wallet = _appStore.wallet;
    if (wallet is! SoftwareWallet) return;
    final draft = await _walletService.revealCurrentSeed();
    if (isClosed) {
      draft.dispose();
      return;
    }
    _draft = draft;
    // copyWith preserves a [showSeed] toggle that may have raced ahead
    // of the unlock so the user's choice isn't dropped on the floor.
    if (state.seed != draft.mnemonic) {
      emit(state.copyWith(seed: draft.mnemonic));
    }
  }

  void toggleShowSeed() => emit(state.copyWith(showSeed: !state.showSeed));

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // BL-023 parallel: drop the draft when the user backgrounds the
    // app while this screen is on top. Equivalent to the verify-seed
    // path; the seed-reveal screen is the second of two screens where
    // the mnemonic lives on the main isolate (the first being
    // verify-seed during onboarding).
    if (state == AppLifecycleState.hidden ||
        state == AppLifecycleState.paused) {
      _disposeDraft();
      if (isClosed) return;
      // Wipe the rendered string too so a UI-tree dump (e.g. iOS
      // snapshot) doesn't capture the words.
      if (this.state.seed.isNotEmpty) emit(this.state.copyWith(seed: ''));
    }
  }

  void _disposeDraft() {
    final draft = _draft;
    if (draft == null || draft.isDisposed) return;
    draft.dispose();
    _draft = null;
  }

  @override
  Future<void> close() async {
    WidgetsBinding.instance.removeObserver(this);
    _disposeDraft();
    // The mnemonic is on screen only while this cubit is alive — once the user
    // navigates away, drop it back to the locked view so the key isn't
    // resident for the rest of the foreground session.
    await _walletService.lockCurrentWallet();
    return super.close();
  }
}
