import 'dart:async';
import 'dart:typed_data';

import 'package:bitbox_flutter/bitbox_flutter.dart';
import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:realunit_wallet/packages/hardware_wallet/bitbox.dart';
import 'package:realunit_wallet/packages/hardware_wallet/bitbox_credentials.dart';
import 'package:realunit_wallet/packages/repository/settings_repository.dart';
import 'package:realunit_wallet/packages/repository/wallet_repository.dart';
import 'package:realunit_wallet/packages/service/app_store.dart';
import 'package:realunit_wallet/packages/service/wallet_service.dart';
import 'package:realunit_wallet/packages/storage/database.dart';
import 'package:realunit_wallet/packages/storage/secure_storage.dart';
import 'package:realunit_wallet/packages/wallet/wallet.dart';

import '../../test_utils/fake_wallet_isolate.dart';

class _MockWalletRepository extends Mock implements WalletRepository {}

class _MockSettingsRepository extends Mock implements SettingsRepository {}

class _MockBitboxService extends Mock implements BitboxService {}

class _MockBitboxManager extends Mock implements BitboxManager {}

class _MockAppStore extends Mock implements AppStore {}

class _MockSecureStorage extends Mock implements SecureStorage {}

const _testMnemonic = 'test test test test test test test test test test test junk';
const _debugAddress = '0x0000000000000000000000000000000000000001';
final _testKeyBytes = Uint8List.fromList(List.generate(32, (i) => i));

WalletInfo _info({
  int id = 1,
  String name = 'Main',
  String seed = '',
  String address = '',
  required WalletType type,
}) => WalletInfo(id: id, name: name, seed: seed, address: address, type: type.index);

