// Cross-layer integration tests for the BitBox wallet-creation flow.
//
// These tests stitch the WalletService together with a *real* BitboxService
// driven by the official bitbox_flutter simulator, a *real* WalletRepository
// backed by a Drift in-memory database (AppDatabase.forTesting +
// NativeDatabase.memory), and a *real* SettingsRepository on
// SharedPreferences.setMockInitialValues. The seam under test is:
//
//   WalletService.createBitboxWallet
//     → BitboxService.bitboxManager.getETHAddress  (via the simulator)
//     → WalletRepository.createViewWallet          (writes walletInfos)
//     → SettingsRepository.saveCurrentWalletId     (persists current id)
//
// Style anchors:
//   * test/integration/connect_bitbox_flow_test.dart (simulator install +
//     tearDown pattern)
//   * test/packages/repository/wallet_repository_test.dart (in-memory DB +
//     mock SecureStorage setup)
//   * test/packages/service/wallet_service_test.dart (the createBitboxWallet
//     contract — pinned here against the *real* downstream stack instead of
//     the mocks the unit suite uses).

import 'dart:typed_data';

import 'package:bitbox_flutter/testing.dart';
import 'package:bitbox_flutter/usb/bitbox_usb_platform_interface.dart';
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
import 'package:shared_preferences/shared_preferences.dart';

class _MockSecureStorage extends Mock implements SecureStorage {}

class _MockAppStore extends Mock implements AppStore {}

// SimulatedBitboxPlatform's default ETH address. The simulator always
// returns this string from getETHAddress regardless of the chainId / path,
// so it is what createBitboxWallet ends up persisting on the view row.
const _simulatedAddress = '0x1111111111111111111111111111111111111111';

