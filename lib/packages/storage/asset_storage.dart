import 'package:drift/drift.dart';
import 'package:realunit_wallet/packages/storage/database.dart';
import 'package:realunit_wallet/packages/utils/fast_hash.dart';

extension AssetStorage on AppDatabase {
  Future<int> insertAsset(int id, int chainId, String address, String symbol, String name,
          int decimals, String? iconUrl, bool editable) =>
      into(assets).insert(AssetsCompanion.insert(
        id: id,
        chainId: chainId,
        address: address,
        symbol: symbol,
        name: name,
        decimals: decimals,
        iconUrl: Value(iconUrl),
        editable: editable,
      ));

  Future<int> updateAsset(int id, {String? iconUrl}) =>
      (update(assets)..where((row) => row.id.equals(id)))
          .write(AssetsCompanion(iconUrl: Value(iconUrl)));

  Future<AssetData?> getAsset(int chainId, String address) =>
      (select(assets)..where((row) => row.id.equals(fastHash('$chainId:$address'))))
          .getSingleOrNull();

  Future<List<AssetData>> get allAssets => assets.all().get();
}

@DataClassName('AssetData')
class Assets extends Table {
  IntColumn get id => integer().unique()();

  IntColumn get chainId => integer()();

  TextColumn get address => text()();

  TextColumn get symbol => text()();

  TextColumn get name => text()();

  IntColumn get decimals => integer()();

  TextColumn get iconUrl => text().nullable()();

  BoolColumn get editable => boolean()();
}
