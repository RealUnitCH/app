import 'dart:convert' show utf8;

import 'package:bip32/bip32.dart';
import 'package:convert/convert.dart';
import 'package:web3dart/web3dart.dart';

abstract class AWalletAccount {
  final int accountIndex;
  final CredentialsWithKnownAddress primaryAddress;

  AWalletAccount(this.accountIndex, this.primaryAddress);

  String getDerivationPath(int addressIndex) => "m/44'/60'/$accountIndex'/0/$addressIndex";

  Future<String> signMessage(String message, {int addressIndex = 0});
}

class WalletAccount extends AWalletAccount {
  final BIP32 root;

  WalletAccount(this.root, int accountIndex)
      : super(accountIndex, _getPrivateKeyAt(root, accountIndex, 0));

  static EthPrivateKey _getPrivateKeyAt(BIP32 root, int accountIndex, int addressIndex) {
    final addressAtIndex = root.derivePath("m/44'/60'/$accountIndex'/0/$addressIndex");

    return EthPrivateKey.fromHex(hex.encode(addressAtIndex.privateKey!));
  }

  @override
  Future<String> signMessage(String message, {int addressIndex = 0}) async =>
      '0x${hex.encode(_getPrivateKeyAt(root, accountIndex, addressIndex).signPersonalMessageToUint8List(utf8.encode(message)))}';
}

class BitboxWalletAccount extends AWalletAccount {
  BitboxWalletAccount(super.accountIndex, super.primaryAddress);

  @override
  Future<String> signMessage(String message, {int addressIndex = 0}) async =>
      '0x${hex.encode(await primaryAddress.signPersonalMessage(utf8.encode(message)))}';
}

class SoftwareViewWalletAccount extends AWalletAccount {
  SoftwareViewWalletAccount(super.accountIndex, super.primaryAddress);

  // Programmer error: callers must await WalletService.ensureCurrentWalletUnlocked
  // before signing. The locked credentials on this account already assert on the
  // same path, so this method is reachable only when the caller bypasses the
  // wallet's primaryAddress and calls signMessage directly.
  @override
  Future<String> signMessage(String message, {int addressIndex = 0}) {
    assert(false, 'SoftwareViewWalletAccount.signMessage called without first '
        'awaiting WalletService.ensureCurrentWalletUnlocked()');
    throw StateError('SoftwareViewWalletAccount cannot sign while the mnemonic '
        'is locked — call WalletService.ensureCurrentWalletUnlocked() first.');
  }
}
