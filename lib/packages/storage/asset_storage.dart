import 'package:drift/drift.dart';
import 'package:realunit_wallet/packages/storage/database.dart';
import 'package:realunit_wallet/packages/utils/fast_hash.dart';

extension AssetStorage on AppDatabase {
  Future<int> insertAsset(
    int id,
    int chainId,
    String address,
    String symbol,
    String name,
    int decimals,
    String? iconUrl,
    bool editable,
  ) => into(assets).insert(
    AssetsCompanion.insert(
      id: id,
      chainId: chainId,
      address: address,
      symbol: symbol,
      name: name,
      decimals: decimals,
      iconUrl: Value(iconUrl),
      editable: editable,
    ),
  );

  Future<int> updateAsset(int id, {String? iconUrl}) => (update(
    assets,
  )..where((row) => row.id.equals(id))).write(AssetsCompanion(iconUrl: Value(iconUrl)));

  Future<AssetData?> getAsset(int chainId, String address) => (select(
    assets,
  )..where((row) => row.id.equals(fastHash('$chainId:$address')))).getSingleOrNull();

  Future<List<AssetData>> get allAssets => assets.all().get();
}

// The schema getters below are read by `drift_dev` at codegen time and the
// resulting column metadata is consumed via the generated mirror class —
// they are not invoked at runtime, so line-coverage instrumentation never
// marks them as executed. The same coverage gap exists on every Drift
// table in the repo. `// coverage:ignore-line` keeps the file at the
// surface the test suite can actually reach.
@DataClassName('AssetData')
class Assets extends Table {
  IntColumn get id => integer().unique()(); // coverage:ignore-line

  IntColumn get chainId => integer()(); // coverage:ignore-line

  TextColumn get address => text()(); // coverage:ignore-line

  TextColumn get symbol => text()(); // coverage:ignore-line

  TextColumn get name => text()(); // coverage:ignore-line

  IntColumn get decimals => integer()(); // coverage:ignore-line

  TextColumn get iconUrl => text().nullable()(); // coverage:ignore-line

  BoolColumn get editable => boolean()(); // coverage:ignore-line
}
