import 'package:eip7702/eip7702.dart' as eip7702;
import 'package:realunit_wallet/packages/service/dfx/models/payment/sell/dto/eip7702/eip7702_data_dto.dart';
import 'package:web3dart/web3dart.dart';

class Eip7702Signer {
  static eip7702.EIP7702MsgSignature signAuthorization({
    required CredentialsWithKnownAddress credentials,
    required Eip7702Data eip7702Data,
  }) {
    if (credentials is! EthPrivateKey) {
      throw Exception(
        'Hardware wallets not supported for EIP-7702 authorization signing. '
        'BitBox02 firmware does not expose a raw EIP-7702 signing API.',
      );
    }

    final eip7702.UnsignedAuthorization unsignedAuth = (
      chainId: BigInt.from(eip7702Data.domain.chainId),
      delegateAddress: eip7702Data.delegatorAddress,
      nonce: eip7702Data.userNonce,
    );
    final signer = eip7702.Signer.eth(credentials);
    final authTuple = eip7702.signAuthorization(signer, unsignedAuth);

    return authTuple.signature;
  }
}
