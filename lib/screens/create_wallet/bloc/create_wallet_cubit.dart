import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:realunit_wallet/packages/service/dfx/dfx_auth_service.dart';
import 'package:realunit_wallet/packages/service/wallet_service.dart';
import 'package:realunit_wallet/packages/wallet/wallet.dart';

part 'create_wallet_state.dart';

class CreateWalletCubit extends Cubit<CreateWalletState> {
  CreateWalletCubit(this._service, this._authService) : super(const CreateWalletState()) {
    // Onboarding-equivalent of `WalletService.lockCurrentWallet()` for the
    // freshly generated mnemonic. While the user is on the create-wallet
    // screen, the mnemonic lives in `CreateWalletState.wallet` — not in
    // `AppStore.wallet` — so the service-level lock is a no-op for this
    // path. Clearing the cubit state on `hidden` drops the seed before iOS
    // suspends the isolate; the user returning is sent back to the start
    // of the create flow, which is the safe restart point.
    _lifecycleListener = AppLifecycleListener(onStateChange: _onLifecycleState);
  }

  final WalletService _service;
  final DFXAuthService _authService;
  late final AppLifecycleListener _lifecycleListener;

  void createWallet() async {
    final wallet = await _service.createSeedWallet('Obi-Wallet-Kenobi');
    // Fire-and-forget the auth-signature capture — the lazy path in
    // DFXAuthService.getSignature is the safety net, and a 20 s HTTP timeout
    // shouldn't gate the "creating wallet" UI.
    unawaited(
      warmAuthSignature(
        _authService,
        wallet.currentAccount,
        loggerName: '$CreateWalletCubit',
      ),
    );
    // Async-tail guard: with the `_dropMnemonic` re-fire on `hidden`, the
    // user can return to foreground and immediately pop the screen before
    // the regenerated `createSeedWallet` resolves — the AppBar back closes
    // the cubit, and a post-close `emit` would throw `StateError`. Matches
    // the `connect_bitbox_cubit` / `kyc_cubit` pattern.
    if (isClosed) return;
    emit(state.copyWith(wallet: wallet));
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
    // Reset to the initial state — drops `wallet` (and its mnemonic) and
    // restores the default `hideSeed: true`. `copyWith` would carry the
    // existing wallet through, so we emit a fresh state explicitly.
    if (state.wallet == null) return;
    emit(const CreateWalletState());
    // The cubit is built once via `BlocProvider.create` (`..createWallet()`
    // fires exactly once at construction), so without re-firing here the
    // user would resume to a `state.wallet == null` and the view's
    // `BlocBuilder` would render `CupertinoActivityIndicator` indefinitely
    // — escapable only via the AppBar back button. Re-issue a fresh
    // generation so the next emission replaces the cleared state; the
    // screen briefly flashes the loading indicator, then re-renders with
    // the new mnemonic. The prior in-memory seed is already gone.
    createWallet();
  }

  @override
  Future<void> close() {
    _lifecycleListener.dispose();
    return super.close();
  }
}
