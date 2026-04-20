import 'dart:developer';
import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:realunit_wallet/packages/storage/asset_storage.dart';
import 'package:realunit_wallet/packages/storage/balance_storage.dart';
import 'package:realunit_wallet/packages/storage/dfx_transaction_storage.dart';
import 'package:realunit_wallet/packages/storage/key_value_cache.dart';
import 'package:realunit_wallet/packages/storage/node_storage.dart';
import 'package:realunit_wallet/packages/storage/transaction_storage.dart';
import 'package:realunit_wallet/packages/storage/wallet_storage.dart';

part 'database.g.dart';

const _databaseFileName = 'wallet.db.enc';

Future<bool> tryOpeningDatabase(String encryptionPassword) async {
  final database = AppDatabase(encryptionPassword);
  try {
    await database.select(database.assets).get();
    await database.close();
    return true;
  } on SqliteException catch (e) {
    log('SqliteException', error: e, name: 'AppDatabase tryOpeningDatabase');
    if (e.resultCode == 26) {
      log('Wrong Pin', error: e, name: 'AppDatabase tryOpeningDatabase');
    }
  } catch (e) {
    log('Unexpected Error', error: e, name: 'AppDatabase tryOpeningDatabase');
  } finally {
    await database.close();
  }
  return false;
}

@DriftDatabase(
  tables: [
    Assets,
    Balances,
    KeyValueCache,
    Nodes,
    Transactions,
    DfxTransactionDetails,
    WalletAccountInfos,
    WalletInfos,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase(String encryptionPassword) : super(_openDatabase(encryptionPassword));

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (Migrator m) async {
      await m.createAll();
    },
    onUpgrade: (Migrator m, int from, int to) async {
      if (from < 2) {
        await m.createTable(dfxTransactionDetails);
      }
    },
  );

  static Future<String> getDatabasePath() async {
    final path = await getApplicationDocumentsDirectory();
    return p.join(path.path, _databaseFileName);
  }
}

QueryExecutor _openDatabase(String encryptionPassword) {
  return LazyDatabase(() async {
    final path = await AppDatabase.getDatabasePath();

    return NativeDatabase.createInBackground(
      File(path),
      setup: (db) {
        final escapedKey = encryptionPassword.replaceAll("'", "''");
        db.execute("pragma cipher = 'sqlcipher'");
        db.execute('pragma legacy = 4');
        db.execute("pragma key = '$escapedKey'");
        db.execute('select count(*) from sqlite_master');
      },
    );
  });
}