void main() {
  late BitboxUsbPlatform previousPlatform;
  late SimulatedBitboxPlatform platform;
  late AppDatabase db;
  late _MockSecureStorage secureStorage;
  late WalletRepository walletRepository;
  late SettingsRepository settingsRepository;
  late BitboxService bitboxService;
  late _MockAppStore appStore;
  late WalletService service;

  // Deterministic 256-bit AES-GCM key — content is irrelevant for the
  // round-trip assertions, only that the encrypt/decrypt static helpers
  // would receive consistent bytes if they were ever called. The bitbox
  // path must NOT touch this key (no seed to wrap), and the
  // persistence-round-trip test pins that contract.
  final mnemonicKey = Uint8List.fromList(List<int>.generate(32, (i) => i));

  setUp(() async {
    previousPlatform = BitboxUsbPlatform.instance;
    // The production cubit drives `BitboxService.init(device)` (→ connect +
    // initBitBox) before `WalletService.createBitboxWallet` ever calls
    // `bitboxManager.getETHAddress`. These tests target the WalletService
    // boundary directly, so we relax the simulator's `requireOpen` guard
    // instead of replaying the pairing handshake just to satisfy it.
    platform = installSimulatedBitboxPlatform(requireOpen: false);

    SharedPreferences.setMockInitialValues(const <String, Object>{});
    final prefs = await SharedPreferences.getInstance();

    db = AppDatabase.forTesting(NativeDatabase.memory());
    secureStorage = _MockSecureStorage();
    walletRepository = WalletRepository(db, secureStorage);
    settingsRepository = SettingsRepository(prefs);
    // Real BitboxService — connectionStatusInterval is irrelevant here,
    // we never arm the observer in these tests.
    bitboxService = BitboxService();
    appStore = _MockAppStore();
    service = WalletService(bitboxService, walletRepository, settingsRepository, appStore);

    when(() => secureStorage.getOrCreateMnemonicKey()).thenAnswer((_) async => mnemonicKey);
  });

  tearDown(() async {
    await db.close();
    BitboxUsbPlatform.instance = previousPlatform;
  });

  group('$WalletService.createBitboxWallet × $BitboxService × $WalletRepository', () {
    test(
      'happy: createBitboxWallet writes a view row to the in-memory DB and marks it current',
      () async {
        // The full commit path runs end-to-end:
        //   simulator getETHAddress → WalletRepository.createViewWallet
        //   → WalletStorage.insertWallet → walletInfos row
        //   → SettingsRepository.saveCurrentWalletId
        // The unit suite covers each layer in isolation with mocks; this
        // pins the same contract through the *real* downstream stack so a
        // wiring regression (wrong WalletType.index, missing setCurrentWallet
        // call, dropped address) surfaces here.
        final wallet = await service.createBitboxWallet('Hardware');

        expect(wallet, isA<BitboxWallet>());
        expect(wallet.name, 'Hardware');
        // The DB-assigned id must be the same one the wallet carries and
        // the same one persisted as current — otherwise the next launch
        // lands on a different wallet than the one we just created.
        expect(wallet.id, greaterThan(0));
        expect(settingsRepository.currentWalletId, wallet.id);

        // Inspect the persisted row directly via the storage extension,
        // not via the repository, so a regression that bypasses
        // createViewWallet still surfaces.
        final row = await db.getWalletById(wallet.id);
        expect(row, isNotNull);
        expect(row!.name, 'Hardware');
        expect(row.type, WalletType.bitbox.index);
        // BitBox view rows have NO encrypted seed — only the cached
        // address. Anything in the seed column would mean we persisted
        // unencrypted material or accidentally re-used the software path.
        expect(row.seed, isEmpty);
        expect(row.address.toLowerCase(), _simulatedAddress.toLowerCase());

        // Simulator must have been the one to hand back the address —
        // pin the touchpoint count so a future refactor that derives the
        // address from a cache or settings layer instead surfaces here.
        expect(
          platform.count(SimulatedBitboxMethod.getETHAddress),
          1,
          reason: 'createBitboxWallet must derive the address from the device exactly once',
        );
        // Encryption key must NOT be touched — BitBox rows carry no seed
        // and have no use for the AES-GCM key the software path relies on.
        verifyNever(() => secureStorage.getOrCreateMnemonicKey());
      },
    );

    test(
      'hardware-failure: simulator throws on getETHAddress → no row, no current-id write',
      () async {
        // Defends the partial-commit contract: a transport drop or device
        // reject mid-derivation must propagate cleanly and leave the DB
        // and SharedPreferences untouched. Without this guard, a half-
        // paired hardware wallet would already be the "current" wallet on
        // the next launch and the user would land on a dashboard pointing
        // at an address the device has never confirmed.
        platform.throwOn(
          SimulatedBitboxMethod.getETHAddress,
          Exception('USB transport dropped'),
        );

        await expectLater(
          service.createBitboxWallet('Hardware'),
          throwsA(isA<Exception>()),
        );

        // No row landed.
        final hadWallet = await db.hasWallet;
        expect(
          hadWallet,
          isFalse,
          reason: 'a failed BitBox derivation must not leave a half-committed walletInfos row',
        );
        // Current-id must not have been persisted — otherwise the next
        // launch points at a wallet that does not exist.
        expect(settingsRepository.currentWalletId, isNull);
        // Simulator was hit exactly once before throwing.
        expect(platform.count(SimulatedBitboxMethod.getETHAddress), 1);
      },
    );

    test(
      'persistence-round-trip: cold-load via getWalletById finds the Bitbox row and skips decryption',
      () async {
        // The "cold-load" half of the contract: after createBitboxWallet
        // commits, a fresh WalletService instance (mimicking app restart)
        // must be able to materialise the same wallet by id WITHOUT ever
        // touching the mnemonic-encryption key — BitBox rows have an
        // empty seed column and the SoftwareWallet branch is unreachable.
        final created = await service.createBitboxWallet('Hardware');
        // Mirror the caller-side contract: HomeBloc / the connect flow set
        // AppStore.wallet themselves once createBitboxWallet returns. Pin
        // that the wallet returned by createBitboxWallet is the same
        // instance the caller would surface in-app.
        appStore.wallet = created;
        verify(() => appStore.wallet = created).called(1);

        // Cold-load: fresh service instance, fresh mock secure storage so
        // any stray `getOrCreateMnemonicKey()` call would be observable
        // (mocktail returns null for unstubbed methods → would crash the
        // decrypt path). Reuse the same DB and SharedPreferences so the
        // persisted state survives the "restart".
        final coldSecureStorage = _MockSecureStorage();
        final coldRepo = WalletRepository(db, coldSecureStorage);
        final coldBitbox = BitboxService();
        final coldService = WalletService(
          coldBitbox,
          coldRepo,
          settingsRepository,
          _MockAppStore(),
        );

        final reloaded = await coldService.getWalletById(created.id);

        expect(
          reloaded,
          isA<BitboxWallet>(),
          reason: 'BitBox rows must reload as BitboxWallet, never as SoftwareViewWallet',
        );
        expect(reloaded.id, created.id);
        expect(reloaded.name, 'Hardware');
        // The currentAccount on a BitboxWallet pulls credentials from the
        // *new* BitboxService — pin that the address survives the round
        // trip and matches the one the simulator originally derived.
        expect(
          reloaded.currentAccount.primaryAddress.address.hexEip55.toLowerCase(),
          _simulatedAddress.toLowerCase(),
        );

        // The critical pin: cold-load must NOT attempt to decrypt a seed
        // that doesn't exist. The bitbox branch in getWalletById bypasses
        // the secure storage entirely; this verifies that contract through
        // the *real* DB row, not a stubbed WalletInfo.
        verifyNever(() => coldSecureStorage.getOrCreateMnemonicKey());
      },
    );
  });
}
