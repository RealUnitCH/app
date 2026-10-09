import 'dart:async';
import 'dart:developer' as developer show log;

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:realunit_wallet/packages/service/dfx/models/transactions/dto/transactions_dto.dart';
import 'package:realunit_wallet/packages/service/transaction_history_service.dart';

class PendingTransactionsCubit extends Cubit<List<TransactionDto>> {
  PendingTransactionsCubit(this._transactionHistoryService) : super([]) {
    unawaited(_loadPendingTransactions());
  }

  final TransactionHistoryService _transactionHistoryService;

  Future<void> _loadPendingTransactions() async {
    try {
      final transactions = await _transactionHistoryService.fetchPendingTransactions();
      emit(transactions);
    } catch (e) {
      developer.log('Failed to load pending transactions: $e', name: '$PendingTransactionsCubit');
      emit([]);
    }
  }
}
