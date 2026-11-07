import 'package:realunit_wallet/models/asset.dart';
import 'package:realunit_wallet/models/dfx_transaction.dart';
import 'package:realunit_wallet/models/transaction.dart';
import 'package:realunit_wallet/packages/repository/transaction_repository.dart';
import 'package:realunit_wallet/packages/service/app_store.dart';
import 'package:realunit_wallet/packages/service/dfx/models/history/dto/pay_quote_dto.dart';
import 'package:realunit_wallet/packages/service/transaction_history_service.dart';
import 'package:realunit_wallet/setup/di.dart';

/// `'confirmed'` is the sentinel PayProcessCubit stores when an already-confirmed
/// pay has no hash. It is not a transaction id.
String? usableTxHash(String? value) {
  if (value == null) return null;
  final trimmed = value.trim();
  if (trimmed.isEmpty || trimmed == 'confirmed') return null;
  return trimmed;
}

Transaction buildFallbackTransaction({
  required Asset asset,
  required String walletAddress,
  required String? txHash,
  required BigInt amount,
  required String receiverAddress,
  required TransferCategory category,
  required DateTime timestamp,
}) {
  return Transaction(
    height: 0,
    txId: usableTxHash(txHash) ?? '',
    chainId: asset.chainId,
    senderAddress: walletAddress,
    receiverAddress: receiverAddress,
    amount: amount,
    asset: asset,
    type: TransactionTypes.tokenTransfer,
    category: category,
    note: '',
    data: null,
    timestamp: timestamp,
  );
}

/// Same row, with [data] replaced. A DFX payment keeps its off-chain legs.
Transaction transactionWithData(Transaction source, String? data) {
  if (source is DfxTransaction) {
    return DfxTransaction(
      dfxId: source.dfxId,
      rate: source.rate,
      inputTxId: source.inputTxId,
      outputTxId: source.outputTxId,
      inputAmount: source.inputAmount,
      inputAsset: source.inputAsset,
      outputAmount: source.outputAmount,
      outputAsset: source.outputAsset,
      height: source.height,
      txId: source.txId,
      chainId: source.chainId,
      senderAddress: source.senderAddress,
      receiverAddress: source.receiverAddress,
      amount: source.amount,
      asset: source.asset,
      type: source.type,
      category: source.category,
      note: source.note,
      data: data,
      timestamp: source.timestamp,
    );
  }
  return Transaction(
    height: source.height,
    txId: source.txId,
    chainId: source.chainId,
    senderAddress: source.senderAddress,
    receiverAddress: source.receiverAddress,
    amount: source.amount,
    asset: source.asset,
    type: source.type,
    category: source.category,
    note: source.note,
    data: data,
    timestamp: source.timestamp,
  );
}

/// Stores the confirmation quote on the completed payment when the hash can
/// identify the row later. Without a usable hash the in-memory booking is
/// still returned, so the detail can show the quote once.
Future<Transaction> attachPayQuote(
  Transaction transaction,
  PayQuoteDto quote, {
  TransactionRepository? repository,
}) async {
  final booked = transactionWithData(transaction, quote.encode());
  if (usableTxHash(booked.txId) == null) return booked;
  try {
    final repo = repository ?? getIt<TransactionRepository>();
    if (booked is DfxTransaction) {
      await repo.insertDfxTransaction(booked);
    } else {
      await repo.insertTransaction(booked);
    }
  } catch (_) {}
  return booked;
}

class CompletedTransactionRequest {
  final String? txHash;
  final BigInt amount;
  final String receiverAddress;
  final TransferCategory category;
  const CompletedTransactionRequest({
    required this.txHash,
    required this.amount,
    required this.receiverAddress,
    required this.category,
  });
}

class CompletedTransaction {
  final Transaction transaction;
  final String walletAddress;
  const CompletedTransaction({
    required this.transaction,
    required this.walletAddress,
  });
}

typedef CompletedTransactionResolver =
    Future<CompletedTransaction> Function(
      CompletedTransactionRequest request,
    );

Future<CompletedTransaction> resolveCompletedTransaction(
  CompletedTransactionRequest request, {
  TransactionHistoryService? history,
  TransactionRepository? repository,
  AppStore? appStore,
  DateTime? now,
}) async {
  final repo = repository ?? getIt<TransactionRepository>();
  final store = appStore ?? getIt<AppStore>();
  final timestamp = now ?? DateTime.now();
  final walletAddress = store.primaryAddress;
  final asset = store.apiConfig.asset;

  Transaction? stored;
  final txId = usableTxHash(request.txHash);
  if (txId != null) {
    try {
      await (history ?? getIt<TransactionHistoryService>()).apiBasedSync();
    } catch (_) {}
    try {
      final storedId = await repo.findTxIdIgnoreCase(txId);
      if (storedId != null) {
        final all = await repo.allTransactions;
        for (final candidate in all) {
          if (candidate.txId == storedId) {
            stored = candidate;
            break;
          }
        }
      }
    } catch (_) {}
  }

  if (stored != null) {
    return CompletedTransaction(
      transaction: stored,
      walletAddress: walletAddress,
    );
  }

  return CompletedTransaction(
    transaction: buildFallbackTransaction(
      asset: asset,
      walletAddress: walletAddress,
      txHash: request.txHash,
      amount: request.amount,
      receiverAddress: request.receiverAddress,
      category: request.category,
      timestamp: timestamp,
    ),
    walletAddress: walletAddress,
  );
}
