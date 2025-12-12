import 'package:bip39/bip39.dart' as bip39;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:realunit_wallet/packages/service/wallet_service.dart';
import 'package:realunit_wallet/packages/wallet/wallet.dart';

part 'create_wallet_state.dart';

class CreateWalletCubit extends Cubit<CreateWalletState> {
  CreateWalletCubit(this._service) : super(CreateWalletState());

  final WalletService _service;

  void createWallet() async {
    final mnemonic = bip39.generateMnemonic();
    final wallet = await _service.createWallet(
      name: "Obi-Wallet-Kenobi",
      seed: mnemonic,
    );

    emit(state.copyWith(wallet: wallet));
  }

  void toggleShowSeed() {
    emit(state.copyWith(hideSeed: !state.hideSeed));
  }
}
