part of 'transaction_history_receipt_cubit.dart';

abstract class TransactionHistoryReceiptState extends Equatable {
  const TransactionHistoryReceiptState();

  @override
  List<Object?> get props => [];
}

class TransactionHistoryReceiptInitial extends TransactionHistoryReceiptState {
  const TransactionHistoryReceiptInitial();
}

class TransactionHistoryReceiptLoading extends TransactionHistoryReceiptState {
  const TransactionHistoryReceiptLoading();
}

class TransactionHistoryReceiptSuccess extends TransactionHistoryReceiptState {
  final String receiptPath;

  const TransactionHistoryReceiptSuccess(this.receiptPath);

  @override
  List<Object?> get props => [receiptPath];
}

class TransactionHistoryReceiptFailure extends TransactionHistoryReceiptState {
  final String message;

  const TransactionHistoryReceiptFailure(this.message);
}
