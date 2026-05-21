import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:realunit_wallet/packages/wallet/wallet.dart';
import 'package:realunit_wallet/packages/wallet/wallet_account.dart';

const _testMnemonic =
    'test test test test test test test test test test test junk';

// Why every sign path on a SoftwareViewWallet throws an Error subtype: in
// debug builds the assert(false) fires first and surfaces as an
// AssertionError; in release the assert is stripped and the StateError
// wins. Both are Error subtypes, which is the contract — _not_ a typed
// Exception that callers would catch and route.
const _viewWalletErrorRationale =
    'assert(false) in debug → AssertionError, StateError in release — both Error subtypes';

void main() {
  group('$SoftwareWallet', () {
    test('exposes walletType == software', () {
      final wallet = SoftwareWallet(1, 'Main', _testMnemonic);

      expect(wallet.walletType, WalletType.software);
    });

    test('primaryAccount is derived at BIP-44 account index 0', () {
      final wallet = SoftwareWallet(1, 'Main', _testMnemonic);

      expect(wallet.primaryAccount, isA<WalletAccount>());
      expect(wallet.primaryAccount.accountIndex, 0);
    });

    test('currentAccount starts equal to primaryAccount', () {
      final wallet = SoftwareWallet(1, 'Main', _testMnemonic);

      expect(
        wallet.currentAccount.primaryAddress.address.hex,
        wallet.primaryAccount.primaryAddress.address.hex,
      );
    });

    test('selectAccount switches currentAccount to a different derivation', () {
      final wallet = SoftwareWallet(1, 'Main', _testMnemonic);
      final firstAddress = wallet.currentAccount.primaryAddress.address.hex;

      wallet.selectAccount(1);

      expect(wallet.currentAccount.accountIndex, 1);
      expect(
        wallet.currentAccount.primaryAddress.address.hex,
        isNot(firstAddress),
      );
    });

    test('selectAccount does not alter primaryAccount', () {
      final wallet = SoftwareWallet(1, 'Main', _testMnemonic);
      final primary = wallet.primaryAccount.primaryAddress.address.hex;

      wallet.selectAccount(2);

      expect(wallet.primaryAccount.primaryAddress.address.hex, primary);
    });

    test('id and name are preserved from the constructor', () {
      final wallet = SoftwareWallet(42, 'Savings', _testMnemonic);

      expect(wallet.id, 42);
      expect(wallet.name, 'Savings');
    });

    test('name field is mutable (set after construction)', () {
      final wallet = SoftwareWallet(1, 'Old', _testMnemonic);

      wallet.name = 'New';

      expect(wallet.name, 'New');
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
}
