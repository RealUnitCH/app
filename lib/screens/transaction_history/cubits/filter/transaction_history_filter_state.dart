part of 'transaction_history_filter_cubit.dart';

class TransactionHistoryFilterState {
  final List<Transaction> all;
  final List<Transaction> filtered;
  final DateTime? startDate;
  final DateTime? endDate;

  const TransactionHistoryFilterState({
    this.all = const [],
    this.filtered = const [],
    this.startDate,
    this.endDate,
  });

  TransactionHistoryFilterState copyWith({
    List<Transaction>? all,
    List<Transaction>? filtered,
    DateTime? startDate,
    DateTime? endDate,
  }) {
    return TransactionHistoryFilterState(
      all: all ?? this.all,
      filtered: filtered ?? this.filtered,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
    );
  }
}
