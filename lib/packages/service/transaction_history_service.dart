import 'dart:convert';
import 'dart:developer' as developer;

import 'package:collection/collection.dart';
import 'package:etherscan_api/etherscan_api.dart';
// ignore: implementation_imports
import 'package:etherscan_api/src/models/account/token_tx_model.dart';
// ignore: implementation_imports
import 'package:etherscan_api/src/models/account/tx_list_model.dart';
import 'package:realunit_wallet/models/asset.dart';
import 'package:realunit_wallet/models/blockchain.dart';
import 'package:realunit_wallet/models/dfx_transaction.dart';
import 'package:realunit_wallet/models/transaction.dart';
import 'package:realunit_wallet/packages/config/api_config.dart';
import 'package:realunit_wallet/packages/ponder/ponder.dart';
import 'package:realunit_wallet/packages/repository/asset_repository.dart';
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
  final AssetRepository _assetRepository;
  final TransactionRepository _transactionRepository;

  TransactionHistoryService(this._appStore, this._assetRepository, this._transactionRepository);

  Future<void> explorerAssistedScan([int call = 0]) async {
    final chain = Blockchain.ethereum;
    final api = EtherscanAPI(apiKey: 'IBE36W7QPVF4M62N8AZ6YRTWK52FXWDH33', enableLogs: false);
    final latestHeight = (await _transactionRepository.getLatestHeight()) + 1;

    developer.log('[explorerAssistedScan][$call call] Trying sync at $latestHeight');

    final txs =
        await api.txList(address: _appStore.primaryAddress, offset: 0, startblock: latestHeight);

    if ((txs.result ?? []).isEmpty) {
      developer.log(
          '[explorerAssistedScan][$call call] 0 Transactions at $latestHeight. Sync finished!');
      return;
    }

    final ercTx = await api.tokenTx(address: _appStore.primaryAddress, startblock: latestHeight);

    for (EtherScanTxResult result in txs.result ?? []) {
      final isContractCall = result.input != '0x';

      final isTokenTransfer = ercTx.result?.any((e) => e.hash == result.hash) ?? false;

      BigInt value = BigInt.parse(result.value);
      String receiver = result.to.asHexEip55;
      Asset? asset = await _assetRepository.getAsset(chain.chainId, result.to.asHexEip55);

      if (isTokenTransfer) {
        final tokenTransfer = ercTx.result?.firstWhere((e) => e.hash == result.hash);
        if (tokenTransfer != null) {
          value = BigInt.parse(tokenTransfer.value);
          receiver = tokenTransfer.to.asHexEip55;
        }
        asset ??= Asset(
          chainId: chain.chainId,
          address: result.to.asHexEip55,
          name: 'Unknown',
          symbol: '???',
          decimals: 18,
        );
      }

      _transactionRepository.insertTransaction(Transaction(
        height: int.parse(result.blockNumber),
        txId: result.hash,
        chainId: chain.chainId,
        senderAddress: result.from.asHexEip55,
        receiverAddress: receiver,
        amount: value,
        asset: asset ?? chain.nativeAsset,
        type: isContractCall
            ? isTokenTransfer
                ? TransactionTypes.tokenTransfer
                : TransactionTypes.genericContractCall
            : TransactionTypes.transfer,
        note: '',
        data: isContractCall ? result.input : null,
        timestamp: DateTime.fromMillisecondsSinceEpoch(int.parse(result.timeStamp) * 1000),
      ));
    }

    for (EtherScanMintedTokenTxResult result in ercTx.result ?? []) {
      if (await _transactionRepository.existsTransaction(result.hash)) continue;

      Asset? asset =
          await _assetRepository.getAsset(chain.chainId, result.contractAddress.asHexEip55) ??
              Asset(
                chainId: chain.chainId,
                address: result.to.asHexEip55,
                name: 'Unknown',
                symbol: '???',
                decimals: 18,
              );

      final exists = await _transactionRepository.existsTransaction(result.hash);
      if (!exists) {
        _transactionRepository.insertTransaction(Transaction(
          height: int.parse(result.blockNumber),
          txId: result.hash,
          chainId: chain.chainId,
          senderAddress: result.from.asHexEip55,
          receiverAddress: result.to.asHexEip55,
          amount: BigInt.parse(result.value),
          asset: asset,
          type: TransactionTypes.tokenTransfer,
          note: '',
          data: result.input,
          timestamp: DateTime.fromMillisecondsSinceEpoch(int.parse(result.timeStamp) * 1000),
        ));
      }
    }

    // Recursive call till interrupted after being fully indexed
    explorerAssistedScan(call + 1);
  }

  Future<void> ponderBasedSync() async {
    final ponder = Ponder();
    final transactions = await ponder.getSavingsSavedTransactions(_appStore.primaryAddress);
    final transactions2 = await ponder.getSavingsWithdrawnTransactions(_appStore.primaryAddress);

    for (final tx in [...transactions, ...transactions2]) {
      final exists = await _transactionRepository.existsTransaction(tx.txId);
      if (exists) {
        _transactionRepository.updateTransaction(tx);
      } else {
        _transactionRepository.insertTransaction(tx);
      }
    }
  }

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

      if (matchingTransaction != null) {
        final dfxTransaction = DfxTransaction(
          dfxId: matchingTransaction.id,
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
}

extension ToEpiAddress on String {
  String get asHexEip55 => EthereumAddress.fromHex(this).hexEip55;

  String get asShortAddress {
    final address = asHexEip55;
    return '${address.substring(0, 6)}...${address.substring(address.length - 5)}';
  }

  String get asShortTxId {
    return '${substring(0, 10)}...${substring(length - 10)}';
  }

  String get asMediumAddress {
    final address = asHexEip55;
    return '${address.substring(0, 10)}...${address.substring(address.length - 10)}';
  }

  bool get isValidAddress {
    try {
      EthereumAddress.fromHex(this);
      return true;
    } catch (_) {
      return false;
    }
  }
}
