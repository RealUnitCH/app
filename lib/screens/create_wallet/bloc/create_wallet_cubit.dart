import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:realunit_wallet/packages/service/wallet_service.dart';
import 'package:realunit_wallet/packages/wallet/wallet.dart';

part 'create_wallet_state.dart';

class CreateWalletCubit extends Cubit<CreateWalletState> {
  CreateWalletCubit(this._service) : super(const CreateWalletState());

  final WalletService _service;

  void createWallet() async {
    final wallet = await _service.createSeedWallet("Obi-Wallet-Kenobi");

    emit(state.copyWith(wallet: wallet));
  }

  void toggleShowSeed() {
    emit(state.copyWith(hideSeed: !state.hideSeed));
  }
}
