import 'dart:convert';

import 'package:eth_sig_util_plus/eth_sig_util_plus.dart';
import 'package:realunit_wallet/packages/service/dfx/models/payment/sell/dto/eip7702/eip7702_data_dto.dart';
import 'package:realunit_wallet/packages/service/dfx/models/registration/registration.dart';
import 'package:web3dart/crypto.dart';
import 'package:web3dart/web3dart.dart';

class Eip712Signer {
  static String signRegistration({
    required CredentialsWithKnownAddress credentials,
    required Registration registration,
  }) {
    if (credentials is! EthPrivateKey) {
      throw Exception('Hardware wallets not supported for EIP-712 registration signing');
    }

    final Map<String, dynamic> typedDataMap = {
      'types': {
        'EIP712Domain': [
          {'name': 'name', 'type': 'string'},
          {'name': 'version', 'type': 'string'}
        ],
        'RealUnitUser': [
          {'name': 'email', 'type': 'string'},
          {'name': 'name', 'type': 'string'},
          {'name': 'type', 'type': 'string'},
          {'name': 'phoneNumber', 'type': 'string'},
          {'name': 'birthday', 'type': 'string'},
          {'name': 'nationality', 'type': 'string'},
          {'name': 'addressStreet', 'type': 'string'},
          {'name': 'addressPostalCode', 'type': 'string'},
          {'name': 'addressCity', 'type': 'string'},
          {'name': 'addressCountry', 'type': 'string'},
          {'name': 'swissTaxResidence', 'type': 'bool'},
          {'name': 'registrationDate', 'type': 'string'},
          {'name': 'walletAddress', 'type': 'address'}
        ]
      },
      'primaryType': 'RealUnitUser',
      'domain': {'name': 'RealUnitUser', 'version': '1'},
      'message': {
        'email': registration.email,
        'name': '${registration.firstName} ${registration.lastName}',
        'type': registration.type.jsonName,
        'phoneNumber': registration.phoneNumber,
        'birthday': registration.birthday,
        'nationality': registration.nationality.symbol,
        'addressStreet': registration.addressStreet,
        'addressPostalCode': registration.addressPostalCode,
        'addressCity': registration.addressCity,
        'addressCountry': registration.addressCountry.symbol,
        'swissTaxResidence': true,
        'registrationDate': registration.registrationDate,
        'walletAddress': credentials.address.hexEip55,
      }
    };

    return EthSigUtil.signTypedData(
      privateKey: bytesToHex(credentials.privateKey, include0x: true),
      jsonData: jsonEncode(typedDataMap),
      version: TypedDataVersion.V4,
    );
  }

  static String signDelegation({
    required CredentialsWithKnownAddress credentials,
    required Eip7702Data eip7702Data,
  }) {
    if (credentials is! EthPrivateKey) {
      throw Exception('Hardware wallets not supported for EIP-712 delegation signing');
    }

    final Map<String, dynamic> typedDataMap = {
      'types': {
        'EIP712Domain': [
          {'name': 'name', 'type': 'string'},
          {'name': 'version', 'type': 'string'},
          {'name': 'chainId', 'type': 'uint256'},
          {'name': 'verifyingContract', 'type': 'address'}
        ],
        'Delegation': eip7702Data.types.delegation
            .map((field) => {'name': field.name, 'type': field.type})
            .toList(),
        'Caveat': eip7702Data.types.caveat
            .map((field) => {'name': field.name, 'type': field.type})
            .toList(),
      },
      'primaryType': 'Delegation',
      'domain': {
        'name': eip7702Data.domain.name,
        'version': eip7702Data.domain.version,
        'chainId': eip7702Data.domain.chainId,
        'verifyingContract': eip7702Data.domain.verifyingContract,
      },
      'message': {
        'delegate': eip7702Data.message.delegate,
        'delegator': eip7702Data.message.delegator,
        'authority': eip7702Data.message.authority,
        'caveats': eip7702Data.message.caveats,
        'salt': eip7702Data.message.salt,
      }
    };

    final signature = EthSigUtil.signTypedData(
      privateKey: bytesToHex(credentials.privateKey, include0x: true),
      jsonData: jsonEncode(typedDataMap),
      version: TypedDataVersion.V4,
    );
    return signature;
  }
}