void main() {
  late _MockWalletRepository repo;
  late _MockSettingsRepository settings;
  late _MockBitboxService bitbox;
  late _MockBitboxManager bitboxManager;
  late _MockAppStore appStore;
  late _MockSecureStorage secureStorage;
  late WalletService service;
  late FakeWalletIsolate isolate;

  setUpAll(() {
    // mocktail needs a default for non-primitive types used with `any()`.
    registerFallbackValue(WalletType.software);
    registerFallbackValue(SoftwareViewWallet(0, '_fallback', _debugAddress) as AWallet);
    registerFallbackValue(Uint8List(0));
  });

  setUp(() {
    repo = _MockWalletRepository();
    settings = _MockSettingsRepository();
    bitbox = _MockBitboxService();
    bitboxManager = _MockBitboxManager();
    appStore = _MockAppStore();
    secureStorage = _MockSecureStorage();
    service = WalletService(bitbox, repo, settings, appStore, secureStorage);
    isolate = FakeWalletIsolate();
    service.debugInjectWalletIsolate(isolate);

    when(() => settings.saveCurrentWalletId(any())).thenAnswer((_) async => true);
    when(() => settings.removeCurrentWalletId()).thenAnswer((_) async => true);
    when(() => repo.deleteWallet(any())).thenAnswer((_) async => (accountRows: 0, walletRows: 1));
    when(() => repo.isLastWallet()).thenAnswer((_) async => false);
    when(() => repo.updateAddress(any(), any())).thenAnswer((_) async {});
    when(() => settings.deleteMnemonicKeyOnLastWalletDelete).thenReturn(false);
    when(() => secureStorage.deleteMnemonicEncryptionKey()).thenAnswer((_) async {});
    when(() => secureStorage.getOrCreateMnemonicKey()).thenAnswer((_) async => _testKeyBytes);
    when(() => bitbox.bitboxManager).thenReturn(bitboxManager);
    when(() => bitbox.getCredentials(any())).thenReturn(BitboxCredentials(_debugAddress));
  });

  group('$WalletService', () {
    group('generateUncommittedSeedDraft', () {
      test('returns a SeedDraft with a valid bip39 mnemonic and the given name', () async {
        final draft = await service.generateUncommittedSeedDraft('Main');

        expect(draft, isA<SeedDraft>());
        expect(draft.name, 'Main');
        expect(service.validateSeed(draft.mnemonic), isTrue);
        expect(draft.isDisposed, isFalse);
      });

      test('does NOT write to the repository — the encrypted seed must not land on disk', () async {
        await service.generateUncommittedSeedDraft('Main');

        // Pin the disk-side guarantee: nothing flows into `walletInfos`
        // until a separate `commitGeneratedWallet` call. Without this,
        // every `_dropMnemonic` regenerate in `CreateWalletCubit`
        // would persist a fresh encrypted-seed row.
        verifyNever(() => repo.createWallet(any(), any(), any(), any()));
        verifyNever(() => settings.saveCurrentWalletId(any()));
      });

      test(
        'two consecutive calls produce distinct mnemonics (entropy not pinned by the API)',
        () async {
          final a = await service.generateUncommittedSeedDraft('Main');
          final b = await service.generateUncommittedSeedDraft('Main');

          expect(
            a.mnemonic,
            isNot(equals(b.mnemonic)),
            reason:
                'each call must produce a fresh mnemonic — pinning entropy '
                'would silently break the "regenerate on hidden" contract',
          );
        },
      );
    });

    group('commitGeneratedWallet', () {
      test('persists the draft seed via the isolate, returns a SoftwareWallet handle, '
          'and disposes the draft', () async {
        when(() => repo.createWallet(any(), any(), any(), any())).thenAnswer((_) async => 42);
        const fakeAddress = '0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266';
        isolate.defaultAddress = fakeAddress;

        final draft = SeedDraft(_testMnemonic, name: 'Main');
        final committed = await service.commitGeneratedWallet(draft);

        expect(committed.id, 42);
        expect(committed.name, 'Main');
        expect(committed.address, fakeAddress);
        expect(
          draft.isDisposed,
          isTrue,
          reason:
              'BL-018: the draft must be disposed after commit so the '
              'mnemonic is no longer reachable through the cubit-side holder',
        );
        verify(() => repo.createWallet('Main', WalletType.software, _testMnemonic, '')).called(1);
        verify(() => repo.updateAddress(42, fakeAddress)).called(1);
        expect(
          isolate.adoptCallCount,
          1,
          reason: 'the plaintext must cross into the isolate exactly once',
        );
      });

      test('throws when called on a disposed draft', () async {
        final draft = SeedDraft(_testMnemonic);
        draft.dispose();

        expect(
          () => service.commitGeneratedWallet(draft),
          throwsA(isA<StateError>()),
        );
      });

      test('does not set the wallet as current (caller is responsible)', () async {
        when(() => repo.createWallet(any(), any(), any(), any())).thenAnswer((_) async => 7);

        final draft = SeedDraft(_testMnemonic, name: 'Main');
        await service.commitGeneratedWallet(draft);

        verifyNever(() => settings.saveCurrentWalletId(any()));
      });
    });

    group('restoreWallet', () {
      test('persists the provided seed via the isolate and marks it current', () async {
        when(() => repo.createWallet(any(), any(), any(), any())).thenAnswer((_) async => 7);

        final wallet = await service.restoreWallet('Restored', _testMnemonic);

        expect(wallet.id, 7);
        expect(wallet.name, 'Restored');
        verify(
          () => repo.createWallet('Restored', WalletType.software, _testMnemonic, ''),
        ).called(1);
        verify(() => settings.saveCurrentWalletId(7)).called(1);
        expect(isolate.adoptCallCount, 1);
      });
    });

    group('createDebugWallet', () {
      test('persists a view wallet and marks it current', () async {
        when(() => repo.createViewWallet(any(), any(), any())).thenAnswer((_) async => 99);

        final wallet = await service.createDebugWallet(_debugAddress);

        expect(wallet, isA<DebugWallet>());
        expect(wallet.id, 99);
        expect(wallet.address, _debugAddress);
        verify(() => repo.createViewWallet('Debug', WalletType.debug, _debugAddress)).called(1);
        verify(() => settings.saveCurrentWalletId(99)).called(1);
      });
    });

    group('createBitboxWallet', () {
      test('persists the BitBox address as a view wallet and marks it current', () async {
        when(
          () => bitboxManager.getETHAddress(any(), any()),
        ).thenAnswer((_) async => _debugAddress);
        when(() => repo.createViewWallet(any(), any(), any())).thenAnswer((_) async => 77);

        final wallet = await service.createBitboxWallet('Hardware');

        expect(wallet, isA<BitboxWallet>());
        expect(wallet.id, 77);
        verify(() => bitboxManager.getETHAddress(1, "m/44'/60'/0'/0/0")).called(1);
        verify(() => repo.createViewWallet('Hardware', WalletType.bitbox, _debugAddress)).called(1);
        verify(() => settings.saveCurrentWalletId(77)).called(1);
      });
    });

    group('getWalletById', () {
      test('returns SoftwareViewWallet (address only) for cached-address software rows', () async {
        when(() => repo.getWalletInfo(1)).thenAnswer(
          (_) async => _info(
            id: 1,
            name: 'Main',
            address: _debugAddress,
            type: WalletType.software,
          ),
        );

        final wallet = await service.getWalletById(1);

        expect(wallet, isA<SoftwareViewWallet>());
      });

      test('returns DebugWallet for debug type', () async {
        when(() => repo.getWalletInfo(2)).thenAnswer(
          (_) async => _info(id: 2, name: 'Debug', address: _debugAddress, type: WalletType.debug),
        );

        final wallet = await service.getWalletById(2);

        expect(wallet, isA<DebugWallet>());
        expect((wallet as DebugWallet).address, _debugAddress);
      });

      test('promotes legacy software rows with empty cached address', () async {
        when(() => repo.getWalletInfo(3)).thenAnswer(
          (_) async => _info(
            id: 3,
            name: 'Legacy',
            seed: '<encrypted-blob>',
            address: '',
            type: WalletType.software,
          ),
        );
        isolate.defaultAddress = _debugAddress;

        final wallet = await service.getWalletById(3);

        // The backfill only needs the address: it returns a view wallet and
        // drops the seed from the isolate (no lingering, uncapped mnemonic).
        expect(wallet, isA<SoftwareViewWallet>());
        verify(() => repo.updateAddress(3, _debugAddress)).called(1);
        expect(
          isolate.slots.containsKey(3),
          isFalse,
          reason: '#609 F2: legacy backfill must not leave the seed resident',
        );
      });

      test('returns BitboxWallet for BitBox rows', () async {
        when(() => repo.getWalletInfo(4)).thenAnswer(
          (_) async => _info(id: 4, name: 'BBox', address: _debugAddress, type: WalletType.bitbox),
        );

        final wallet = await service.getWalletById(4);

        expect(wallet, isA<BitboxWallet>());
        verify(() => bitbox.getCredentials(_debugAddress)).called(1);
      });

      test('throws when the repository returns null (no such id)', () async {
        when(() => repo.getWalletInfo(404)).thenAnswer((_) async => null);

        expect(() => service.getWalletById(404), throwsA(isA<TypeError>()));
      });
    });

    group('unlockWalletById', () {
      test('returns a SoftwareWallet handle and seats the isolate slot', () async {
        when(() => repo.getWalletInfo(1)).thenAnswer(
          (_) async => _info(
            id: 1,
            name: 'Main',
            seed: '<encrypted-blob>',
            address: _debugAddress,
            type: WalletType.software,
          ),
        );

        final wallet = await service.unlockWalletById(1);

        expect(wallet, isA<SoftwareWallet>());
        expect(wallet.id, 1);
        expect(
          isolate.unlockCallCount,
          1,
          reason: 'unlock must round-trip the ciphertext + key into the isolate',
        );
        expect(isolate.slots.containsKey(1), isTrue);
      });

      test('throws for non-software wallet types', () async {
        when(() => repo.getWalletInfo(2)).thenAnswer(
          (_) async => _info(id: 2, name: 'BBox', address: _debugAddress, type: WalletType.bitbox),
        );

        expect(() => service.unlockWalletById(2), throwsA(isA<StateError>()));
      });
    });

    group('revealCurrentSeed', () {
      test('returns a SeedDraft with the isolate-side mnemonic', () async {
        when(() => settings.currentWalletId).thenReturn(1);
        when(() => repo.getWalletInfo(1)).thenAnswer(
          (_) async => _info(
            id: 1,
            name: 'Main',
            address: _debugAddress,
            type: WalletType.software,
          ),
        );
        // Seed the isolate slot directly so reveal has something to
        // return — production flow does this via `unlockWalletById`.
        await isolate.adoptPlaintext(1, _testMnemonic);

        final draft = await service.revealCurrentSeed();

        expect(draft.mnemonic, _testMnemonic);
        expect(draft.name, 'Main');
        expect(
          draft.isDisposed,
          isFalse,
          reason:
              'reveal returns an undisposed draft — the caller is '
              'responsible for dispose() after rendering',
        );
      });
    });

    group('setCurrentWallet', () {
      test('delegates to SettingsRepository.saveCurrentWalletId', () async {
        await service.setCurrentWallet(5);

        verify(() => settings.saveCurrentWalletId(5)).called(1);
      });
    });

    group('current wallet helpers', () {
      test('getCurrentWallet resolves the id from settings', () async {
        when(() => settings.currentWalletId).thenReturn(2);
        when(() => repo.getWalletInfo(2)).thenAnswer(
          (_) async => _info(id: 2, name: 'Debug', address: _debugAddress, type: WalletType.debug),
        );

        final wallet = await service.getCurrentWallet();

        expect(wallet, isA<DebugWallet>());
        verify(() => repo.getWalletInfo(2)).called(1);
      });

      test('unlockCurrentWallet resolves the id from settings', () async {
        when(() => settings.currentWalletId).thenReturn(5);
        when(() => repo.getWalletInfo(5)).thenAnswer(
          (_) async => _info(
            id: 5,
            name: 'Main',
            seed: '<encrypted-blob>',
            address: _debugAddress,
            type: WalletType.software,
          ),
        );

        final wallet = await service.unlockCurrentWallet();

        expect(wallet, isA<SoftwareWallet>());
        expect(wallet.id, 5);
      });
    });

    group('hasWallet', () {
      test('returns true when a current id is set', () {
        when(() => settings.currentWalletId).thenReturn(1);

        expect(service.hasWallet(), isTrue);
      });

      test('returns false when no current id is set', () {
        when(() => settings.currentWalletId).thenReturn(null);

        expect(service.hasWallet(), isFalse);
      });
    });

    group('validateSeed', () {
      test('accepts a valid bip39 mnemonic', () {
        expect(service.validateSeed(_testMnemonic), isTrue);
      });

      test('rejects an obviously invalid mnemonic', () {
        expect(service.validateSeed('not a valid seed phrase at all'), isFalse);
      });

      test('rejects an empty string', () {
        expect(service.validateSeed(''), isFalse);
      });

      test('rejects a mnemonic with a wrong checksum word', () {
        const broken = 'test test test test test test test test test test test ability';
        expect(service.validateSeed(broken), isFalse);
      });
    });

    group('ensureCurrentWalletUnlocked', () {
      test('promotes a SoftwareViewWallet to a SoftwareWallet via the isolate', () async {
        final view = SoftwareViewWallet(7, 'Main', _debugAddress);
        final stored = <AWallet>[view];
        when(() => appStore.wallet).thenAnswer((_) => stored.last);
        when(() => appStore.wallet = any(that: isA<AWallet>())).thenAnswer((inv) {
          final newWallet = inv.positionalArguments.single as AWallet;
          stored.add(newWallet);
          return newWallet;
        });
        when(() => settings.currentWalletId).thenReturn(7);
        when(() => repo.getWalletInfo(7)).thenAnswer(
          (_) async => _info(
            id: 7,
            name: 'Main',
            seed: '<enc>',
            address: _debugAddress,
            type: WalletType.software,
          ),
        );

        await service.ensureCurrentWalletUnlocked();

        expect(stored.last, isA<SoftwareWallet>());
        expect(isolate.unlockCallCount, 1);
      });

      test('post-unlock timer force-locks the wallet after the safety cap', () {
        fakeAsync((async) {
          final stored = <AWallet>[SoftwareViewWallet(7, 'Main', _debugAddress)];
          when(() => appStore.wallet).thenAnswer((_) => stored.last);
          when(() => appStore.wallet = any(that: isA<AWallet>())).thenAnswer((inv) {
            final newWallet = inv.positionalArguments.single as AWallet;
            stored.add(newWallet);
            return newWallet;
          });
          when(() => settings.currentWalletId).thenReturn(7);
          when(() => repo.getWalletInfo(7)).thenAnswer(
            (_) async => _info(
              id: 7,
              name: 'Main',
              seed: '<enc>',
              address: _debugAddress,
              type: WalletType.software,
            ),
          );

          var completed = false;
          service.ensureCurrentWalletUnlocked().then((_) => completed = true);
          async.flushMicrotasks();

          expect(completed, isTrue);
          expect(stored.last, isA<SoftwareWallet>());
          isolate.lockCallCount = 0;

          async.elapse(const Duration(seconds: 59));
          async.flushMicrotasks();
          expect(isolate.lockCallCount, 0);
          expect(stored.last, isA<SoftwareWallet>());

          async.elapse(const Duration(seconds: 2));
          async.flushMicrotasks();

          expect(isolate.lockCallCount, 1);
          expect(stored.last, isA<SoftwareViewWallet>());
        });
      });

      test('is a no-op when the current wallet is not a SoftwareViewWallet', () async {
        final unlocked = SoftwareWallet(7, 'Main', _debugAddress, isolate);
        when(() => appStore.wallet).thenReturn(unlocked);

        await service.ensureCurrentWalletUnlocked();

        expect(
          isolate.unlockCallCount,
          0,
          reason: 'no view-wallet to promote — the isolate must not be touched',
        );
      });
    });

    group('lockCurrentWallet', () {
      setUp(() {
        when(() => appStore.isWalletLoaded).thenReturn(true);
      });

      test('replaces an unlocked SoftwareWallet with its SoftwareViewWallet counterpart '
          'and locks the isolate slot', () async {
        final unlocked = SoftwareWallet(9, 'Main', _debugAddress, isolate);
        AWallet? written;
        when(() => appStore.wallet).thenReturn(unlocked);
        when(() => appStore.wallet = any(that: isA<AWallet>())).thenAnswer((inv) {
          final newWallet = inv.positionalArguments.single as AWallet;
          written = newWallet;
          return newWallet;
        });
        // Seed a slot so we can verify the lock drops it.
        await isolate.adoptPlaintext(9, _testMnemonic);
        isolate.lockCallCount = 0;

        await service.lockCurrentWallet();

        expect(written, isA<SoftwareViewWallet>());
        expect(written!.id, 9);
        expect(written!.name, 'Main');
        expect(
          isolate.lockCallCount,
          1,
          reason:
              'BL-022: lock must propagate to the isolate so the '
              'decrypted slot is released, not just to the AppStore',
        );
        expect(isolate.slots.containsKey(9), isFalse);
      });

      test('is a no-op when the wallet is already locked / not software', () async {
        when(() => appStore.wallet).thenReturn(
          SoftwareViewWallet(9, 'Main', _debugAddress),
        );

        await service.lockCurrentWallet();

        verifyNever(() => appStore.wallet = any(that: isA<AWallet>()));
        expect(
          isolate.lockCallCount,
          0,
          reason: 'a view wallet has no isolate slot — lock must skip the IPC',
        );
      });

      test('is a no-op when no wallet has been loaded yet', () async {
        when(() => appStore.isWalletLoaded).thenReturn(false);

        await service.lockCurrentWallet();

        verifyNever(() => appStore.wallet);
        verifyNever(() => appStore.wallet = any(that: isA<AWallet>()));
        expect(isolate.lockCallCount, 0);
      });
    });

    group('lock cancels in-flight decrypt (BL-022)', () {
      // BL-022: pre-Initiative-IV `lockCurrentWallet` called
      // `_unlockInFlight?.ignore()` which detached the future but did
      // NOT cancel the underlying isolate work. Post-Initiative-IV
      // the isolate slot is dropped via `lock()` so the decrypted
      // seed is released even if the awaiting future is never
      // observed.
      setUp(() {
        when(() => appStore.isWalletLoaded).thenReturn(true);
      });

      test('lock during a single in-flight unlock locks the isolate slot afterwards', () async {
        final stored = <AWallet>[SoftwareViewWallet(7, 'Main', _debugAddress)];
        when(() => appStore.wallet).thenAnswer((_) => stored.last);
        when(() => appStore.wallet = any(that: isA<AWallet>())).thenAnswer((inv) {
          final newWallet = inv.positionalArguments.single as AWallet;
          stored.add(newWallet);
          return newWallet;
        });
        when(() => settings.currentWalletId).thenReturn(7);

        final gate = Completer<WalletInfo>();
        when(() => repo.getWalletInfo(7)).thenAnswer((_) => gate.future);

        final ensure = service.ensureCurrentWalletUnlocked();
        await service.lockCurrentWallet();

        gate.complete(
          _info(
            id: 7,
            name: 'Main',
            seed: '<enc>',
            address: _debugAddress,
            type: WalletType.software,
          ),
        );
        await ensure;

        // After the chained lock + ensure resolves, the AppStore must
        // still be on the view wallet — the in-flight unlock must
        // not resurface the mnemonic. The new mechanism is the
        // isolate-side slot drop AND the main-side _unlockInFlight
        // gate; both must hold.
        expect(
          stored.last,
          isA<SoftwareViewWallet>(),
          reason:
              'BL-022: in-flight unlock invalidated by intervening '
              'lock must not resurface the mnemonic in AppStore',
        );
        verifyNever(() => appStore.wallet = any(that: isA<SoftwareWallet>()));
        // #609 F1: the isolate slot the in-flight unlock seated must be
        // dropped — the decrypted seed must not stay pinned after the lock.
        await Future<void>.delayed(Duration.zero);
        expect(
          isolate.slots.containsKey(7),
          isFalse,
          reason: 'in-flight unlock must not leave the seed pinned in the isolate',
        );
      });
    });

    group('deleteCurrentWallet', () {
      test('deletes the wallet and clears the current-id setting', () async {
        when(() => settings.currentWalletId).thenReturn(8);

        final result = await service.deleteCurrentWallet();

        verify(() => repo.deleteWallet(8)).called(1);
        verify(() => settings.removeCurrentWalletId()).called(1);
        expect(
          result.walletRows,
          1,
          reason:
              'BL-004: the walletInfos row count must be surfaced so '
              'the cleanup chain can be audited end-to-end',
        );
      });

      test('drops the isolate slot before deleting the row', () async {
        when(() => settings.currentWalletId).thenReturn(8);
        await isolate.adoptPlaintext(8, _testMnemonic);
        isolate.lockCallCount = 0;

        await service.deleteCurrentWallet();

        expect(
          isolate.lockCallCount,
          1,
          reason:
              'the decrypted seed (if any) must be released before '
              'the row goes — defensive against an unlocked-without-lock '
              'cycle leaving a stale slot',
        );
        expect(isolate.slots.containsKey(8), isFalse);
      });

      test('does NOT touch the mnemonic encryption key when the opt-in is off', () async {
        when(() => settings.currentWalletId).thenReturn(8);
        when(() => repo.isLastWallet()).thenAnswer((_) async => true);
        when(() => settings.deleteMnemonicKeyOnLastWalletDelete).thenReturn(false);

        final result = await service.deleteCurrentWallet();

        verifyNever(() => secureStorage.deleteMnemonicEncryptionKey());
        expect(result.mnemonicKeyDeleted, isFalse);
      });

      test('does NOT touch the mnemonic encryption key when other wallets remain', () async {
        when(() => settings.currentWalletId).thenReturn(8);
        when(() => repo.isLastWallet()).thenAnswer((_) async => false);
        when(() => settings.deleteMnemonicKeyOnLastWalletDelete).thenReturn(true);

        final result = await service.deleteCurrentWallet();

        verifyNever(() => secureStorage.deleteMnemonicEncryptionKey());
        expect(
          result.mnemonicKeyDeleted,
          isFalse,
          reason:
              'opt-in flag fires only on last-wallet-delete — the '
              'key must survive while other encrypted seeds still need it',
        );
      });

      test('wipes the mnemonic encryption key on a last-wallet-delete when opted in', () async {
        when(() => settings.currentWalletId).thenReturn(8);
        when(() => repo.isLastWallet()).thenAnswer((_) async => true);
        when(() => settings.deleteMnemonicKeyOnLastWalletDelete).thenReturn(true);

        final result = await service.deleteCurrentWallet();

        verify(() => secureStorage.deleteMnemonicEncryptionKey()).called(1);
        expect(result.mnemonicKeyDeleted, isTrue);
      });
    });

    group('persistence failure resilience', () {
      test('commitGeneratedWallet propagates repository exception', () async {
        when(() => repo.createWallet(any(), any(), any(), any())).thenThrow(Exception('disk full'));

        final draft = SeedDraft(_testMnemonic, name: 'Main');

        expect(
          () => service.commitGeneratedWallet(draft),
          throwsA(isA<Exception>()),
        );
        verifyNever(() => settings.saveCurrentWalletId(any()));
      });

      test('restoreWallet propagates repository exception without setting current', () async {
        when(() => repo.createWallet(any(), any(), any(), any())).thenThrow(Exception('disk full'));

        expect(
          () => service.restoreWallet('Restored', _testMnemonic),
          throwsA(isA<Exception>()),
        );
        verifyNever(() => settings.saveCurrentWalletId(any()));
      });
    });
  });
}
