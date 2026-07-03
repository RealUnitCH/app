import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:realunit_wallet/packages/hardware_wallet/bitbox_credentials.dart';
import 'package:realunit_wallet/packages/service/dfx/models/payment/sell/dto/eip7702/eip7702_data_dto.dart';
import 'package:realunit_wallet/packages/wallet/eip7702_signer.dart';
import 'package:web3dart/web3dart.dart';

class _MockBitboxCredentials extends Mock implements BitboxCredentials {}

const _delegatorAddress = '0x0000000000000000000000000000000000000001';

Eip7702Data _data({int chainId = 1, int userNonce = 0}) => Eip7702Data(
      relayerAddress: '0x0000000000000000000000000000000000000002',
      delegationManagerAddress: '0x0000000000000000000000000000000000000003',
      delegatorAddress: _delegatorAddress,
      userNonce: BigInt.from(userNonce),
      domain: Eip7702Domain(
        name: 'RealUnit',
        version: '1',
        chainId: chainId,
        verifyingContract: '0x0000000000000000000000000000000000000004',
      ),
      types: const Eip7702Types(delegation: [], caveat: []),
      message: Eip7702Message(
        delegate: '0x0000000000000000000000000000000000000005',
        delegator: _delegatorAddress,
        authority: '0x0000000000000000000000000000000000000006',
        caveats: [],
        salt: BigInt.zero,
      ),
      tokenAddress: '0x0000000000000000000000000000000000000007',
      amountWei: '0',
      depositAddress: '0x0000000000000000000000000000000000000008',
    );

void main() {
  group('$Eip7702Signer', () {
    test('throws when credentials are not an EthPrivateKey', () {
      // BitBox02 firmware does not expose a raw EIP-7702 signing API,
      // so any hardware-wallet credential must be rejected up front.
      final credentials = _MockBitboxCredentials();
      when(() => credentials.address).thenReturn(
        EthereumAddress.fromHex(_delegatorAddress),
      );

      expect(
        () => Eip7702Signer.signAuthorization(
          credentials: credentials,
          eip7702Data: _data(),
        ),
        throwsA(isA<Exception>()),
      );
    });

    test('returns a signature for a software EthPrivateKey credential', () {
      final credentials = EthPrivateKey.fromHex(
        'fb1ace12f9801e85f3db1b3935dd47d9f064f98152466f47c701b5e12680e612',
      );

      final signature = Eip7702Signer.signAuthorization(
        credentials: credentials,
        eip7702Data: _data(),
      );

      expect(signature, isNotNull);
    });

    test('produces a deterministic signature for identical inputs', () {
      final credentials = EthPrivateKey.fromHex(
        'fb1ace12f9801e85f3db1b3935dd47d9f064f98152466f47c701b5e12680e612',
      );
      final data = _data(chainId: 1, userNonce: 7);

      final first = Eip7702Signer.signAuthorization(
        credentials: credentials,
        eip7702Data: data,
      );
      final second = Eip7702Signer.signAuthorization(
        credentials: credentials,
        eip7702Data: data,
      );

      expect(first.r, second.r);
      expect(first.s, second.s);
      expect(first.v, second.v);
    });

    test('different nonces produce different signatures', () {
      final credentials = EthPrivateKey.fromHex(
        'fb1ace12f9801e85f3db1b3935dd47d9f064f98152466f47c701b5e12680e612',
      );

      final a = Eip7702Signer.signAuthorization(
        credentials: credentials,
        eip7702Data: _data(userNonce: 0),
      );
      final b = Eip7702Signer.signAuthorization(
        credentials: credentials,
        eip7702Data: _data(userNonce: 1),
      );

      expect(a.r == b.r && a.s == b.s, isFalse);
    });
  });
}
