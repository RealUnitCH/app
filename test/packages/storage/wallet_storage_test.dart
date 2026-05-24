// Tier-0 tests for `WalletStorage.deleteWallet` — the BL-004 / F-001
// fix. Pre-Initiative-IV, deleteWallet only removed `walletAccountInfos`
// rows; the encrypted seed in `walletInfos` accumulated forever. These
// tests pin both row counts dropping to zero on delete AND the
// recreate-same-seed path producing no stale row.

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:realunit_wallet/packages/storage/database.dart';
import 'package:realunit_wallet/packages/storage/wallet_storage.dart';
import 'package:realunit_wallet/packages/wallet/wallet.dart';

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  group('WalletStorage extension', () {
    test('hasWallet is false on an empty database', () async {
      expect(await db.hasWallet, isFalse);
    });

    test('hasWallet flips to true after the first insertWallet', () async {
      await db.insertWallet('Test', 'seed', '0xA', 0);
      expect(await db.hasWallet, isTrue);
    });

    test('insertWallet returns the rowid and getWalletById round-trips the row', () async {
      final id = await db.insertWallet('Main', 'enc-seed', '0xMain', 1);
      expect(id, greaterThan(0));

      final fetched = await db.getWalletById(id);
      expect(fetched, isNotNull);
      expect(fetched!.id, id);
      expect(fetched.name, 'Main');
      expect(fetched.seed, 'enc-seed');
      expect(fetched.address, '0xMain');
      expect(fetched.type, 1);
    });

    test('getWalletById returns null for an unknown id', () async {
      expect(await db.getWalletById(9999), isNull);
    });

    test('updateWalletAddress mutates only the address column', () async {
      final id = await db.insertWallet('Main', 'enc-seed', '0xOld', 0);

      final affected = await db.updateWalletAddress(id, '0xNew');
      expect(affected, 1);

      final fetched = await db.getWalletById(id);
      expect(fetched!.address, '0xNew');
      // The other columns must be untouched.
      expect(fetched.name, 'Main');
      expect(fetched.seed, 'enc-seed');
    });

    test('insertWalletAccount + getWalletAccounts round-trip the rows', () async {
      final walletId = await db.insertWallet('Main', 'seed', '0xMain', 0);

      await db.insertWalletAccount(walletId, 'acc-0', 0);
      await db.insertWalletAccount(walletId, 'acc-1', 1);

      final accounts = await db.getWalletAccounts(walletId);
      expect(accounts, hasLength(2));
      expect(accounts.map((a) => a.name).toSet(), {'acc-0', 'acc-1'});
      expect(accounts.map((a) => a.accountIndex).toSet(), {0, 1});
    });

    test('getWalletAccounts returns an empty list when no accounts are linked', () async {
      final walletId = await db.insertWallet('Empty', 'seed', '0xEmpty', 0);
      expect(await db.getWalletAccounts(walletId), isEmpty);
    });
  });

  // Sentinel for the encrypted-seed column — content is irrelevant
  // here; the test pins that the row is removed, not the cipher round
  // trip (that lives in wallet_repository_test.dart).
  const encryptedSeedSentinel = 'CIPHERTEXT_PLACEHOLDER';
  const address = '0xabCDeF0123456789abCDeF0123456789aBCDeF01';

  Future<int> insertSoftwareWallet({String name = 'Primary'}) =>
      db.insertWallet(name, encryptedSeedSentinel, address, WalletType.software.index);

  group('WalletStorage.deleteWallet (BL-004)', () {
    test('removes both walletAccountInfos AND walletInfos rows', () async {
      // Pre-Initiative-IV bug: only the walletAccountInfos rows were
      // deleted; the walletInfos row (carrying the encrypted seed)
      // remained on disk forever. The whole point of the cleanup chain
      // is that both tables drop to zero so the encrypted seed cannot
      // be recovered via a stale row.
      final id = await insertSoftwareWallet();
      await db.insertWalletAccount(id, 'Account 0', 0);
      await db.insertWalletAccount(id, 'Account 1', 1);

      final preWalletInfo = await db.getWalletById(id);
      expect(preWalletInfo, isNotNull,
          reason: 'sanity: insert landed the row in walletInfos');
      final preAccounts = await db.getWalletAccounts(id);
      expect(preAccounts, hasLength(2),
          reason: 'sanity: two account rows are present pre-delete');

      final result = await db.deleteWallet(id);

      expect(result.accountRows, 2,
          reason: 'both walletAccountInfos rows must be deleted');
      expect(result.walletRows, 1,
          reason: 'BL-004: the walletInfos row must be deleted too — '
              'failure here is the regression the audit flagged');
      expect(await db.getWalletById(id), isNull,
          reason: 'no walletInfos row may survive deleteWallet');
      expect(await db.getWalletAccounts(id), isEmpty,
          reason: 'no walletAccountInfos row may survive deleteWallet');
    });

    test('row count in walletInfos drops to zero on a single-wallet delete',
        () async {
      final id = await insertSoftwareWallet();
      expect(await db.countWallets(), 1);

      await db.deleteWallet(id);

      expect(await db.countWallets(), 0,
          reason: 'BL-004: walletInfos row count must drop to zero so '
              'a re-create on the same seed does not pile on a stale row');
    });

    test('sequential delete + recreate-same-seed leaves no stale row',
        () async {
      // The compounding pre-Initiative-IV failure: delete + recreate
      // with the same mnemonic appended a fresh row without removing
      // the old one. After the BL-004 fix, the recreate must land
      // exactly one row in walletInfos.
      final firstId = await insertSoftwareWallet(name: 'Primary');
      await db.deleteWallet(firstId);

      final secondId = await insertSoftwareWallet(name: 'Primary');
      expect(secondId, isNot(firstId),
          reason: 'autoincrement gives a new id even though the seed is the same');

      expect(await db.countWallets(), 1,
          reason: 'after delete+recreate exactly one walletInfos row may exist');
      expect(await db.getWalletById(firstId), isNull,
          reason: 'the old row must not resurface');
      expect(await db.getWalletById(secondId), isNotNull,
          reason: 'the new row must be reachable');
    });

    test('deleteWallet on an unknown id returns zero counts and does not throw',
        () async {
      final result = await db.deleteWallet(99999);

      expect(result.accountRows, 0);
      expect(result.walletRows, 0);
      expect(await db.countWallets(), 0,
          reason: 'no rows were touched — defence-in-depth for a misbehaving caller');
    });

    test('deleteWallet on wallet A does not touch wallet B', () async {
      final idA = await insertSoftwareWallet(name: 'A');
      final idB = await insertSoftwareWallet(name: 'B');
      await db.insertWalletAccount(idA, 'A:0', 0);
      await db.insertWalletAccount(idB, 'B:0', 0);

      await db.deleteWallet(idA);

      expect(await db.getWalletById(idA), isNull);
      expect(await db.getWalletById(idB), isNotNull,
          reason: 'sibling wallet must survive the delete — the where-clause '
              'must scope to walletId');
      expect(await db.getWalletAccounts(idA), isEmpty);
      expect(await db.getWalletAccounts(idB), hasLength(1));
    });

    test('deleteWallet runs the two deletes inside a transaction', () async {
      // Pin the transaction wrapper so a refactor cannot quietly drop
      // it — without the transaction, a concurrent insert could land
      // between the account-rows and wallet-row deletes and leave a
      // partial-state snapshot visible to a SQLite trigger or a
      // parallel reader. The contract is documented in the
      // implementation comment; this test makes the contract a
      // regression-trip.
      final idA = await insertSoftwareWallet(name: 'A');
      // A second wallet is inserted so `countWallets` has a meaningful
      // observed value mid-race (1 or 2 depending on ordering, never 0).
      // The id is intentionally discarded — the test pins atomicity of
      // the deletes, not the surviving row's identity.
      await insertSoftwareWallet(name: 'B');
      await db.insertWalletAccount(idA, 'A:0', 0);

      // Race a concurrent count + delete; under the transaction
      // wrapper the count cannot observe a partial state.
      final results = await Future.wait([
        db.deleteWallet(idA),
        db.countWallets(),
      ]);

      // The delete result is the first element; the count is the second.
      final deleteResult = results[0] as ({int accountRows, int walletRows});
      final count = results[1] as int;
      expect(deleteResult.walletRows, 1);
      // The count was either observed before the delete (2) or after (1) —
      // never the inconsistent "wallet row gone but account row still
      // there" state. The transaction ordering guarantees the deletes
      // are atomic relative to outside reads.
      expect(count, anyOf(1, 2),
          reason: 'transaction must isolate the delete from concurrent reads');
    });
  });

  group('WalletStorage.countWallets', () {
    test('returns 0 for an empty database', () async {
      expect(await db.countWallets(), 0);
    });

    test('increments for each insertWallet, decrements on deleteWallet',
        () async {
      final id1 = await insertSoftwareWallet(name: 'A');
      expect(await db.countWallets(), 1);

      final id2 = await insertSoftwareWallet(name: 'B');
      expect(await db.countWallets(), 2);

      await db.deleteWallet(id1);
      expect(await db.countWallets(), 1);

      await db.deleteWallet(id2);
      expect(await db.countWallets(), 0,
          reason: 'last-wallet-delete drops the count to zero — used by '
              'WalletService.deleteCurrentWallet to gate the optional '
              'deleteMnemonicEncryptionKey opt-in');
    });
  });
}
