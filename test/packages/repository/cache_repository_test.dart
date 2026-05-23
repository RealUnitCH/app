import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:realunit_wallet/packages/repository/cache_repository.dart';
import 'package:realunit_wallet/packages/storage/database.dart';

void main() {
  late AppDatabase db;
  late CacheRepository repo;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repo = CacheRepository(db);
  });

  tearDown(() async {
    await db.close();
  });

  group('$CacheRepository', () {
    test('read returns null for an unknown key', () async {
      expect(await repo.read('missing'), isNull);
    });

    test('write persists the value and read returns it', () async {
      await repo.write('settings.theme', 'dark');
      expect(await repo.read('settings.theme'), 'dark');
    });

    test('write is upsert — the second write overwrites the first', () async {
      // CacheRepository.write delegates to writeCacheEntry which uses
      // InsertMode.insertOrReplace. This test pins that contract from
      // the repository surface so a regression to plain insert is
      // caught here too.
      await repo.write('feature.x', 'on');
      await repo.write('feature.x', 'off');

      expect(await repo.read('feature.x'), 'off');
    });

    test('delete removes the entry and subsequent reads return null', () async {
      await repo.write('a', '1');
      await repo.write('b', '2');

      await repo.delete('a');

      expect(await repo.read('a'), isNull);
      // Unrelated keys must remain intact.
      expect(await repo.read('b'), '2');
    });

    test('delete is idempotent for unknown keys', () async {
      // The underlying Drift call returns 0 affected rows in that case;
      // the repository contract is fire-and-forget.
      await repo.delete('never-existed');
      expect(await repo.read('never-existed'), isNull);
    });
  });
}
