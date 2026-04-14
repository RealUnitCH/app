import 'dart:convert';

import 'package:collection/collection.dart';
import 'package:realunit_wallet/models/dfx_transaction.dart';
import 'package:realunit_wallet/models/transaction.dart';
import 'package:realunit_wallet/packages/config/api_config.dart';
import 'package:realunit_wallet/packages/repository/transaction_repository.dart';
import 'package:realunit_wallet/packages/service/app_store.dart';
import 'package:realunit_wallet/packages/service/dfx/models/history/dto/account_history_dto.dart';
import 'package:realunit_wallet/packages/service/dfx/models/transactions/dto/transactions_dto.dart';
import 'package:web3dart/credentials.dart';

class TransactionHistoryService {
  static String _accountHistoryPath(String address) => '/v1/realunit/account/$address/history';
  static const String _transactionsPath = 'v1/transaction';
  String get _host => _appStore.apiConfig.apiHost;

  final AppStore _appStore;
  final TransactionRepository _transactionRepository;

  TransactionHistoryService(this._appStore, this._transactionRepository);

  Future<void> apiBasedSync() async {
    final results = await Future.wait([
      _fetchAccountHistory(),
      _fetchTransactions(),
    ]);

    final accountHistory = results.elementAt(0) as AccountHistoryDto?;
    final transactions = results.elementAt(1) as List<TransactionDto>;

    if (accountHistory == null) return;

    for (final entry in accountHistory.history) {
      final transfer = entry.transfer;
      if (transfer == null) continue;

      final txId = entry.txHash;
      final exists = await _transactionRepository.existsTransaction(txId);
      final matchingTransaction = transactions.firstWhereOrNull(
        (t) => t.inputTxId == txId || t.outputTxId == txId,
      );

      if (matchingTransaction != null && matchingTransaction.id != null) {
        final dfxTransaction = DfxTransaction(
          dfxId: matchingTransaction.id!,
          rate: matchingTransaction.rate,
          inputTxId: matchingTransaction.inputTxId,
          outputTxId: matchingTransaction.outputTxId,
          height: 0, // TODO
          txId: txId,
          chainId: _appStore.apiConfig.asset.chainId,
          senderAddress: transfer.from,
          receiverAddress: transfer.to,
          amount: BigInt.parse(transfer.value),
          asset: _appStore.apiConfig.asset,
          type: TransactionTypes.tokenTransfer,
          note: '',
          data: null,
          timestamp: entry.timestamp,
        );

        if (exists) {
          await _transactionRepository.updateDfxTransaction(dfxTransaction);
        } else {
          await _transactionRepository.insertDfxTransaction(dfxTransaction);
        }
      } else {
        final transaction = Transaction(
          height: 0, // TODO
          txId: txId,
          chainId: _appStore.apiConfig.asset.chainId,
          senderAddress: transfer.from,
          receiverAddress: transfer.to,
          amount: BigInt.parse(transfer.value),
          asset: _appStore.apiConfig.asset,
          type: TransactionTypes.tokenTransfer,
          note: '',
          data: null,
          timestamp: entry.timestamp,
        );

        if (exists) {
          await _transactionRepository.updateTransaction(transaction);
        } else {
          await _transactionRepository.insertTransaction(transaction);
        }
      }
    }
  }

  Future<AccountHistoryDto?> _fetchAccountHistory() async {
    final address = _appStore.primaryAddress;
    final uri = buildUri(_host, _accountHistoryPath(address));

    final response = await _appStore.httpClient.get(uri);
    if (response.statusCode != 200) return null;

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    return AccountHistoryDto.fromJson(body);
  }

  Future<List<TransactionDto>> _fetchTransactions() async {
    final address = _appStore.primaryAddress;
    final uri = buildUri(_host, _transactionsPath, {'userAddress': address});

    final response = await _appStore.httpClient.get(uri);
    if (response.statusCode != 200) return [];

    final List<dynamic> json = jsonDecode(response.body);
    return json.map((e) => TransactionDto.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<List<TransactionDto>> fetchPendingTransactions() async {
    final authToken = _appStore.sessionCache.authToken;
    if (authToken == null) return [];

    final uri = buildUri(_host, '$_transactionsPath/detail');
    final response = await _appStore.httpClient.get(
      uri,
      headers: {'Authorization': 'Bearer $authToken'},
    );

    if (response.statusCode != 200) return [];

    final List<dynamic> json = jsonDecode(response.body);
    final transactions = json
        .map((e) => TransactionDto.fromJson(e as Map<String, dynamic>))
        .toList();

    final walletAddress = _appStore.primaryAddress;
    return transactions.where((t) => t.isPending && t.belongsToWallet(walletAddress)).toList();
  }
}

extension ToEpiAddress on String {
  String get asHexEip55 => EthereumAddress.fromHex(this).hexEip55;

  String get asShortTxId {
    return '${substring(0, 10)}...${substring(length - 10)}';
  }
}
