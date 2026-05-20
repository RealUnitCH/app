import 'dart:developer' as developer;

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

    // Capture the DFX auth signature while the freshly generated mnemonic is
    // still in memory — same rationale as the BitBox pairing flow. Non-fatal
    // on failure; the lazy path in DFXAuthService.getSignature recovers later.
    try {
      await _authService.ensureSignatureFor(wallet.currentAccount);
    } catch (e) {
      developer.log(
        'initial signature capture failed: $e',
        name: '$CreateWalletCubit',
      );
    }

    emit(state.copyWith(wallet: wallet));
  }

  void toggleShowSeed() {
    emit(state.copyWith(hideSeed: !state.hideSeed));
  }
}
