// Tier-1 integration test for the BL-004 cleanup chain. Drives a
// realistic multi-wallet create-then-delete sequence against the
// production Drift database (in-memory) + a WalletRepository wired
// over a real SecureStorage encryption pass, and asserts:
//
//   - Each delete drops both walletAccountInfos AND walletInfos rows
//     (the F-001 fix from Initiative IV).
//   - The walletInfos row count tracks creates - deletes as a
//     property over any sequence.
//   - On the LAST delete with the opt-in flag set, the mnemonic
//     encryption key is wiped — every earlier delete leaves it
//     alone.
//
// The test uses an in-memory NativeDatabase and a Mock SecureStorage,
// so no platform channel scaffolding is required. The mnemonic
// encryption key is treated as a single opaque blob — its actual
// AES-GCM round trip is covered by the Tier-0 wallet_isolate_test
// + secure_storage_test.

import 'dart:typed_data';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:realunit_wallet/packages/hardware_wallet/bitbox.dart';
import 'package:realunit_wallet/packages/repository/settings_repository.dart';
import 'package:realunit_wallet/packages/repository/wallet_repository.dart';
import 'package:realunit_wallet/packages/service/app_store.dart';
import 'package:realunit_wallet/packages/service/wallet_service.dart';
import 'package:realunit_wallet/packages/storage/database.dart';
import 'package:realunit_wallet/packages/storage/secure_storage.dart';
import 'package:realunit_wallet/packages/storage/wallet_storage.dart';
import 'package:realunit_wallet/packages/wallet/wallet.dart';

import '../test_utils/fake_wallet_isolate.dart';

class _MockSettingsRepository extends Mock implements SettingsRepository {}

class _MockBitboxService extends Mock implements BitboxService {}

class _MockSecureStorage extends Mock implements SecureStorage {}

class _MockAppStore extends Mock implements AppStore {}

final _testKeyBytes = Uint8List.fromList(List.generate(32, (i) => i));

