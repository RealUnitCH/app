// Post-Initiative-IV tests for the handle-shaped `SoftwareWallet` +
// the supporting `SoftwareViewWallet` / `DebugWallet` / `SeedDraft`.
// The `SoftwareWallet` constructor now takes a `WalletIsolate`; we
// spawn a real one per group so the round-trip tests exercise the
// production IPC path (no mocks above Tier 0 for this kind of
// cryptographic boundary).

import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:realunit_wallet/packages/hardware_wallet/bitbox.dart';
import 'package:realunit_wallet/packages/hardware_wallet/bitbox_credentials.dart';
import 'package:realunit_wallet/packages/wallet/wallet.dart';
import 'package:realunit_wallet/packages/wallet/wallet_account.dart';
import 'package:realunit_wallet/packages/wallet/wallet_isolate.dart';

class _MockBitboxService extends Mock implements BitboxService {}

const _testMnemonic = 'test test test test test test test test test test test junk';

// Why every sign path on a SoftwareViewWallet throws an Error subtype: in
// debug builds the assert(false) fires first and surfaces as an
// AssertionError; in release the assert is stripped and the StateError
// wins. Both are Error subtypes, which is the contract — _not_ a typed
// Exception that callers would catch and route.
const _viewWalletErrorRationale =
    'assert(false) in debug → AssertionError, StateError in release — both Error subtypes';

