import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:realunit_wallet/models/transaction.dart';
import 'package:realunit_wallet/packages/repository/transaction_repository.dart';
import 'package:realunit_wallet/packages/service/app_store.dart';
import 'package:realunit_wallet/packages/utils/default_assets.dart';

class TransactionHistoryCubit extends Cubit<List<Transaction>> {
  TransactionHistoryCubit(this._repository, this._walletAddress, this._appStore) : super([]) {
    _repository.watchTransactionsOfAssets(
        [realUnitAsset], _walletAddress, _appStore.apiConfig.networkMode, 6).listen(emit);
  }

  final String _walletAddress;
  final TransactionRepository _repository;
  final AppStore _appStore;
}
