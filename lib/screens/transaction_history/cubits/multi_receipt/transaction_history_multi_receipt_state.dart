part of 'transaction_history_multi_receipt_cubit.dart';

abstract class TransactionHistoryMultiReceiptState extends Equatable {
  const TransactionHistoryMultiReceiptState();

  @override
  List<Object?> get props => [];
}

class TransactionHistoryMultiReceiptInitial extends TransactionHistoryMultiReceiptState {
  const TransactionHistoryMultiReceiptInitial();
}

class TransactionHistoryMultiReceiptLoading extends TransactionHistoryMultiReceiptState {
  const TransactionHistoryMultiReceiptLoading();
}

class TransactionHistoryMultiReceiptSuccess extends TransactionHistoryMultiReceiptState {
  final String receiptPath;

  const TransactionHistoryMultiReceiptSuccess(this.receiptPath);

  @override
  List<Object?> get props => [receiptPath];
}

class TransactionHistoryMultiReceiptFailure extends TransactionHistoryMultiReceiptState {
  final String message;

  const TransactionHistoryMultiReceiptFailure(this.message);
}
