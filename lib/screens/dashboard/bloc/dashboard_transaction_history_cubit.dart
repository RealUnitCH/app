import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:realunit_wallet/models/asset.dart';
import 'package:realunit_wallet/models/transaction.dart';
import 'package:realunit_wallet/packages/repository/transaction_repository.dart';

class DashboardTransactionHistoryCubit extends Cubit<List<Transaction>> {
  DashboardTransactionHistoryCubit(
    this._repository, {
    required this.asset,
    required this.walletAddress,
  }) : super([]) {
    _subscription = _repository.watchTransactionsOfAssets([asset], walletAddress, 3).listen(emit);
  }

  final Asset asset;
  final String walletAddress;
  final TransactionRepository _repository;
  late final StreamSubscription<List<Transaction>> _subscription;

  @override
  Future<void> close() {
    _subscription.cancel();
    return super.close();
  }
}