void main() {
  late AppDatabase db;
  late WalletRepository repo;
  late _MockSettingsRepository settings;
  late _MockBitboxService bitbox;
  late _MockAppStore appStore;
  late _MockSecureStorage secureStorage;
  late WalletService service;
  late FakeWalletIsolate isolate;

  setUpAll(() {
    registerFallbackValue(WalletType.software);
    registerFallbackValue(
      SoftwareViewWallet(0, 'fallback', '0x0000000000000000000000000000000000000001') as AWallet,
    );
  });

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    secureStorage = _MockSecureStorage();
    repo = WalletRepository(db, secureStorage);
    settings = _MockSettingsRepository();
    bitbox = _MockBitboxService();
    appStore = _MockAppStore();
    service = WalletService(bitbox, repo, settings, appStore, secureStorage);
    isolate = FakeWalletIsolate();
    service.debugInjectWalletIsolate(isolate);

    when(() => settings.saveCurrentWalletId(any())).thenAnswer((_) async => true);
    when(() => settings.removeCurrentWalletId()).thenAnswer((_) async => true);
    when(() => secureStorage.getOrCreateMnemonicKey())
        .thenAnswer((_) async => _testKeyBytes);
    when(() => secureStorage.deleteMnemonicEncryptionKey())
        .thenAnswer((_) async {});
  });

  tearDown(() async {
    await db.close();
  });

  group('wallet delete cleanup chain (BL-004 / F-001)', () {
    test('create 3 wallets -> delete each -> walletInfos drops to zero; '
        'encryption key is wiped only on the final delete when opt-in is set',
        () async {
      when(() => settings.deleteMnemonicKeyOnLastWalletDelete).thenReturn(true);

      // Create three wallets through the production restoreWallet
      // path. Each one persists an encrypted-seed row + adopts the
      // plaintext into the fake isolate slot.
      final id1 = (await service.restoreWallet('Alpha',
              'abandon ability able about above absent absorb abstract absurd abuse access accident')).id;
      final id2 = (await service.restoreWallet('Beta',
              'test test test test test test test test test test test junk')).id;
      final id3 = (await service.restoreWallet('Gamma',
              'legal winner thank year wave sausage worth useful legal winner thank yellow')).id;

      // Each restore allocates a distinct id.
      expect({id1, id2, id3}, hasLength(3));
      expect(await db.countWallets(), 3);

      // Add account rows so the cleanup chain actually has dependent
      // rows to delete (production wallets have at least the primary
      // account row).
      await db.insertWalletAccount(id1, 'A:0', 0);
      await db.insertWalletAccount(id2, 'B:0', 0);
      await db.insertWalletAccount(id3, 'C:0', 0);

      // ---- delete the first wallet ----
      when(() => settings.currentWalletId).thenReturn(id1);
      var result = await service.deleteCurrentWallet();

      expect(result.walletRows, 1);
      expect(result.accountRows, 1);
      expect(result.mnemonicKeyDeleted, isFalse,
          reason: 'two wallets still on disk — the mnemonic key must not be wiped');
      verifyNever(() => secureStorage.deleteMnemonicEncryptionKey());
      expect(await db.getWalletById(id1), isNull);
      expect(await db.countWallets(), 2);

      // ---- delete the second wallet ----
      when(() => settings.currentWalletId).thenReturn(id2);
      result = await service.deleteCurrentWallet();

      expect(result.walletRows, 1);
      expect(result.mnemonicKeyDeleted, isFalse,
          reason: 'one wallet still on disk — the mnemonic key must not be wiped');
      verifyNever(() => secureStorage.deleteMnemonicEncryptionKey());
      expect(await db.getWalletById(id2), isNull);
      expect(await db.countWallets(), 1);

      // ---- delete the third (last) wallet ----
      when(() => settings.currentWalletId).thenReturn(id3);
      result = await service.deleteCurrentWallet();

      expect(result.walletRows, 1);
      expect(result.mnemonicKeyDeleted, isTrue,
          reason: 'last-wallet-delete with opt-in set MUST wipe the encryption key');
      verify(() => secureStorage.deleteMnemonicEncryptionKey()).called(1);
      expect(await db.getWalletById(id3), isNull);
      expect(await db.countWallets(), 0,
          reason: 'BL-004: the encrypted seed rows are gone, not just the '
              'walletAccountInfos rows that the pre-IV deleteWallet touched');
    });

    test('delete chain with opt-in disabled never wipes the encryption key',
        () async {
      when(() => settings.deleteMnemonicKeyOnLastWalletDelete).thenReturn(false);

      final id1 = (await service.restoreWallet('A',
              'abandon ability able about above absent absorb abstract absurd abuse access accident')).id;
      final id2 = (await service.restoreWallet('B',
              'test test test test test test test test test test test junk')).id;

      when(() => settings.currentWalletId).thenReturn(id1);
      await service.deleteCurrentWallet();
      when(() => settings.currentWalletId).thenReturn(id2);
      final result = await service.deleteCurrentWallet();

      expect(await db.countWallets(), 0);
      expect(result.mnemonicKeyDeleted, isFalse,
          reason: 'opt-in disabled means the key survives — the conservative '
              'default per the ADR');
      verifyNever(() => secureStorage.deleteMnemonicEncryptionKey());
    });

    test('row count after a mixed sequence equals creates - deletes (property test)',
        () async {
      // The mandate calls this out explicitly in §5.4: "walletInfos
      // row count after a sequence of create/delete equals |creates|
      // - |deletes|". Drive a deterministic mixed sequence here so a
      // counter regression at the storage layer fails loudly.
      when(() => settings.deleteMnemonicKeyOnLastWalletDelete).thenReturn(false);

      final ids = <int>[];
      // create 5
      for (var i = 0; i < 5; i++) {
        final id = (await service.restoreWallet('W$i',
                'abandon ability able about above absent absorb abstract absurd abuse access accident')).id;
        ids.add(id);
      }
      expect(await db.countWallets(), 5);

      // delete 2
      when(() => settings.currentWalletId).thenReturn(ids[0]);
      await service.deleteCurrentWallet();
      when(() => settings.currentWalletId).thenReturn(ids[3]);
      await service.deleteCurrentWallet();
      expect(await db.countWallets(), 3);

      // create 2 more
      final id5 = (await service.restoreWallet('W5',
              'test test test test test test test test test test test junk')).id;
      final id6 = (await service.restoreWallet('W6',
              'legal winner thank year wave sausage worth useful legal winner thank yellow')).id;
      expect(await db.countWallets(), 5);

      // delete remaining 5
      for (final id in [ids[1], ids[2], ids[4], id5, id6]) {
        when(() => settings.currentWalletId).thenReturn(id);
        await service.deleteCurrentWallet();
      }

      expect(await db.countWallets(), 0,
          reason: 'create count == delete count → row count must be exactly 0');
    });
  });
}
