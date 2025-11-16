import 'package:realunit_wallet/models/asset.dart';
import 'package:realunit_wallet/models/balance.dart';
import 'package:realunit_wallet/packages/repository/balance_repository.dart';
import 'package:realunit_wallet/packages/utils/default_assets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class BalanceCubit extends Cubit<Balance> {
  BalanceCubit(this._repository,
      {required this.asset, required String walletAddress})
      : super(Balance(
          chainId: asset.chainId,
          contractAddress: asset.address,
          walletAddress: walletAddress,
          balance: BigInt.zero,
          asset: dEUROAsset,
        )) {
    _repository.watchBalance(state).listen(emit);
  }

  final BalanceRepository _repository;
  final Asset asset;
}
