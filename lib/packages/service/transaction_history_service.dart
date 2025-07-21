import 'dart:developer' as developer;

import 'package:deuro_wallet/models/asset.dart';
import 'package:deuro_wallet/models/blockchain.dart';
import 'package:deuro_wallet/models/transaction.dart';
import 'package:deuro_wallet/packages/ponder/ponder.dart';
import 'package:deuro_wallet/packages/repository/asset_repository.dart';
import 'package:deuro_wallet/packages/repository/transaction_repository.dart';
import 'package:deuro_wallet/packages/service/app_store.dart';
import 'package:etherscan_api/etherscan_api.dart';
import 'package:etherscan_api/src/models/account/token_tx_model.dart';
import 'package:etherscan_api/src/models/account/tx_list_model.dart';
import 'package:web3dart/credentials.dart';

class TransactionHistoryService {
  final AppStore _appStore;
  final AssetRepository _assetRepository;
  final TransactionRepository _transactionRepository;

  TransactionHistoryService(
      this._appStore, this._assetRepository, this._transactionRepository);

  Future<void> explorerAssistedScan([int call = 0]) async {
    final chain = Blockchain.ethereum;
    final api = EtherscanAPI(
        apiKey: 'IBE36W7QPVF4M62N8AZ6YRTWK52FXWDH33', enableLogs: false);
    final latestHeight = (await _transactionRepository.getLatestHeight()) + 1;

    developer
        .log("[explorerAssistedScan][$call call] Trying sync at $latestHeight");

    final txs = await api.txList(
        address: _appStore.primaryAddress, offset: 0, startblock: latestHeight);

    if ((txs.result ?? []).isEmpty) {
      developer.log(
          "[explorerAssistedScan][$call call] 0 Transactions at $latestHeight. Sync finished!");
      return;
    }

    final ercTx = await api.tokenTx(
        address: _appStore.primaryAddress, startblock: latestHeight);

    for (EtherScanTxResult result in txs.result ?? []) {
      final isContractCall = result.input != "0x";

      final isTokenTransfer =
          ercTx.result?.any((e) => e.hash == result.hash) ?? false;

      BigInt value = BigInt.parse(result.value);
      String receiver = result.to.asHexEip55;
      Asset? asset =
          await _assetRepository.getAsset(chain.chainId, result.to.asHexEip55);

      if (isTokenTransfer) {
        final tokenTransfer =
            ercTx.result?.firstWhere((e) => e.hash == result.hash);
        if (tokenTransfer != null) {
          value = BigInt.parse(tokenTransfer.value);
          receiver = tokenTransfer.to.asHexEip55;
        }
        asset ??= Asset(
          chainId: chain.chainId,
          address: result.to.asHexEip55,
          name: "Unknown",
          symbol: "???",
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
        note: "",
        data: isContractCall ? result.input : null,
        timestamp: DateTime.fromMillisecondsSinceEpoch(
            int.parse(result.timeStamp) * 1000),
      ));
    }

    for (EtherScanMintedTokenTxResult result in ercTx.result ?? []) {
      if (await _transactionRepository.exitsTransaction(result.hash)) continue;

      Asset? asset = await _assetRepository.getAsset(
              chain.chainId, result.contractAddress.asHexEip55) ??
          Asset(
            chainId: chain.chainId,
            address: result.to.asHexEip55,
            name: "Unknown",
            symbol: "???",
            decimals: 18,
          );

      final exists = await _transactionRepository.exitsTransaction(result.hash);
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
          note: "",
          data: result.input,
          timestamp: DateTime.fromMillisecondsSinceEpoch(
              int.parse(result.timeStamp) * 1000),
        ));
      }
    }

    // Recursive call till interrupted after being fully indexed
    explorerAssistedScan(call + 1);
  }

  Future<void> ponderBasedSync() async {
    final transactions = await Ponder().getSavingsSavingsTransactions(_appStore.primaryAddress);

    for (final tx in transactions) {
      final exists = await _transactionRepository.exitsTransaction(tx.txId);
      print(tx.txId);
      if (exists) {
        _transactionRepository.updateTransaction(tx);
      } else {
        _transactionRepository.insertTransaction(tx);
      }
    }
  }

// Future<Transaction> getTransactionState(String txId, int chainId) async {
//   final txState =
//       await _appStore.getClient(chainId).getTransactionByHash(txId);
//
//   if (txState != null) {
//     txState.
//   }
// }
}

extension ToEpiAddress on String {
  String get asHexEip55 => EthereumAddress.fromHex(this).hexEip55;

  String get asShortAddress {
    final address = asHexEip55;
    return "${address.substring(0, 6)}...${address.substring(address.length - 5)}";
  }

  String get asShortTxId {
    return "${substring(0, 10)}...${substring(length - 10)}";
  }

  String get asMediumAddress {
    final address = asHexEip55;
    return "${address.substring(0, 10)}...${address.substring(address.length - 10)}";
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
