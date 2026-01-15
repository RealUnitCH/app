import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:realunit_wallet/models/asset.dart';
import 'package:realunit_wallet/models/transaction.dart';
import 'package:realunit_wallet/packages/repository/transaction_repository.dart';

class TransactionHistoryCubit extends Cubit<List<Transaction>> {
  TransactionHistoryCubit(
    this._repository, {
    required this.asset,
    required this.walletAddress,
    int? limit,
  }) : super([]) {
    _repository.watchTransactionsOfAssets([asset], walletAddress, limit).listen(emit);
  }

  final Asset asset;
  final String walletAddress;
  final TransactionRepository _repository;
}
