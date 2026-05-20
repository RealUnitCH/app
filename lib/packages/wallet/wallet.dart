import 'dart:typed_data';

import 'package:bip32/bip32.dart';
import 'package:bip39/bip39.dart';
import 'package:realunit_wallet/packages/hardware_wallet/bitbox.dart';
import 'package:realunit_wallet/packages/wallet/exceptions/wallet_locked_exception.dart';
import 'package:realunit_wallet/packages/wallet/wallet_account.dart';
import 'package:web3dart/crypto.dart';
import 'package:web3dart/web3dart.dart';

enum WalletType { software, bitbox, debug }

abstract class AWallet {
  WalletType get walletType;
  final int id;
  String name;

  /// The Primary account is the account derived from the account index 0
  AWalletAccount get primaryAccount;
  AWalletAccount get currentAccount;

  AWallet(this.id, this.name);
}

class SoftwareWallet extends AWallet {
  @override
  WalletType get walletType => WalletType.software;

  final String seed;

  @override
  late final WalletAccount primaryAccount;
  late final BIP32 _bip32;

  late WalletAccount _currentAccount;

  @override
  WalletAccount get currentAccount => _currentAccount;

  SoftwareWallet(super.id, super.name, this.seed) {
    final seedBytes = mnemonicToSeed(seed);
    _bip32 = BIP32.fromSeed(seedBytes);
    primaryAccount = WalletAccount(_bip32, 0);
    _currentAccount = primaryAccount;
  }

  void selectAccount(int index) => _currentAccount = WalletAccount(_bip32, index);
}

/// Software wallet without the mnemonic in memory — only the public address is
/// cached. Used at app startup so the dashboard renders before the (expensive
/// and rarely needed) BIP32 derivation happens. Must be upgraded to a full
/// [SoftwareWallet] via `WalletService.unlockCurrentWallet` before any sign
/// operation.
class SoftwareViewWallet extends AWallet {
  @override
  WalletType get walletType => WalletType.software;

  @override
  late final SoftwareViewWalletAccount primaryAccount;

  late SoftwareViewWalletAccount _currentAccount;

  @override
  SoftwareViewWalletAccount get currentAccount => _currentAccount;

  SoftwareViewWallet(super.id, super.name, String address) {
    primaryAccount = SoftwareViewWalletAccount(0, _LockedCredentials(address));
    _currentAccount = primaryAccount;
  }
}

class _LockedCredentials extends CredentialsWithKnownAddress {
  final EthereumAddress _address;

  _LockedCredentials(String hexAddress) : _address = EthereumAddress.fromHex(hexAddress);

  @override
  EthereumAddress get address => _address;

  @override
  MsgSignature signToEcSignature(Uint8List payload, {int? chainId, bool isEIP1559 = false}) =>
      throw const WalletLockedException();

  @override
  Future<MsgSignature> signToSignature(Uint8List payload, {int? chainId, bool isEIP1559 = false}) =>
      throw const WalletLockedException();

  @override
  Future<Uint8List> signPersonalMessage(Uint8List payload, {int? chainId}) =>
      throw const WalletLockedException();

  @override
  Uint8List signPersonalMessageToUint8List(Uint8List payload, {int? chainId}) =>
      throw const WalletLockedException();
}

class BitboxWallet extends AWallet {
  @override
  WalletType get walletType => WalletType.bitbox;

  final BitboxService _bitboxService;

  @override
  late final BitboxWalletAccount primaryAccount;

  late BitboxWalletAccount _currentAccount;

  @override
  BitboxWalletAccount get currentAccount => _currentAccount;

  BitboxWallet(super.id, super.name, String address, this._bitboxService) {
    primaryAccount = BitboxWalletAccount(0, _bitboxService.getCredentials(address));
    _currentAccount = primaryAccount;
  }
}

class _DebugCredentials extends CredentialsWithKnownAddress {
  final EthereumAddress _address;

  _DebugCredentials(String hexAddress) : _address = EthereumAddress.fromHex(hexAddress);

  @override
  EthereumAddress get address => _address;

  @override
  MsgSignature signToEcSignature(Uint8List payload, {int? chainId, bool isEIP1559 = false}) =>
      throw UnsupportedError('Debug wallet cannot sign');

  @override
  Future<MsgSignature> signToSignature(Uint8List payload, {int? chainId, bool isEIP1559 = false}) =>
      throw UnsupportedError('Debug wallet cannot sign');

  @override
  Future<Uint8List> signPersonalMessage(Uint8List payload, {int? chainId}) =>
      throw UnsupportedError('Debug wallet cannot sign');

  @override
  Uint8List signPersonalMessageToUint8List(Uint8List payload, {int? chainId}) =>
      throw UnsupportedError('Debug wallet cannot sign');
}

class DebugWalletAccount extends AWalletAccount {
  DebugWalletAccount(String hexAddress) : super(0, _DebugCredentials(hexAddress));

  @override
  Future<String> signMessage(String message, {int addressIndex = 0}) =>
      throw UnsupportedError('Debug wallet cannot sign');
}

class DebugWallet extends AWallet {
  @override
  WalletType get walletType => WalletType.debug;

  final String address;
  late final DebugWalletAccount _account;

  @override
  DebugWalletAccount get primaryAccount => _account;

  @override
  DebugWalletAccount get currentAccount => _account;

  DebugWallet(super.id, super.name, this.address) {
    _account = DebugWalletAccount(address);
  }
}
