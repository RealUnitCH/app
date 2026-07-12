import 'dart:typed_data';

import 'package:bip32/bip32.dart';
import 'package:bip39/bip39.dart' as bip39;
import 'package:bitbox_flutter/bitbox_manager.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:realunit_wallet/packages/hardware_wallet/bitbox_credentials.dart';
import 'package:realunit_wallet/packages/wallet/wallet_account.dart';

class _MockBitboxManager extends Mock implements BitboxManager {}

const _testMnemonic = 'test test test test test test test test test test test junk';

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

    test('signMessage with non-ASCII characters succeeds (regression for #289)', () async {
      final account = WalletAccount(_testRoot(), 0);

      final sig = await account.signMessage('Grüße 🚀');

      expect(sig, startsWith('0x'));
      expect(sig.length, 132);
    });
  });

  group('$BitboxWalletAccount', () {
    // BitboxWalletAccount.signMessage is the single method the subclass adds
    // on top of AWalletAccount — it forwards utf8-encoded bytes through the
    // BitBox credentials and hex-encodes the result. The native sign call is
    // mocked at the BitboxManager boundary so the test stays unit-level and
    // does not require a real device.
    const address = '0x000000000000000000000000000000000000dead';
    late _MockBitboxManager manager;

    setUpAll(() {
      registerFallbackValue(Uint8List(0));
    });

    setUp(() {
      manager = _MockBitboxManager();
    });

    BitboxWalletAccount account() => BitboxWalletAccount(
      0,
      BitboxCredentials(address)..setBitbox(manager),
    );

    test('signMessage hex-encodes the bytes returned by the BitBox manager', () async {
      when(
        () => manager.signETHMessage(any(), any(), any()),
      ).thenAnswer((_) async => Uint8List.fromList([0xCA, 0xFE, 0xBA, 0xBE]));

      final signature = await account().signMessage('hello');

      expect(signature, '0xcafebabe');
    });

    test('signMessage forwards utf8-encoded message bytes to the BitBox manager', () async {
      Uint8List? capturedPayload;
      when(() => manager.signETHMessage(any(), any(), any())).thenAnswer((invocation) async {
        capturedPayload = invocation.positionalArguments[2] as Uint8List;
        return Uint8List.fromList([0x00]);
      });

      await account().signMessage('Grüße 🚀');

      // utf8 round-trip: the native call must see the same bytes the rest
      // of the app would compute via utf8.encode — verifies the encoding
      // boundary that #289 regressed on.
      expect(
        capturedPayload,
        Uint8List.fromList([
          0x47,
          0x72,
          0xc3,
          0xbc,
          0xc3,
          0x9f,
          0x65,
          0x20,
          0xf0,
          0x9f,
          0x9a,
          0x80,
        ]),
      );
    });
  });
}