void main() {
  group('$SoftwareWallet (handle)', () {
    late WalletIsolate isolate;
    late String primaryAddress;

    setUp(() async {
      isolate = await WalletIsolate.spawn();
      primaryAddress = await isolate.adoptPlaintext(1, _testMnemonic);
    });

    tearDown(() async {
      await isolate.dispose();
    });

    test('exposes walletType == software', () {
      final wallet = SoftwareWallet(1, 'Main', primaryAddress, isolate);

      expect(wallet.walletType, WalletType.software);
    });

    test('primaryAccount carries account index 0', () {
      final wallet = SoftwareWallet(1, 'Main', primaryAddress, isolate);

      expect(wallet.primaryAccount.accountIndex, 0);
    });

    test('currentAccount starts equal to primaryAccount', () {
      final wallet = SoftwareWallet(1, 'Main', primaryAddress, isolate);

      expect(
        wallet.currentAccount.primaryAddress.address.hex,
        wallet.primaryAccount.primaryAddress.address.hex,
      );
    });

    test('primaryAddress matches the isolate-derived EIP-55 address', () {
      final wallet = SoftwareWallet(1, 'Main', primaryAddress, isolate);

      // The first test-mnemonic Ethereum address is the well-known
      // Hardhat / Foundry account #0.
      const expected = '0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266';
      expect(wallet.primaryAccount.primaryAddress.address.hexEip55, expected);
    });

    test('selectAccount switches currentAccount to a different derivation', () async {
      final wallet = SoftwareWallet(1, 'Main', primaryAddress, isolate);
      final addressAtOne = await isolate.deriveAddress(1, 1, 0);

      wallet.selectAccount(1, addressAtOne);

      expect(wallet.currentAccount.accountIndex, 1);
      expect(
        wallet.currentAccount.primaryAddress.address.hexEip55,
        isNot(primaryAddress),
      );
    });

    test('selectAccount does not alter primaryAccount', () async {
      final wallet = SoftwareWallet(1, 'Main', primaryAddress, isolate);
      final addressAtTwo = await isolate.deriveAddress(1, 2, 0);

      wallet.selectAccount(2, addressAtTwo);

      expect(
        wallet.primaryAccount.primaryAddress.address.hexEip55,
        primaryAddress,
      );
    });

    test('id and name are preserved from the constructor', () {
      final wallet = SoftwareWallet(42, 'Savings', primaryAddress, isolate);

      expect(wallet.id, 42);
      expect(wallet.name, 'Savings');
    });

    test('name field is mutable (set after construction)', () {
      final wallet = SoftwareWallet(1, 'Old', primaryAddress, isolate);

      wallet.name = 'New';

      expect(wallet.name, 'New');
    });

    test('signMessage runs through the isolate and returns a 65-byte hex', () async {
      final wallet = SoftwareWallet(1, 'Main', primaryAddress, isolate);

      final signature = await wallet.currentAccount.signMessage('hello');

      // 0x prefix + 65 bytes * 2 hex chars = 132 chars.
      expect(signature, startsWith('0x'));
      expect(signature.length, 132);
    });
  });

  group('$DebugWallet', () {
    const address = '0x0000000000000000000000000000000000000001';

    test('exposes walletType == debug', () {
      final wallet = DebugWallet(1, 'Debug', address);

      expect(wallet.walletType, WalletType.debug);
    });

    test('primaryAccount equals currentAccount', () {
      final wallet = DebugWallet(1, 'Debug', address);

      expect(identical(wallet.primaryAccount, wallet.currentAccount), isTrue);
    });

    test('exposes the configured address through primaryAccount', () {
      final wallet = DebugWallet(1, 'Debug', address);

      expect(
        wallet.primaryAccount.primaryAddress.address.hex.toLowerCase(),
        address.toLowerCase(),
      );
    });

    test('signMessage throws UnsupportedError', () async {
      final wallet = DebugWallet(1, 'Debug', address);

      expect(
        () => wallet.primaryAccount.signMessage('payload'),
        throwsA(isA<UnsupportedError>()),
      );
    });

    // The DebugWallet's credentials must reject every sign path with a typed
    // UnsupportedError — surfaces a regression where a future refactor wires
    // the debug-view wallet onto a real signing backend. The four entry
    // points (signToEcSignature, signToSignature, signPersonalMessage,
    // signPersonalMessageToUint8List) cover the synchronous AND the async
    // variants the web3dart `Credentials` interface exposes.
    test('credentials.signToEcSignature throws UnsupportedError', () {
      final wallet = DebugWallet(1, 'Debug', address);

      expect(
        () => wallet.primaryAccount.primaryAddress.signToEcSignature(Uint8List(0)),
        throwsA(isA<UnsupportedError>()),
      );
    });

    test('credentials.signToSignature throws UnsupportedError', () {
      final wallet = DebugWallet(1, 'Debug', address);

      expect(
        () => wallet.primaryAccount.primaryAddress.signToSignature(Uint8List(0)),
        throwsA(isA<UnsupportedError>()),
      );
    });

    test('credentials.signPersonalMessage throws UnsupportedError', () {
      final wallet = DebugWallet(1, 'Debug', address);

      expect(
        () => wallet.primaryAccount.primaryAddress.signPersonalMessage(Uint8List(0)),
        throwsA(isA<UnsupportedError>()),
      );
    });

    test('credentials.signPersonalMessageToUint8List throws UnsupportedError', () {
      final wallet = DebugWallet(1, 'Debug', address);

      expect(
        () => wallet.primaryAccount.primaryAddress.signPersonalMessageToUint8List(Uint8List(0)),
        throwsA(isA<UnsupportedError>()),
      );
    });

    test('credentials expose the configured address through the credentials interface', () {
      final wallet = DebugWallet(1, 'Debug', address);

      expect(
        wallet.primaryAccount.primaryAddress.address.hex.toLowerCase(),
        address.toLowerCase(),
        reason:
            'the address must round-trip through CredentialsWithKnownAddress '
            'so downstream consumers (e.g. UI / tx-history) read the same value',
      );
    });

    test('id and name are preserved from the constructor', () {
      final wallet = DebugWallet(7, 'Debug-7', address);

      expect(wallet.id, 7);
      expect(wallet.name, 'Debug-7');
      expect(wallet.address, address);
    });
  });

  group('$BitboxWallet', () {
    // Wires BitboxService into the wallet without actually talking to USB / BLE.
    // The credentials object is just a typed handle stored on the account —
    // the actual native sign call happens inside BitboxCredentials.signPersonalMessage
    // which is exercised by the bitbox_credentials suite.
    const address = '0x0000000000000000000000000000000000000002';
    late _MockBitboxService bitboxService;

    setUp(() {
      bitboxService = _MockBitboxService();
      when(() => bitboxService.getCredentials(any())).thenReturn(BitboxCredentials(address));
    });

    test('exposes walletType == bitbox', () {
      final wallet = BitboxWallet(1, 'Hardware', address, bitboxService);

      expect(wallet.walletType, WalletType.bitbox);
    });

    test('primaryAccount is a BitboxWalletAccount derived at account index 0', () {
      final wallet = BitboxWallet(1, 'Hardware', address, bitboxService);

      expect(wallet.primaryAccount, isA<BitboxWalletAccount>());
      expect(wallet.primaryAccount.accountIndex, 0);
    });

    test('currentAccount starts equal to primaryAccount', () {
      final wallet = BitboxWallet(1, 'Hardware', address, bitboxService);

      expect(identical(wallet.primaryAccount, wallet.currentAccount), isTrue);
    });

    test('forwards the address through BitboxService.getCredentials', () {
      BitboxWallet(1, 'Hardware', address, bitboxService);

      // The constructor must hand the raw address to the service so the
      // service's lowercase-keyed cache hits regardless of EIP-55 casing.
      verify(() => bitboxService.getCredentials(address)).called(1);
    });

    test('id and name are preserved from the constructor', () {
      final wallet = BitboxWallet(42, 'Treasury', address, bitboxService);

      expect(wallet.id, 42);
      expect(wallet.name, 'Treasury');
    });

    test('credentials carry the configured address', () {
      final wallet = BitboxWallet(1, 'Hardware', address, bitboxService);

      expect(
        wallet.primaryAccount.primaryAddress.address.hex.toLowerCase(),
        address.toLowerCase(),
      );
    });
  });

  group('$SoftwareViewWallet', () {
    // Programmer-error tests: any sign path that bypassed
    // WalletService.ensureCurrentWalletUnlocked() must surface loudly, not
    // silently return a wrong-type result. In release builds the assert is
    // stripped and the StateError still fires.
    const address = '0x0000000000000000000000000000000000000001';

    test('exposes walletType == software', () {
      final wallet = SoftwareViewWallet(1, 'Main', address);

      expect(wallet.walletType, WalletType.software);
    });

    test('primaryAccount == currentAccount, both view-wallet specialisations', () {
      final wallet = SoftwareViewWallet(1, 'Main', address);

      expect(identical(wallet.primaryAccount, wallet.currentAccount), isTrue);
      expect(wallet.primaryAccount, isA<SoftwareViewWalletAccount>());
    });

    test('primaryAccount.primaryAddress.address resolves the cached EIP-55 hex', () {
      final wallet = SoftwareViewWallet(1, 'Main', address);

      expect(wallet.primaryAccount.primaryAddress.address.hex.toLowerCase(), address);
    });

    test('primaryAccount.signMessage throws StateError instead of signing', () {
      final wallet = SoftwareViewWallet(1, 'Main', address);

      expect(
        () => wallet.primaryAccount.signMessage('payload'),
        throwsA(isA<Error>()),
        reason: _viewWalletErrorRationale,
      );
    });

    test('credentials.signToSignature throws StateError', () {
      final wallet = SoftwareViewWallet(1, 'Main', address);

      expect(
        () => wallet.primaryAccount.primaryAddress.signToSignature(Uint8List(0)),
        throwsA(isA<Error>()), // see _viewWalletErrorRationale
      );
    });

    test('credentials.signPersonalMessage throws StateError', () {
      final wallet = SoftwareViewWallet(1, 'Main', address);

      expect(
        () => wallet.primaryAccount.primaryAddress.signPersonalMessage(Uint8List(0)),
        throwsA(isA<Error>()), // see _viewWalletErrorRationale
      );
    });

    test('credentials.signPersonalMessageToUint8List throws StateError', () {
      final wallet = SoftwareViewWallet(1, 'Main', address);

      expect(
        () => wallet.primaryAccount.primaryAddress.signPersonalMessageToUint8List(Uint8List(0)),
        throwsA(isA<Error>()), // see _viewWalletErrorRationale
      );
    });

    test('credentials.signToEcSignature throws StateError', () {
      final wallet = SoftwareViewWallet(1, 'Main', address);

      expect(
        () => wallet.primaryAccount.primaryAddress.signToEcSignature(Uint8List(0)),
        throwsA(isA<Error>()), // see _viewWalletErrorRationale
      );
    });
  });

  group('$SeedDraft', () {
    test('exposes the mnemonic and its split-words form', () {
      final draft = SeedDraft(_testMnemonic, name: 'Onboarding');

      expect(draft.mnemonic, _testMnemonic);
      expect(draft.seedWords, hasLength(12));
      expect(draft.name, 'Onboarding');
      expect(draft.isDisposed, isFalse);
    });

    test('dispose() overwrites the mnemonic and flips isDisposed', () {
      final draft = SeedDraft(_testMnemonic);
      expect(draft.isDisposed, isFalse);

      draft.dispose();

      expect(draft.isDisposed, isTrue);
      expect(
        () => draft.mnemonic,
        throwsA(isA<StateError>()),
        reason:
            'post-dispose reads must throw — silently returning the '
            'space-filled placeholder would let the UI render a fake seed',
      );
    });

    test('dispose() is idempotent', () {
      final draft = SeedDraft(_testMnemonic);
      draft.dispose();

      expect(() => draft.dispose(), returnsNormally);
      expect(draft.isDisposed, isTrue);
    });
  });
}
