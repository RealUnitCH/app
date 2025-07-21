import 'package:deuro_wallet/models/transaction.dart';
import 'package:deuro_wallet/packages/repository/transaction_repository.dart';
import 'package:deuro_wallet/packages/utils/default_assets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class TransactionHistoryCubit extends Cubit<List<Transaction>> {
  TransactionHistoryCubit(this._repository, this._walletAddress) : super([]) {
    _repository.watchTransactionsSavings(
        [dEUROAsset], _walletAddress, 6).listen(emit);
  }

  final String _walletAddress;
  final TransactionRepository _repository;
}
