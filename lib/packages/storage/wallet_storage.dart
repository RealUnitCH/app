import 'package:drift/drift.dart';
import 'package:realunit_wallet/packages/storage/database.dart';

extension WalletStorage on AppDatabase {
  Future<int> insertWallet(String name, String seed, String address, int walletType) => into(
    walletInfos,
  ).insert(WalletInfosCompanion.insert(name: name, seed: seed, address: address, type: walletType));

  Future<WalletInfo?> getWalletById(int id) =>
      (select(walletInfos)..where((row) => row.id.equals(id))).getSingleOrNull();

  Future<int> updateWalletAddress(int id, String address) => (update(
    walletInfos,
  )..where((row) => row.id.equals(id))).write(WalletInfosCompanion(address: Value(address)));

  Future<int> insertWalletAccount(int walletId, String name, int accountIndex) =>
      into(walletAccountInfos).insert(
        WalletAccountInfosCompanion.insert(
          name: name,
          accountIndex: accountIndex,
          wallet: walletId,
        ),
      );

  Future<List<WalletAccountInfo>> getWalletAccounts(int walletId) =>
      (select(walletAccountInfos)..where((row) => row.wallet.equals(walletId))).get();

  /// Number of `walletInfos` rows currently on disk. Callers use this to
  /// detect "this was the last wallet" so wallet-delete can chain into a
  /// `SecureStorage.deleteMnemonicEncryptionKey` if the opt-in setting is
  /// enabled — without that count, the chain has no way to tell.
  Future<int> countWallets() async => (await select(walletInfos).get()).length;

  /// Deletes the wallet row identified by [walletId] and its dependent
  /// `walletAccountInfos` rows. The delete order matters — the FK on
  /// `walletAccountInfos.wallet` references `walletInfos.id`, so we drop
  /// the dependent rows first to avoid a FK-violation when sqlite enforces
  /// integrity. The pre-Initiative-IV implementation only deleted from
  /// `walletAccountInfos`, leaving the encrypted seed row in `walletInfos`
  /// on disk forever — see F-001 / BL-004. The encryption key still lives
  /// in Keychain, but defence-in-depth says we don't keep encrypted seeds
  /// past wallet-delete.
  ///
  /// Returns the row counts deleted so the caller can audit (e.g. a Tier-1
  /// integration test verifying the cleanup chain). Both counts are
  /// expected to be non-negative; a count of 0 on either is legitimate (a
  /// freshly-created wallet may have no account rows yet, or a partial
  /// previous delete may have left the account rows behind).
  Future<({int accountRows, int walletRows})> deleteWallet(int walletId) async {
    // Run as a single transaction so the FK ordering invariant holds even
    // under concurrent writers — without this, a parallel `insertWallet`
    // could land between the two deletes and a SQLite trigger snapshot
    // would see a partial state. drift's `transaction` is an explicit
    // unit-of-work; the deletes inside it are isolated from outside reads.
    return transaction(() async {
      final accountRows = await (delete(walletAccountInfos)
            ..where((row) => row.wallet.equals(walletId)))
          .go();
      final walletRows = await (delete(walletInfos)
            ..where((row) => row.id.equals(walletId)))
          .go();
      return (accountRows: accountRows, walletRows: walletRows);
    });
  }

  /// Deletes the `walletInfos` row itself (the encrypted-seed record) after
  /// clearing its dependent `walletAccountInfos` rows (FK in
  /// [WalletAccountInfos.wallet]).
  Future<void> deleteWalletCompletely(int walletId) => transaction(() async {
    await (delete(walletAccountInfos)..where((row) => row.wallet.equals(walletId))).go();
    await (delete(walletInfos)..where((row) => row.id.equals(walletId))).go();
  });

  Future<bool> get hasWallet => select(walletInfos).get().then((result) => result.isNotEmpty);
}

// The schema getters below are read by `drift_dev` at codegen time and the
// resulting column metadata is consumed via the generated mirror class —
// they are not invoked at runtime, so line-coverage instrumentation never
// marks them as executed. The same coverage gap exists on every Drift
// table in the repo. `// coverage:ignore-line` keeps the file at the
// surface the test suite can actually reach.
@DataClassName('WalletInfo')
class WalletInfos extends Table {
  IntColumn get id => integer().autoIncrement()(); // coverage:ignore-line

  TextColumn get name => text()(); // coverage:ignore-line

  TextColumn get seed => text()(); // coverage:ignore-line

  TextColumn get address => text()(); // coverage:ignore-line

  IntColumn get type => integer()(); // coverage:ignore-line
}

@DataClassName('WalletAccountInfo')
class WalletAccountInfos extends Table {
  IntColumn get id => integer().autoIncrement()(); // coverage:ignore-line

  TextColumn get name => text()(); // coverage:ignore-line

  IntColumn get accountIndex => integer()(); // coverage:ignore-line

  IntColumn get wallet => integer().references(WalletInfos, #id)(); // coverage:ignore-line
}
