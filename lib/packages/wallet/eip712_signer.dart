import 'dart:convert';

import 'package:eth_sig_util_plus/eth_sig_util_plus.dart';
import 'package:realunit_wallet/packages/service/dfx/models/registration/dfx_registration.dart';
import 'package:web3dart/crypto.dart';
import 'package:web3dart/web3dart.dart';

class EIP712Signer {
  static String signRegistration({
    required CredentialsWithKnownAddress credentials,
    required DfxRegistration registration,
  }) {
    if (credentials is! EthPrivateKey) {
      throw Exception('Hardware wallets not supported for registration signing');
    }

    final Map<String, dynamic> typedDataMap = {
      "types": {
        "EIP712Domain": [
          {"name": "name", "type": "string"},
          {"name": "version", "type": "string"}
        ],
        "RealUnitUser": [
          {"name": "email", "type": "string"},
          {"name": "name", "type": "string"},
          {"name": "type", "type": "string"},
          {"name": "phoneNumber", "type": 'string'},
          {"name": "birthday", "type": "string"},
          {"name": "nationality", "type": "string"},
          {"name": "addressStreet", "type": "string"},
          {"name": "addressPostalCode", "type": "string"},
          {"name": "addressCity", "type": "string"},
          {"name": "addressCountry", "type": "string"},
          {"name": "swissTaxResidence", "type": "bool"},
          {"name": "registrationDate", "type": "string"},
          {"name": "walletAddress", "type": "address"}
        ]
      },
      "primaryType": "RealUnitUser",
      "domain": {"name": "RealUnitUser", "version": "1"},
      "message": {
        "email": registration.email,
        "name": "${registration.firstName} ${registration.lastName}",
        "type": "HUMAN",
        "phoneNumber": registration.phoneNumber,
        "birthday": registration.birthday,
        "nationality": registration.nationality,
        "addressStreet": registration.addressStreet,
        "addressPostalCode": registration.addressPostalCode,
        "addressCity": registration.addressCity,
        "addressCountry": registration.addressCountry,
        "swissTaxResidence": true,
        "registrationDate": registration.registrationDate,
        "walletAddress": credentials.address.hexEip55,
      }
    };

    return EthSigUtil.signTypedData(
      privateKey: bytesToHex(credentials.privateKey, include0x: true),
      jsonData: jsonEncode(typedDataMap),
      version: TypedDataVersion.V4,
    );
  }
}
