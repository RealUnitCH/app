import 'dart:async';
import 'dart:developer' as developer;

import 'package:realunit_wallet/models/asset.dart';
import 'package:realunit_wallet/packages/storage/asset_storage.dart';
import 'package:realunit_wallet/packages/storage/database.dart';

class AssetRepository {
  final AppDatabase _appDatabase;

  const AssetRepository(this._appDatabase);

  Future<void> saveAsset(Asset asset) async {
    final exists = await exitsAsset(asset);
    developer.log('${asset.name} $exists', name: 'AssetRepository.saveAsset');
    if (!exists) await insertAsset(asset);
  }

  Future<int> insertAsset(Asset asset) => _appDatabase.insertAsset(
        asset.id,
        asset.chainId,
        asset.address,
        asset.symbol,
        asset.name,
        asset.decimals,
        null,
        false,
      );

  Future<void> updateAsset(Asset asset) =>
      _appDatabase.updateAsset(asset.id, iconUrl: null);

  Future<Asset?> getAsset(int chainId, String address) =>
      _appDatabase.getAsset(chainId, address).then((asset) => asset != null
          ? Asset(
              chainId: asset.chainId,
              address: asset.address,
              name: asset.name,
              symbol: asset.symbol,
              decimals: asset.decimals,
            )
          : null);

  Future<List<Asset>> get allAssets =>
      _appDatabase.allAssets.then((assets) => assets
          .map((asset) => Asset(
                chainId: asset.chainId,
                address: asset.address,
                name: asset.name,
                symbol: asset.symbol,
                decimals: asset.decimals,
              ))
          .toList());

  Future<bool> exitsAsset(Asset asset) =>
      getAsset(asset.chainId, asset.address)
          .then((asset) => asset != null);
}
