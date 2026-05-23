import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:realunit_wallet/packages/storage/database.dart';
import 'package:realunit_wallet/packages/storage/dfx_transaction_storage.dart';
import 'package:realunit_wallet/packages/storage/transaction_storage.dart';
import 'package:realunit_wallet/packages/storage/wallet_storage.dart';

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  group('AppDatabase schema', () {
    test('schema version is 2', () {
      expect(db.schemaVersion, 2);
    });

    test('creates all expected tables on fresh database', () async {
      final rows = await db
          .customSelect(
            "SELECT name FROM sqlite_master WHERE type='table' AND name NOT LIKE 'sqlite_%'",
          )
          .get();
      final names = rows.map((r) => r.read<String>('name')).toSet();

      expect(names, containsAll([
        'assets',
        'balances',
        'key_value_cache',
        'nodes',
        'transactions',
        'dfx_transaction_details',
        'wallet_account_infos',
        'wallet_infos',
      ]));
    });

    test('wallet_infos accepts inserts via Drift API', () async {
      final id = await db.insertWallet('Test', 'encrypted-seed', '0xAddress', 0);

      expect(id, greaterThan(0));

      final row = await db.getWalletById(id);
      expect(row, isNotNull);
      expect(row!.name, 'Test');
      expect(row.seed, 'encrypted-seed');
      expect(row.address, '0xAddress');
    });

    test('dfx_transaction_details references transactions via tx_id', () async {
      await db.insertTransactions(
        1, 'tx-1', 1, '0xA', '0xB', '100', 1, 0, '', '', DateTime.now(),
      );

      await db.insertDfxTransactionDetails(txId: 'tx-1', dfxId: 42);

      final details = await db.getDfxTransactionDetailsByDfxId(42);
      expect(details, isNotNull);
      expect(details!.txId, 'tx-1');
    });
  });
}
