import 'dart:convert' show utf8;

import 'package:convert/convert.dart';
import 'package:web3dart/web3dart.dart';

abstract class AWalletAccount {
  final int accountIndex;
  final CredentialsWithKnownAddress primaryAddress;

  AWalletAccount(this.accountIndex, this.primaryAddress);

  String getDerivationPath(int addressIndex) => "m/44'/60'/$accountIndex'/0/$addressIndex";

  Future<String> signMessage(String message, {int addressIndex = 0});
}

class BitboxWalletAccount extends AWalletAccount {
  BitboxWalletAccount(super.accountIndex, super.primaryAddress);

  @override
  Future<String> signMessage(String message, {int addressIndex = 0}) async =>
      '0x${hex.encode(await primaryAddress.signPersonalMessage(utf8.encode(message)))}';
}
