import 'dart:async';

import 'package:realunit_wallet/models/asset.dart';
import 'package:realunit_wallet/models/balance.dart';
import 'package:realunit_wallet/models/blockchain.dart';
import 'package:realunit_wallet/packages/repository/asset_repository.dart';
import 'package:realunit_wallet/packages/repository/balance_repository.dart';
import 'package:realunit_wallet/packages/service/app_store.dart';
import 'package:erc20/erc20.dart';
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
        Duration(seconds: 10), (_) => updateERC20Balances(address));
  }

  void cancelSync() => _syncTimer?.cancel();

  Future<void> updateERC20Balances(String address) async {
    final assets =
        (await _assetRepository.allAssets).where((e) => e.symbol != "0x0");

    for (final erc20Token in assets) {
      final erc20 = ERC20(
        address: EthereumAddress.fromHex(erc20Token.address),
        client: _appStore.getClient(erc20Token.chainId),
      );
      final balance = await erc20.balanceOf(EthereumAddress.fromHex(address));

      await _balanceRepository.saveBalance(Balance(
        chainId: erc20Token.chainId,
        contractAddress: erc20Token.address,
        walletAddress: address,
        balance: balance,
        asset: erc20Token,
      ));
    }

    return _updateNativeBalances(address);
  }

  Future<Balance?> getBalance(Asset asset, String address) =>
      _balanceRepository.getBalance(asset, address);

  Future<void> _updateNativeBalances(String address) async {
    for (final chain in Blockchain.values) {
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
    }
  }
}
