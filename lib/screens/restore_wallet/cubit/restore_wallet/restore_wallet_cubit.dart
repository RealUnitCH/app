import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:realunit_wallet/packages/service/wallet_service.dart';
import 'package:realunit_wallet/packages/wallet/wallet.dart';

part 'restore_wallet_state.dart';

class RestoreWalletCubit extends Cubit<RestoreWalletState> {
  RestoreWalletCubit(this._walletService) : super(const RestoreWalletState());

  final WalletService _walletService;

  void restoreWallet(String seed) async {
    emit(const RestoreWalletState(isLoading: true));

    final normalizedSeed = seed.split(' ').where((element) => element.isNotEmpty).join(' ');

    final wallet = await _walletService.restoreWallet('Obi-Wallet-Kenobi', normalizedSeed);

    emit(
      RestoreWalletState(
        isLoading: false,
        wallet: wallet,
      ),
    );
  }

}
