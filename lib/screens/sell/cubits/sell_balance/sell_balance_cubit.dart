import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:realunit_wallet/models/balance.dart';
import 'package:realunit_wallet/packages/repository/balance_repository.dart';
import 'package:realunit_wallet/packages/service/app_store.dart';

class SellBalanceCubit extends Cubit<Balance> {
  SellBalanceCubit(
    BalanceRepository repository,
    AppStore appStore,
  ) : _repository = repository,
      super(
        Balance(
          chainId: appStore.apiConfig.asset.chainId,
          contractAddress: appStore.apiConfig.asset.address,
          walletAddress: appStore.primaryAddress,
          balance: BigInt.zero,
          asset: appStore.apiConfig.asset,
        ),
      ) {
    _subscription = _repository.watchBalance(state).listen(emit);
  }

  final BalanceRepository _repository;
  StreamSubscription<Balance>? _subscription;

  @override
  Future<void> close() {
    _subscription?.cancel();
    return super.close();
  }
}
