import 'dart:async';
import 'dart:convert';

import 'package:realunit_wallet/models/asset.dart';
import 'package:realunit_wallet/models/balance.dart';
import 'package:realunit_wallet/models/blockchain.dart';
import 'package:realunit_wallet/packages/repository/asset_repository.dart';
import 'package:realunit_wallet/packages/repository/balance_repository.dart';
import 'package:realunit_wallet/packages/service/app_store.dart';
import 'package:realunit_wallet/packages/utils/default_assets.dart';
import 'package:web3dart/web3dart.dart';

class BalanceService {
  final BalanceRepository _balanceRepository;
  final AssetRepository _assetRepository;
  final AppStore _appStore;

  BalanceService(
      this._balanceRepository, this._assetRepository, this._appStore);

  Timer? _syncTimer;

  void startSync(String address) {
    cancelSync();

    _syncTimer = Timer.periodic(
        Duration(seconds: 10), (_) => updateBalances(address));
  }

  void cancelSync() => _syncTimer?.cancel();

  Future<void> updateBalances(String address) async {
    await _updateRealUnitBalance(address);
    await _updateNativeBalances(address);
  }

  Future<void> _updateRealUnitBalance(String address) async {
    try {
      final baseUrl = _appStore.apiConfig.dfxApiHost;
      final uri = Uri.https(baseUrl, '/v1/realunit/account/$address');

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
          ));
        }
      }
    } catch (e) {
      // Silently fail - balance will be updated on next sync
    }
  }

  Future<Balance?> getBalance(Asset asset, String address) =>
      _balanceRepository.getBalance(asset, address);

  Future<void> _updateNativeBalances(String address) async {
    for (final chain in Blockchain.values) {
      try {
        final balance = await _appStore
            .getClient(chain.chainId)
            .getBalance(EthereumAddress.fromHex(address));
        await _balanceRepository.saveBalance(Balance(
          chainId: chain.chainId,
          contractAddress: chain.nativeAsset.address,
          walletAddress: address,
          balance: balance.getInWei,
          asset: chain.nativeAsset,
        ));
      } catch (e) {
        // Silently fail for individual chains
      }
    }
  }
}
