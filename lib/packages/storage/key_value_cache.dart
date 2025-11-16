import 'package:realunit_wallet/packages/storage/database.dart';
import 'package:drift/drift.dart';

extension CacheStorage on AppDatabase {
  Future<int> writeCacheEntry(String key, String value) =>
      into(keyValueCache).insert(CacheEntry(id: key, value: value),
          mode: InsertMode.insertOrReplace);

  Future<CacheEntry?> readCacheEntry(String key) =>
      (select(keyValueCache)..where((row) => row.id.equals(key)))
          .getSingleOrNull();

  Future<List<CacheEntry>> get allCacheEntries => keyValueCache.all().get();
}

@DataClassName("CacheEntry")
class KeyValueCache extends Table {
  TextColumn get id => text().unique()();

  TextColumn get value => text()();
}
