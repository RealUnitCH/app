import 'dart:developer' as developer;

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

    // Capture the DFX auth signature while the freshly restored mnemonic is
    // still in memory — same rationale as the BitBox pairing flow. Non-fatal
    // on failure; the lazy path in DFXAuthService.getSignature recovers later.
    try {
      await _authService.ensureSignatureFor(wallet.currentAccount);
    } catch (e) {
      developer.log(
        'initial signature capture failed: $e',
        name: '$RestoreWalletCubit',
      );
    }

    emit(
      RestoreWalletState(
        isLoading: false,
        wallet: wallet,
      ),
    );
  }
}
