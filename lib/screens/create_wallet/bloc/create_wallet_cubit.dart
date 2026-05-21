import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:realunit_wallet/packages/service/dfx/dfx_auth_service.dart';
import 'package:realunit_wallet/packages/service/wallet_service.dart';
import 'package:realunit_wallet/packages/wallet/wallet.dart';

part 'create_wallet_state.dart';

class CreateWalletCubit extends Cubit<CreateWalletState> {
  CreateWalletCubit(this._service, this._authService) : super(const CreateWalletState());

  final WalletService _service;
  final DFXAuthService _authService;

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
    emit(state.copyWith(wallet: wallet));
  }

  void toggleShowSeed() {
    emit(state.copyWith(hideSeed: !state.hideSeed));
  }
}
