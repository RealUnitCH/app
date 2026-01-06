import 'dart:async';
import 'dart:convert';

import 'package:realunit_wallet/models/asset.dart';
import 'package:realunit_wallet/models/balance.dart';
import 'package:realunit_wallet/models/blockchain.dart';
import 'package:realunit_wallet/packages/repository/balance_repository.dart';
import 'package:realunit_wallet/packages/service/app_store.dart';
import 'package:realunit_wallet/packages/utils/default_assets.dart';
import 'package:web3dart/web3dart.dart';

class BalanceService {
  static const _balancePath = '/v1/realunit/account';
  String get _host => _appStore.apiConfig.apiHost;

  final BalanceRepository _balanceRepository;
  final AppStore _appStore;

  BalanceService(this._balanceRepository, this._appStore);

  Timer? _syncTimer;

  void startSync(String address) {
    cancelSync();

    _syncTimer = Timer.periodic(Duration(seconds: 10), (_) => updateBalances(address));
  }

  void cancelSync() => _syncTimer?.cancel();

  Future<void> updateBalances(String address) async {
    await _updateRealUnitBalance(address);
    await _updateNativeBalances(address);
  }

  Future<void> _updateRealUnitBalance(String address) async {
    try {
      final uri = Uri.https(_host, '$_balancePath/$address');

      final response = await _appStore.httpClient.get(uri);

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        final balanceString = json['balance'] as String?;

        if (balanceString != null) {
          final balanceValue = BigInt.parse(balanceString);

          await _balanceRepository.saveBalance(Balance(
            chainId: realUnitAsset.chainId,
            contractAddress: realUnitAsset.address,
            walletAddress: address,
            balance: balanceValue,
            asset: realUnitAsset,
            networkMode: _appStore.apiConfig.networkMode,
          ));
        }
      }
    } catch (e) {
      // Silently fail - balance will be updated on next sync
    }
  }

  Future<Balance?> getBalance(Asset asset, String address) =>
      _balanceRepository.getBalance(asset, address, _appStore.apiConfig.networkMode);

  Future<void> _updateNativeBalances(String address) async {
    for (final chain in Blockchain.values) {
      try {
        final balance =
            await _appStore.getClient(chain.chainId).getBalance(EthereumAddress.fromHex(address));
        await _balanceRepository.saveBalance(Balance(
          chainId: chain.chainId,
          contractAddress: chain.nativeAsset.address,
          walletAddress: address,
          balance: balance.getInWei,
          asset: chain.nativeAsset,
          networkMode: _appStore.apiConfig.networkMode,
        ));
      } catch (e) {
        // Silently fail for individual chains
      }
    }
  }
}
