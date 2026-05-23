import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:realunit_wallet/packages/storage/database.dart';
import 'package:realunit_wallet/packages/storage/key_value_cache.dart';

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  group('CacheStorage extension', () {
    test('writeCacheEntry persists the value and readCacheEntry round-trips it', () async {
      final rowId = await db.writeCacheEntry('settings.theme', 'dark');
      expect(rowId, greaterThan(0));

      final entry = await db.readCacheEntry('settings.theme');
      expect(entry, isNotNull);
      expect(entry!.id, 'settings.theme');
      expect(entry.value, 'dark');
    });

    test('readCacheEntry returns null for an unknown key', () async {
      expect(await db.readCacheEntry('unknown'), isNull);
    });

    test('writeCacheEntry uses insertOrReplace — the second write wins', () async {
      // The extension passes `InsertMode.insertOrReplace`; this test
      // pins that contract so a regression toward `insert` (which would
      // raise UNIQUE) is caught immediately.
      await db.writeCacheEntry('feature.x', 'enabled');
      await db.writeCacheEntry('feature.x', 'disabled');

      final entry = await db.readCacheEntry('feature.x');
      expect(entry!.value, 'disabled');

      final all = await db.allCacheEntries;
      expect(all, hasLength(1));
    });

    test('deleteCacheEntry removes only the targeted key', () async {
      await db.writeCacheEntry('a', '1');
      await db.writeCacheEntry('b', '2');

      final removed = await db.deleteCacheEntry('a');
      expect(removed, 1);

      expect(await db.readCacheEntry('a'), isNull);
      expect((await db.readCacheEntry('b'))!.value, '2');
    });

    test('deleteCacheEntry returns 0 when the key does not exist', () async {
      expect(await db.deleteCacheEntry('missing'), 0);
    });

    test('allCacheEntries returns every persisted entry', () async {
      await db.writeCacheEntry('a', '1');
      await db.writeCacheEntry('b', '2');
      await db.writeCacheEntry('c', '3');

      final all = await db.allCacheEntries;
      expect(all.map((e) => e.id).toSet(), {'a', 'b', 'c'});
    });

    test('allCacheEntries is empty on a fresh database', () async {
      expect(await db.allCacheEntries, isEmpty);
    });
  });
}
