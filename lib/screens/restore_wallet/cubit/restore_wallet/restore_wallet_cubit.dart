import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:realunit_wallet/packages/service/dfx/dfx_auth_service.dart';
import 'package:realunit_wallet/packages/service/wallet_service.dart';
import 'package:realunit_wallet/packages/wallet/wallet.dart';

part 'restore_wallet_state.dart';

class RestoreWalletCubit extends Cubit<RestoreWalletState> {
  RestoreWalletCubit(this._walletService, this._authService)
    : super(const RestoreWalletState());

  final WalletService _walletService;
  final DFXAuthService _authService;

  void restoreWallet(String seed) async {
    emit(const RestoreWalletState(isLoading: true));

    final normalizedSeed = seed.split(' ').where((element) => element.isNotEmpty).join(' ');

    final wallet = await _walletService.restoreWallet('Obi-Wallet-Kenobi', normalizedSeed);
    // Fire-and-forget the auth-signature capture so a 20 s HTTP timeout doesn't
    // block the wallet-restore UI. The lazy path in DFXAuthService.getSignature
    // is the safety net.
    unawaited(
      warmAuthSignature(
        _authService,
        wallet.currentAccount,
        loggerName: '$RestoreWalletCubit',
      ),
    );

    emit(
      RestoreWalletState(
        isLoading: false,
        wallet: wallet,
      ),
    );
  }
}
