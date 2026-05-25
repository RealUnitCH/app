part of 'transaction_history_filter_cubit.dart';

class TransactionHistoryFilterState {
  final List<Transaction> all;
  final List<Transaction> filtered;
  final DateTime? startDate;
  final DateTime? endDate;

  TransactionHistoryFilterState({
    this.all = const [],
    this.filtered = const [],
    DateTime? startDate,
    DateTime? endDate,
  }) : startDate = startDate ?? clock.now().subtract(const Duration(days: 365)),
       endDate = endDate ?? clock.now();

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
