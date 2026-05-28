import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:realunit_wallet/packages/hardware_wallet/bitbox.dart';
import 'package:realunit_wallet/packages/hardware_wallet/bitbox_credentials.dart';
import 'package:realunit_wallet/packages/wallet/wallet.dart';
import 'package:realunit_wallet/packages/wallet/wallet_account.dart';
import 'package:realunit_wallet/packages/wallet/wallet_isolate.dart';

class _MockBitboxService extends Mock implements BitboxService {}

const _primaryAddress = '0x0000000000000000000000000000000000000001';
const _secondaryAddress = '0x0000000000000000000000000000000000000002';

class _FakeWalletIsolate extends WalletIsolate {
  _FakeWalletIsolate() : super.forTesting();

  int? lastWalletId;
  String? lastDerivationPath;
  Uint8List? lastPayload;
  int? lastChainId;

  @override
  Future<({BigInt r, BigInt s, int v})> signDigest(
    int walletId,
    String derivationPath,
    Uint8List digest, {
    int? chainId,
  }) async {
    lastWalletId = walletId;
    lastDerivationPath = derivationPath;
    lastPayload = digest;
    lastChainId = chainId;
    return (r: BigInt.one, s: BigInt.two, v: 27);
  }

  @override
  Future<Uint8List> signPersonalMessage(
    int walletId,
    String derivationPath,
    Uint8List payload, {
    int? chainId,
  }) async {
    lastWalletId = walletId;
    lastDerivationPath = derivationPath;
    lastPayload = payload;
    lastChainId = chainId;
    return Uint8List.fromList([0x00, 0x01, 0x02, 0xff]);
  }
}

SoftwareWallet _softwareWallet({
  int id = 1,
  String name = 'Main',
  String address = _primaryAddress,
}) => SoftwareWallet(id, name, address, _FakeWalletIsolate());

// Why every sign path on a SoftwareViewWallet throws an Error subtype: in
// debug builds the assert(false) fires first and surfaces as an
// AssertionError; in release the assert is stripped and the StateError
// wins. Both are Error subtypes, which is the contract — _not_ a typed
// Exception that callers would catch and route.
const _viewWalletErrorRationale =
    'assert(false) in debug → AssertionError, StateError in release — both Error subtypes';

void main() {
  group('$SeedDraft', () {
    test('throws if the mnemonic is read after dispose', () {
      final draft = SeedDraft('test test junk');

      draft.dispose();

      expect(draft.isDisposed, isTrue);
      expect(
        () => draft.mnemonic,
        throwsA(isA<StateError>()),
      );
      expect(() => draft.dispose(), returnsNormally);
    });

    test('seedWords trims repeated whitespace before disposal', () {
      final draft = SeedDraft('  test   test\njunk  ');

      expect(draft.mnemonic, '  test   test\njunk  ');
      expect(draft.seedWords, ['test', 'test', 'junk']);
    });
  });

  group('$SoftwareWallet', () {
    test('exposes walletType == software', () {
      final wallet = _softwareWallet();

      expect(wallet.walletType, WalletType.software);
    });

    test('primaryAccount is derived at BIP-44 account index 0', () {
      final wallet = _softwareWallet();

      expect(wallet.primaryAccount, isA<WalletAccount>());
      expect(wallet.primaryAccount.accountIndex, 0);
    });

    test('currentAccount starts equal to primaryAccount', () {
      final wallet = _softwareWallet();

      expect(
        wallet.currentAccount.primaryAddress.address.hex,
        wallet.primaryAccount.primaryAddress.address.hex,
      );
    });

    test('selectAccount switches currentAccount to a different derivation', () {
      final wallet = _softwareWallet();
      final firstAddress = wallet.currentAccount.primaryAddress.address.hex;

      wallet.selectAccount(1, _secondaryAddress);

      expect(wallet.currentAccount.accountIndex, 1);
      expect(
        wallet.currentAccount.primaryAddress.address.hex,
        isNot(firstAddress),
      );
    });

    test('selectAccount does not alter primaryAccount', () {
      final wallet = _softwareWallet();
      final primary = wallet.primaryAccount.primaryAddress.address.hex;

      wallet.selectAccount(2, _secondaryAddress);

      expect(wallet.primaryAccount.primaryAddress.address.hex, primary);
    });

    test('id and name are preserved from the constructor', () {
      final wallet = _softwareWallet(id: 42, name: 'Savings');

      expect(wallet.id, 42);
      expect(wallet.name, 'Savings');
    });

    test('name field is mutable (set after construction)', () {
      final wallet = _softwareWallet(name: 'Old');

      wallet.name = 'New';

      expect(wallet.name, 'New');
    });

    test(
      'isolate credentials signToSignature delegates digest signing with the account path',
      () async {
        final isolate = _FakeWalletIsolate();
        final wallet = SoftwareWallet(7, 'Main', _primaryAddress, isolate);
        final digest = Uint8List.fromList([0xaa, 0xbb]);

        final signature = await wallet.primaryAccount.primaryAddress.signToSignature(
          digest,
          chainId: 11,
        );

        expect(signature.r, BigInt.one);
        expect(signature.s, BigInt.two);
        expect(signature.v, 27);
        expect(isolate.lastWalletId, 7);
        expect(isolate.lastDerivationPath, "m/44'/60'/0'/0/0");
        expect(isolate.lastPayload, digest);
        expect(isolate.lastChainId, 11);
      },
    );

    test(
      'isolate credentials signPersonalMessage delegates through the selected account path',
      () async {
        final isolate = _FakeWalletIsolate();
        final wallet = SoftwareWallet(7, 'Main', _primaryAddress, isolate);
        final payload = Uint8List.fromList([0x01, 0x02, 0x03]);

        wallet.selectAccount(2, _secondaryAddress);
        final signature = await wallet.currentAccount.primaryAddress.signPersonalMessage(
          payload,
          chainId: 1,
        );

        expect(signature, [0x00, 0x01, 0x02, 0xff]);
        expect(isolate.lastWalletId, 7);
        expect(isolate.lastDerivationPath, "m/44'/60'/2'/0/0");
        expect(isolate.lastPayload, payload);
        expect(isolate.lastChainId, 1);
      },
    );

    test('WalletAccount.signMessage UTF-8 encodes and hex-encodes isolate signatures', () async {
      final isolate = _FakeWalletIsolate();
      final wallet = SoftwareWallet(7, 'Main', _primaryAddress, isolate);

      final signature = await wallet.primaryAccount.signMessage(
        'Gruezi',
        addressIndex: 3,
      );

      expect(signature, '0x000102ff');
      expect(isolate.lastWalletId, 7);
      expect(isolate.lastDerivationPath, "m/44'/60'/0'/0/3");
      expect(isolate.lastPayload, utf8.encode('Gruezi'));
    });

    test('sync isolate credential entrypoints reject async-only signing', () {
      final wallet = _softwareWallet();

      expect(
        () => wallet.primaryAccount.primaryAddress.signToEcSignature(Uint8List(32)),
        throwsA(isA<UnsupportedError>()),
      );
      expect(
        () => wallet.primaryAccount.primaryAddress.signPersonalMessageToUint8List(
          Uint8List(32),
        ),
        throwsA(isA<UnsupportedError>()),
      );
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
}
