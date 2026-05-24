import 'dart:typed_data';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:realunit_wallet/packages/repository/wallet_repository.dart';
import 'package:realunit_wallet/packages/storage/database.dart';
import 'package:realunit_wallet/packages/storage/secure_storage.dart';
import 'package:realunit_wallet/packages/storage/wallet_storage.dart';
import 'package:realunit_wallet/packages/wallet/wallet.dart';

class _MockSecureStorage extends Mock implements SecureStorage {}

void main() {
  late AppDatabase db;
  late _MockSecureStorage secureStorage;
  late WalletRepository repo;

  // Deterministic 256-bit AES-GCM key — content is irrelevant for the
  // round-trip assertions, only that the encrypt/decrypt static helpers
  // get the same bytes both ways.
  final mnemonicKey = Uint8List.fromList(List<int>.generate(32, (i) => i));

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    secureStorage = _MockSecureStorage();
    repo = WalletRepository(db, secureStorage);

    when(() => secureStorage.getOrCreateMnemonicKey()).thenAnswer((_) async => mnemonicKey);
  });

  tearDown(() async {
    await db.close();
  });

  const seed = 'test mnemonic words go here twelve total for a real bip39';
  const walletName = 'Primary';
  const address = '0xabCDeF0123456789abCDeF0123456789aBCDeF01';

  group('$WalletRepository', () {
    test('createWallet encrypts the seed before persisting it', () async {
      final id = await repo.createWallet(walletName, WalletType.software, seed, address);

      expect(id, greaterThan(0));

      final row = await db.getWalletById(id);
      expect(row, isNotNull);
      expect(row!.name, walletName);
      expect(row.address, address);
      expect(row.type, WalletType.software.index);
      // The stored seed must not be the plaintext: the whole point of
      // the encrypt step is that a leaked DB row doesn't equal the
      // mnemonic.
      expect(row.seed, isNot(equals(seed)));
      expect(row.seed, isNotEmpty);

      verify(() => secureStorage.getOrCreateMnemonicKey()).called(1);
    });

    test('createViewWallet stores an empty seed and bypasses the secure storage', () async {
      final id = await repo.createViewWallet(walletName, WalletType.software, address);

      expect(id, greaterThan(0));

      final row = await db.getWalletById(id);
      expect(row, isNotNull);
      expect(row!.name, walletName);
      expect(row.address, address);
      expect(row.seed, isEmpty);
      // No encryption key is fetched for a view wallet because there
      // is no seed material to wrap.
      verifyNever(() => secureStorage.getOrCreateMnemonicKey());
    });

    test('getWalletInfo returns the row with the seed still encrypted', () async {
      final id = await repo.createWallet(walletName, WalletType.software, seed, address);

      final info = await repo.getWalletInfo(id);
      expect(info, isNotNull);
      expect(info!.name, walletName);
      // getWalletInfo must NOT decrypt — that is the whole reason
      // the fast-path exists.
      expect(info.seed, isNot(equals(seed)));
      expect(info.seed, isNotEmpty);
    });

    test('getWalletInfo returns null for an unknown id', () async {
      expect(await repo.getWalletInfo(99999), isNull);
    });

    test('updateAddress backfills the address column', () async {
      final id = await repo.createViewWallet(walletName, WalletType.software, '');

      const newAddress = '0xfedCBA9876543210fedCBA9876543210fEdCbA98';
      await repo.updateAddress(id, newAddress);

      final info = await repo.getWalletInfo(id);
      expect(info, isNotNull);
      expect(info!.address, newAddress);
    });

    test('getUnlockedWalletById decrypts the seed back to the plaintext', () async {
      final id = await repo.createWallet(walletName, WalletType.software, seed, address);

      final unlocked = await repo.getUnlockedWalletById(id);

      expect(unlocked, isNotNull);
      expect(unlocked!.seed, seed);
      expect(unlocked.name, walletName);
      expect(unlocked.address, address);
    });

    test('getUnlockedWalletById returns null for an unknown id', () async {
      expect(await repo.getUnlockedWalletById(99999), isNull);
    });

    test('getUnlockedWalletById short-circuits when the seed column is empty', () async {
      // View wallets have an empty seed string. The decrypt branch is
      // guarded by `if (info.seed.isEmpty) return info`; without that
      // short-circuit the GCM cipher would be handed an empty cipher
      // text and throw — so this test pins the early-return behaviour
      // and verifies the secure storage is never reached.
      final id = await repo.createViewWallet(walletName, WalletType.software, address);

      final unlocked = await repo.getUnlockedWalletById(id);

      expect(unlocked, isNotNull);
      expect(unlocked!.seed, isEmpty);
      verifyNever(() => secureStorage.getOrCreateMnemonicKey());
    });

    test('deleteWallet removes BOTH wallet-account-info AND wallet-info rows (BL-004)',
        () async {
      // Post-Initiative-IV: deleteWallet drops both the dependent
      // walletAccountInfos rows AND the walletInfos row carrying the
      // encrypted seed. Pre-IV the walletInfos row stayed forever, so
      // a leaked Keychain key could later recover every wallet ever
      // created on this install.
      final walletId =
          await repo.createWallet(walletName, WalletType.software, seed, address);
      await db.insertWalletAccount(walletId, 'acc-0', 0);

      final beforeAccounts = await db.getWalletAccounts(walletId);
      expect(beforeAccounts, hasLength(1));
      expect(await db.getWalletById(walletId), isNotNull);

      final result = await repo.deleteWallet(walletId);

      expect(result.accountRows, 1);
      expect(result.walletRows, 1,
          reason: 'BL-004: walletInfos row count must be surfaced and '
              'must drop to one — the cleanup chain is auditable end-to-end');
      expect(await db.getWalletAccounts(walletId), isEmpty);
      expect(await db.getWalletById(walletId), isNull,
          reason: 'encrypted seed row must NOT survive the delete');
    });

    test('isLastWallet returns true when no wallet rows remain', () async {
      expect(await repo.isLastWallet(), isTrue,
          reason: 'fresh DB is the trivial "no other wallets" case');
    });

    test('isLastWallet returns false while siblings still exist', () async {
      await repo.createWallet(walletName, WalletType.software, seed, address);
      await repo.createWallet('Other', WalletType.software, seed, address);

      expect(await repo.isLastWallet(), isFalse,
          reason: 'two rows are present — last-wallet check must be false');
    });

    test('isLastWallet flips to true after the final delete', () async {
      final id1 =
          await repo.createWallet(walletName, WalletType.software, seed, address);
      final id2 =
          await repo.createWallet('Second', WalletType.software, seed, address);

      expect(await repo.isLastWallet(), isFalse);

      await repo.deleteWallet(id1);
      expect(await repo.isLastWallet(), isFalse,
          reason: 'one row still survives — not the last delete yet');

      await repo.deleteWallet(id2);
      expect(await repo.isLastWallet(), isTrue,
          reason: 'the last delete must flip isLastWallet to true so the '
              'WalletService gate can decide whether to wipe the mnemonic '
              'encryption key (when the opt-in is enabled)');
    });
  });
}
