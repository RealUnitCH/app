import 'dart:convert';

import 'package:eth_sig_util_plus/eth_sig_util_plus.dart';
import 'package:web3dart/crypto.dart';
import 'package:web3dart/web3dart.dart';

class EIP712Signer {
  static String signRegistration({
    required EthPrivateKey privateKey,
    required String email,
    required String name,
    required String phoneNumber,
    required String birthday,
    required String nationality,
    required String addressStreet,
    required String addressPostalCode,
    required String addressCity,
    required String addressCountry,
    required bool swissTaxResidence,
    required String registrationDate,
    required String walletAddress,
  }) {
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
        "email": email,
        "name": name,
        "type": "HUMAN",
        "phoneNumber": phoneNumber,
        "birthday": birthday,
        "nationality": nationality,
        "addressStreet": addressStreet,
        "addressPostalCode": addressPostalCode,
        "addressCity": addressCity,
        "addressCountry": addressCountry,
        "swissTaxResidence": true,
        "registrationDate": registrationDate,
        "walletAddress": walletAddress
      }
    };

    return EthSigUtil.signTypedData(
      privateKey: bytesToHex(privateKey.privateKey, include0x: true),
      jsonData: jsonEncode(typedDataMap),
      version: TypedDataVersion.V4,
    );
  }
}
