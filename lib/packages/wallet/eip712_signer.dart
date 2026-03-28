import 'dart:convert';

import 'package:eth_sig_util_plus/eth_sig_util_plus.dart';
import 'package:realunit_wallet/packages/hardware_wallet/bitbox_credentials.dart';
import 'package:realunit_wallet/packages/service/dfx/models/payment/sell/dto/eip7702/eip7702_data_dto.dart';
import 'package:web3dart/crypto.dart';
import 'package:web3dart/web3dart.dart';

class Eip712Signer {
  static Future<String> signRegistration({
    required CredentialsWithKnownAddress credentials,
    required String email,
    required String name,
    required String type,
    required String phoneNumber,
    required String birthday,
    required String nationality,
    required String addressStreet,
    required String addressPostalCode,
    required String addressCity,
    required String addressCountry,
    required bool swissTaxResidence,
    required String registrationDate,
  }) async {
    final Map<String, dynamic> typedDataMap = {
      'types': {
        'EIP712Domain': [
          {'name': 'name', 'type': 'string'},
          {'name': 'version', 'type': 'string'},
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
          {'name': 'walletAddress', 'type': 'address'},
        ],
      },
      'primaryType': 'RealUnitUser',
      'domain': {'name': 'RealUnitUser', 'version': '1'},
      'message': {
        'email': email,
        'name': name,
        'type': type,
        'phoneNumber': phoneNumber,
        'birthday': birthday,
        'nationality': nationality,
        'addressStreet': addressStreet,
        'addressPostalCode': addressPostalCode,
        'addressCity': addressCity,
        'addressCountry': addressCountry,
        'swissTaxResidence': swissTaxResidence,
        'registrationDate': registrationDate,
        'walletAddress': credentials.address.hexEip55,
      },
    };

    final jsonData = jsonEncode(typedDataMap);

    if (credentials is BitboxCredentials) {
      return credentials.signTypedDataV4(1, jsonData);
    }

    return EthSigUtil.signTypedData(
      privateKey: bytesToHex((credentials as EthPrivateKey).privateKey, include0x: true),
      jsonData: jsonData,
      version: TypedDataVersion.V4,
    );
  }

  static Future<String> signDelegation({
    required CredentialsWithKnownAddress credentials,
    required Eip7702Data eip7702Data,
  }) async {
    final Map<String, dynamic> typedDataMap = {
      'types': {
        'EIP712Domain': [
          {'name': 'name', 'type': 'string'},
          {'name': 'version', 'type': 'string'},
          {'name': 'chainId', 'type': 'uint256'},
          {'name': 'verifyingContract', 'type': 'address'},
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
      },
    };

    final jsonData = jsonEncode(typedDataMap);

    if (credentials is BitboxCredentials) {
      return credentials.signTypedDataV4(eip7702Data.domain.chainId, jsonData);
    }

    return EthSigUtil.signTypedData(
      privateKey: bytesToHex((credentials as EthPrivateKey).privateKey, include0x: true),
      jsonData: jsonData,
      version: TypedDataVersion.V4,
    );
  }
}
