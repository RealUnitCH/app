import 'package:deuro_wallet/packages/storage/database.dart';
import 'package:deuro_wallet/packages/storage/key_value_cache.dart';

class CacheRepository {
  final AppDatabase _appDatabase;

  const CacheRepository(this._appDatabase);

  Future<int> write(String key, String value) =>
      _appDatabase.writeCacheEntry(key, value);

  Future<String?> read(String key) async =>
      (await _appDatabase.readCacheEntry(key))?.value;
}
