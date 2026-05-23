import 'package:drift/drift.dart';
import 'package:realunit_wallet/packages/storage/database.dart';

extension CacheStorage on AppDatabase {
  Future<int> writeCacheEntry(String key, String value) => into(keyValueCache).insert(
    CacheEntry(id: key, value: value),
    mode: InsertMode.insertOrReplace,
  );

  Future<CacheEntry?> readCacheEntry(String key) =>
      (select(keyValueCache)..where((row) => row.id.equals(key))).getSingleOrNull();

  Future<int> deleteCacheEntry(String key) =>
      (delete(keyValueCache)..where((row) => row.id.equals(key))).go();

  Future<List<CacheEntry>> get allCacheEntries => keyValueCache.all().get();
}

// The schema getters below are read by `drift_dev` at codegen time and the
// resulting column metadata is consumed via the generated mirror class —
// they are not invoked at runtime, so line-coverage instrumentation never
// marks them as executed. The same coverage gap exists on every Drift
// table in the repo. `// coverage:ignore-line` keeps the file at the
// surface the test suite can actually reach.
@DataClassName('CacheEntry')
class KeyValueCache extends Table {
  TextColumn get id => text().unique()(); // coverage:ignore-line

  TextColumn get value => text()(); // coverage:ignore-line
}
