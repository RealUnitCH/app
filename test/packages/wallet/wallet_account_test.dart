import 'package:bip32/bip32.dart';
import 'package:bip39/bip39.dart' as bip39;
import 'package:flutter_test/flutter_test.dart';
import 'package:realunit_wallet/packages/wallet/wallet_account.dart';

const _testMnemonic =
    'test test test test test test test test test test test junk';

BIP32 _testRoot() => BIP32.fromSeed(bip39.mnemonicToSeed(_testMnemonic));

void main() {
  group('$WalletAccount', () {
    test('getDerivationPath uses the BIP-44 Ethereum format', () {
      final account = WalletAccount(_testRoot(), 0);

      expect(account.getDerivationPath(0), "m/44'/60'/0'/0/0");
      expect(account.getDerivationPath(5), "m/44'/60'/0'/0/5");
    });

    test('derivation path includes the account index', () {
      final account = WalletAccount(_testRoot(), 3);

      expect(account.getDerivationPath(0), "m/44'/60'/3'/0/0");
    });

    test('primaryAddress is derived deterministically from the seed', () {
      // The first test-mnemonic Ethereum address is the well-known
      // Hardhat / Foundry account #0.
      const expected = '0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266';

      final account = WalletAccount(_testRoot(), 0);

      expect(
        account.primaryAddress.address.hexEip55,
        expected,
      );
    });

    test('different account indices derive different addresses', () {
      final a = WalletAccount(_testRoot(), 0).primaryAddress.address.hex;
      final b = WalletAccount(_testRoot(), 1).primaryAddress.address.hex;

      expect(a, isNot(b));
    });

    test('signMessage produces a 65-byte hex signature', () async {
      final account = WalletAccount(_testRoot(), 0);

      final signature = await account.signMessage('hello');

      // 0x prefix + 65 bytes * 2 hex chars = 132 chars.
      expect(signature, startsWith('0x'));
      expect(signature.length, 132);
    });

    test('signMessage is deterministic for the same input', () async {
      final account = WalletAccount(_testRoot(), 0);

      final first = await account.signMessage('payload');
      final second = await account.signMessage('payload');

      expect(first, second);
    });

    test('signMessage with a different addressIndex yields a different signature', () async {
      final account = WalletAccount(_testRoot(), 0);

      final fromZero = await account.signMessage('payload', addressIndex: 0);
      final fromOne = await account.signMessage('payload', addressIndex: 1);

      expect(fromZero, isNot(fromOne));
    });
  });
}
