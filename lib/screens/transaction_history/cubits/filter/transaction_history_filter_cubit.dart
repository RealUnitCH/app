import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:realunit_wallet/models/asset.dart';
import 'package:realunit_wallet/models/transaction.dart';
import 'package:realunit_wallet/packages/repository/transaction_repository.dart';

part 'transaction_history_filter_state.dart';

class TransactionHistoryFilterCubit extends Cubit<TransactionHistoryFilterState> {
  TransactionHistoryFilterCubit(
    this._repository, {
    required Asset asset,
    required String walletAddress,
    int? limit,
  }) : super(TransactionHistoryFilterState()) {
    _subscription = _repository.watchTransactionsOfAssets([asset], walletAddress).listen(
      _onTransactionsUpdated,
    );
  }

  final TransactionRepository _repository;
  StreamSubscription<List<Transaction>>? _subscription;

  void _onTransactionsUpdated(List<Transaction> transactions) {
    emit(
      state.copyWith(
        all: transactions,
        filtered: _applyFilter(
          transactions,
          startDate: state.startDate,
          endDate: state.endDate,
        ),
      ),
    );
  }

  void changeFilter({DateTime? startDate, DateTime? endDate}) {
    emit(
      state.copyWith(
        startDate: startDate,
        endDate: endDate,
        filtered: _applyFilter(
          state.all,
          startDate: startDate,
          endDate: endDate,
        ),
      ),
    );
  }

  List<Transaction> _applyFilter(
    List<Transaction> transactions, {
    DateTime? startDate,
    DateTime? endDate,
  }) {
    return transactions.where((transaction) {
      final transactionDate = transaction.timestamp;
      final afterStart = startDate == null || !transactionDate.isBefore(startDate);
      final beforeEnd = endDate == null || !transactionDate.isAfter(endDate);
      return afterStart && beforeEnd;
    }).toList();
  }

  @override
  Future<void> close() {
    _subscription?.cancel();
    return super.close();
  }
}
