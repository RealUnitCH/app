import 'package:drift/drift.dart' show Variable;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:realunit_wallet/packages/storage/database.dart';

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  group('Nodes table', () {
    // `node_storage.dart` only declares the Drift schema for the `nodes`
    // table — there is no extension code on AppDatabase. The schema
    // getters themselves are codegen-only and pinned with
    // `coverage:ignore-line`. The behaviour we can still test is that
    // the table is materialised on a fresh database and accepts the
    // expected rows via the Drift API.

    test('table is created with the documented column set', () async {
      final cols = await db.customSelect("PRAGMA table_info('nodes')").get();
      final names = cols.map((r) => r.read<String>('name')).toSet();

      expect(names, containsAll(['chain_id', 'name', 'https_url', 'wss_url']));
    });

    test('chain_id has a UNIQUE constraint', () async {
      // Two rows with the same chain_id must be rejected.
      await db.customInsert(
        'INSERT INTO nodes (chain_id, name, https_url) VALUES (?, ?, ?)',
        variables: [
          const Variable<int>(1),
          const Variable<String>('mainnet-1'),
          const Variable<String>('https://a.example/rpc'),
        ],
      );

      expect(
        () => db.customInsert(
          'INSERT INTO nodes (chain_id, name, https_url) VALUES (?, ?, ?)',
          variables: [
            const Variable<int>(1),
            const Variable<String>('mainnet-2'),
            const Variable<String>('https://b.example/rpc'),
          ],
        ),
        throwsA(isA<Exception>()),
      );
    });

    test('wss_url is nullable', () async {
      final rowId = await db.customInsert(
        'INSERT INTO nodes (chain_id, name, https_url) VALUES (?, ?, ?)',
        variables: [
          const Variable<int>(11155111),
          const Variable<String>('sepolia'),
          const Variable<String>('https://sepolia.example/rpc'),
        ],
      );
      expect(rowId, greaterThan(0));
    });
  });
}
