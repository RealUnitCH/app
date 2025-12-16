import 'dart:convert';

import 'package:bip32/bip32.dart';
import 'package:convert/convert.dart';
import 'package:web3dart/web3dart.dart';

abstract class AWalletAccount {
  final int accountIndex;
  final CredentialsWithKnownAddress primaryAddress;

  AWalletAccount(this.accountIndex, this.primaryAddress);

  String getDerivationPath(int addressIndex) =>
      "m/44'/60'/$accountIndex'/0/$addressIndex";

  Future<String> signMessage(String message, {int addressIndex = 0});
}

class WalletAccount extends AWalletAccount {
  final BIP32 root;

  WalletAccount(this.root, int accountIndex)
      : super(accountIndex, _getPrivateKeyAt(root, accountIndex, 0));

  static EthPrivateKey _getPrivateKeyAt(
      BIP32 root, int accountIndex, int addressIndex) {
    final addressAtIndex =
        root.derivePath("m/44'/60'/$accountIndex'/0/$addressIndex");

    return EthPrivateKey.fromHex(hex.encode(addressAtIndex.privateKey!));
  }

  @override
  Future<String> signMessage(String message, {int addressIndex = 0}) async =>
      "0x${hex.encode(_getPrivateKeyAt(root, addressIndex, addressIndex).signPersonalMessageToUint8List(ascii.encode(message)))}";
}

class BitboxWalletAccount extends AWalletAccount {
  BitboxWalletAccount(super.accountIndex, super.primaryAddress);

  @override
  Future<String> signMessage(String message, {int addressIndex = 0}) async =>
      "0x${hex.encode(await primaryAddress.signPersonalMessage(ascii.encode(message)))}";
}
