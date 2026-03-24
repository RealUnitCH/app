import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:realunit_wallet/models/asset.dart';
import 'package:realunit_wallet/models/balance.dart';
import 'package:realunit_wallet/packages/repository/balance_repository.dart';

class BalanceCubit extends Cubit<Balance> {
  BalanceCubit(
    this._repository, {
    required this.asset,
    required String walletAddress,
  }) : super(
         Balance(
           chainId: asset.chainId,
           contractAddress: asset.address,
           walletAddress: walletAddress,
           balance: BigInt.zero,
           asset: asset,
         ),
       ) {
    _subscription = _repository.watchBalance(state).listen(emit);
  }

  final BalanceRepository _repository;
  final Asset asset;
  StreamSubscription<Balance>? _subscription;

  @override
  Future<void> close() {
    _subscription?.cancel();
    return super.close();
  }
}
