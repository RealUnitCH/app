import 'package:flutter_test/flutter_test.dart';
import 'package:realunit_wallet/packages/wallet/wallet.dart';
import 'package:realunit_wallet/packages/wallet/wallet_account.dart';

const _testMnemonic =
    'test test test test test test test test test test test junk';

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
}
