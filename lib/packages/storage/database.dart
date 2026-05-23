import 'dart:developer';
import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:path/path.dart' as p;
import 'package:realunit_wallet/packages/io/documents_directory_port.dart';
import 'package:realunit_wallet/packages/io/path_provider_adapter.dart';
import 'package:realunit_wallet/packages/storage/asset_storage.dart';
import 'package:realunit_wallet/packages/storage/balance_storage.dart';
import 'package:realunit_wallet/packages/storage/dfx_transaction_storage.dart';
import 'package:realunit_wallet/packages/storage/key_value_cache.dart';
import 'package:realunit_wallet/packages/storage/node_storage.dart';
import 'package:realunit_wallet/packages/storage/transaction_storage.dart';
import 'package:realunit_wallet/packages/storage/wallet_storage.dart';

part 'database.g.dart';

const _databaseFileName = 'wallet.db.enc';

// `tryOpeningDatabase` constructs the production AppDatabase, which goes
// through `_openDatabase` → SQLCipher + path_provider. Neither is available
// under `flutter test`, so this function cannot be exercised in unit tests;
// it is covered by the integration / device test layer.
// coverage:ignore-start
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
// coverage:ignore-end

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
  // Production constructor — opens the on-disk SQLCipher database. Only
  // reachable from the embedder; tests use `AppDatabase.forTesting`.
  // coverage:ignore-start
  AppDatabase(String encryptionPassword) : super(_openDatabase(encryptionPassword));
  // coverage:ignore-end

  /// In-memory database for unit tests. Bypasses SQLCipher and path_provider.
  @visibleForTesting
  AppDatabase.forTesting(super.executor);

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

  /// Resolves the on-disk path of the SQLCipher database file.
  ///
  /// Routes through [DocumentsDirectoryPort] so unit tests can substitute a
  /// writable temp-dir fake instead of going through `path_provider`'s
  /// platform channel (which has no in-process implementation under
  /// `flutter test`). Production calls pass nothing; the
  /// [PathProviderAdapter] default forwards 1:1 to
  /// `path_provider.getApplicationDocumentsDirectory`, so runtime behaviour
  /// is unchanged.
  static Future<String> getDatabasePath([
    DocumentsDirectoryPort directory = const PathProviderAdapter(),
  ]) async {
    final path = await directory.getApplicationDocumentsDirectory();
    return p.join(path.path, _databaseFileName);
  }
}

// coverage:ignore-start
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

// coverage:ignore-end
