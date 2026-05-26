// Tier-0 tests for the surviving `AWalletAccount` abstraction post
// Initiative IV. The legacy main-isolate `WalletAccount` (which held
// a BIP32 root locally) is gone — its replacement lives in
// `lib/packages/wallet/wallet.dart` and runs every sign through the
// dedicated `WalletIsolate`. The end-to-end behaviour of the new
// account is covered by `wallet_isolate_test.dart`; this file pins
// the format of `getDerivationPath` so a refactor of the base class
// cannot quietly break the BIP-44 path convention.

import 'dart:typed_data';

import 'package:bitbox_flutter/bitbox_manager.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:realunit_wallet/packages/hardware_wallet/bitbox_credentials.dart';
import 'package:realunit_wallet/packages/wallet/wallet_account.dart';
import 'package:web3dart/credentials.dart';
import 'package:web3dart/crypto.dart';

class _MockBitboxManager extends Mock implements BitboxManager {}

class _StubCredentials extends CredentialsWithKnownAddress {
  _StubCredentials(this._address);
  final EthereumAddress _address;

  @override
  EthereumAddress get address => _address;

  @override
  MsgSignature signToEcSignature(Uint8List payload, {int? chainId, bool isEIP1559 = false}) =>
      throw UnimplementedError('stub');

  @override
  Future<MsgSignature> signToSignature(Uint8List payload, {int? chainId, bool isEIP1559 = false}) =>
      throw UnimplementedError('stub');
}

class _StubAccount extends AWalletAccount {
  _StubAccount(super.accountIndex, super.primaryAddress);

  @override
  Future<String> signMessage(String message, {int addressIndex = 0}) async =>
      throw UnimplementedError('stub — not exercised in this test');
}

void main() {
  final stubAddress =
      _StubCredentials(EthereumAddress.fromHex('0x0000000000000000000000000000000000000001'));

  group('$AWalletAccount.getDerivationPath', () {
    test('uses the BIP-44 Ethereum format with account index zero', () {
      final account = _StubAccount(0, stubAddress);

      expect(account.getDerivationPath(0), "m/44'/60'/0'/0/0");
      expect(account.getDerivationPath(5), "m/44'/60'/0'/0/5");
    });

    test('threads the account index through the third path segment', () {
      final account = _StubAccount(3, stubAddress);

      expect(account.getDerivationPath(0), "m/44'/60'/3'/0/0");
      expect(account.getDerivationPath(2), "m/44'/60'/3'/0/2");
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
