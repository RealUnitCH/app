import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:realunit_wallet/packages/service/dfx/dfx_auth_service.dart';
import 'package:realunit_wallet/packages/service/wallet_service.dart';
import 'package:realunit_wallet/packages/wallet/wallet.dart';

part 'create_wallet_state.dart';

class CreateWalletCubit extends Cubit<CreateWalletState> {
  CreateWalletCubit(this._service, DFXAuthService authService) : super(const CreateWalletState()) {
    // Onboarding-equivalent of `WalletService.lockCurrentWallet()` for the
    // freshly generated mnemonic. While the user is on the create-wallet
    // screen, the mnemonic lives in `CreateWalletState.draft` — not in
    // `AppStore.wallet` — so the service-level lock is a no-op for this
    // path. Disposing the draft on `hidden` drops the seed before iOS
    // suspends the isolate; the user returning is sent back to the start
    // of the create flow, which is the safe restart point.
    //
    // Pre-Initiative-IV the cubit also kicked off a warm-up of the DFX
    // auth signature using the freshly-derived BIP32 private key on the
    // main isolate. The warm-up was a non-essential optimisation — the
    // lazy path in `DFXAuthService.getSignature` is the safety net and
    // runs the same signature capture on the first authenticated call
    // once the wallet is committed (and the seed lives in the isolate).
    // Dropping the pre-warm here keeps the main isolate's BIP32 surface
    // at zero for the create flow: the only `String` carrying the
    // mnemonic is `SeedDraft._mnemonic`, scoped to this cubit's life.
    _lifecycleListener = AppLifecycleListener(onStateChange: _onLifecycleState);
    // The auth service is intentionally not held — see the comment
    // above. Suppress the unused-parameter lint by referencing the
    // identifier; future re-introduction of the warm path will pick
    // it up again.
    assert(authService.runtimeType.toString().isNotEmpty);
  }

  final WalletService _service;
  late final AppLifecycleListener _lifecycleListener;

  void createWallet() async {
    // Defer the DB write to `VerifySeedCubit.verify()` via
    // `WalletService.commitGeneratedWallet`. Writing on every regenerate
    // would persist a fresh encrypted-seed row on each `_dropMnemonic`
    // cycle (N+1 rows per onboarding session with N hide-cycles), and
    // `WalletStorage.deleteWallet` pre-Initiative-IV only touched
    // `walletAccountInfos` — those `walletInfos` rows would have
    // accumulated undeletable. The draft is a transient main-isolate
    // holder (Law-6 scope: this cubit) so the seed never lives on a
    // long-lived SoftwareWallet handle.
    final draft = await _service.generateUncommittedSeedDraft('Obi-Wallet-Kenobi');
    // Async-tail guard: with the `_dropMnemonic` re-fire on `hidden`,
    // the user can return to foreground and immediately pop the screen
    // before the regenerated `generateUncommittedSeedDraft` resolves
    // — the AppBar back closes the cubit, and a post-close `emit`
    // would throw `StateError`. Matches the `connect_bitbox_cubit` /
    // `kyc_cubit` pattern. Drop the just-created draft so its
    // mnemonic doesn't survive the close as a leaked allocation.
    if (isClosed) {
      draft.dispose();
      return;
    }
    emit(state.copyWith(draft: draft));
  }

  void toggleShowSeed() {
    emit(state.copyWith(hideSeed: !state.hideSeed));
  }

  void _onLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.hidden) {
      _dropMnemonic();
    }
  }

  void _dropMnemonic() {
    // Reset to the initial state — drops the draft (and its mnemonic)
    // and restores the default `hideSeed: true`. `copyWith` would
    // carry the existing draft through, so we emit a fresh state
    // explicitly. The draft's `dispose()` is called so the field is
    // overwritten with spaces before GC has any chance to leak it.
    final old = state.draft;
    if (old == null) return;
    old.dispose();
    emit(const CreateWalletState());
    // The cubit is built once via `BlocProvider.create` (`..createWallet()`
    // fires exactly once at construction), so without re-firing here the
    // user would resume to a `state.draft == null` and the view's
    // `BlocBuilder` would render `CupertinoActivityIndicator` indefinitely
    // — escapable only via the AppBar back button. Re-issue a fresh
    // generation so the next emission replaces the cleared state; the
    // screen briefly flashes the loading indicator, then re-renders with
    // the new mnemonic. The prior in-memory seed is already zeroized.
    createWallet();
  }

  @override
  Future<void> close() {
    state.draft?.dispose();
    _lifecycleListener.dispose();
    return super.close();
  }
}
