import 'dart:async';

import 'package:realunit_wallet/models/asset.dart';
import 'package:realunit_wallet/models/balance.dart';
import 'package:realunit_wallet/packages/config/network_mode.dart';
import 'package:realunit_wallet/packages/storage/balance_storage.dart';
import 'package:realunit_wallet/packages/storage/database.dart';

class BalanceRepository {
  final AppDatabase _appDatabase;

  const BalanceRepository(this._appDatabase);

  Future<void> saveBalance(Balance balance) async {
    final exists = await existsBalance(balance);
    return exists ? updateBalance(balance) : insertBalance(balance);
  }

  Future<int> insertBalance(Balance balance) => _appDatabase.insertBalance(
      balance.id,
      balance.chainId,
      balance.contractAddress,
      balance.walletAddress,
      balance.balance.toRadixString(16),
      balance.networkMode.name);

  Future<void> updateBalance(Balance balance) =>
      _appDatabase.updateBalance(balance.id, balance.balance.toRadixString(16));

  Future<Balance?> getBalance(Asset asset, String walletAddress, NetworkMode networkMode) => _appDatabase
      .getBalance(asset.chainId, asset.address, walletAddress, networkMode.name)
      .then((balance) => balance != null
          ? Balance(
              chainId: balance.chainId,
              contractAddress: balance.contractAddress,
              walletAddress: balance.walletAddress,
              balance: BigInt.parse(balance.balance, radix: 16),
              asset: asset,
              networkMode: networkMode,
            )
          : null);

  Future<bool> existsBalance(Balance balance) =>
      getBalance(balance.asset, balance.walletAddress, balance.networkMode)
          .then((balance) => balance != null);

  Stream<Balance> watchBalance(Balance balance) {
    final transformer = StreamTransformer<BalanceData?, Balance>.fromHandlers(
        handleData: (balanceData, sink) {
      if (balanceData != null) {
        sink.add(Balance(
          chainId: balanceData.chainId,
          contractAddress: balanceData.contractAddress,
          walletAddress: balanceData.walletAddress,
          balance: BigInt.parse(balanceData.balance, radix: 16),
          asset: balance.asset,
          networkMode: balance.networkMode,
        ));
      }
    });
    return _appDatabase
        .watchBalance(balance.id)
        .transform<Balance>(transformer);
  }
}
