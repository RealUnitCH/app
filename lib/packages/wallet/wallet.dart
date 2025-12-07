import 'package:bip32/bip32.dart';
import 'package:bip39/bip39.dart';
import 'package:realunit_wallet/packages/hardware_wallet/bitbox.dart';
import 'package:realunit_wallet/packages/wallet/wallet_account.dart';

enum WalletType { software, bitbox }

abstract class AWallet {
  WalletType get walletType;
  final int id;
  String name;

  /// The Primary account is the account derived from the account index 0
  AWalletAccount get primaryAccount;
  AWalletAccount get currentAccount;

  AWallet(this.id, this.name);
}

class Wallet extends AWallet {
  @override
  WalletType get walletType => WalletType.software;

  final String seed;

  @override
  late final WalletAccount primaryAccount;
  late final BIP32 _bip32;

  late WalletAccount _currentAccount;

  @override
  WalletAccount get currentAccount => _currentAccount;

  Wallet(super.id, super.name, this.seed) {
    final seedBytes = mnemonicToSeed(seed);
    _bip32 = BIP32.fromSeed(seedBytes);
    primaryAccount = WalletAccount(_bip32, 0);
    _currentAccount = primaryAccount;
  }

  void selectAccount(int index) => _currentAccount = WalletAccount(_bip32, index);
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
    primaryAccount = BitboxWalletAccount(0, _bitboxService.getCredentials(
        address));
    _currentAccount = primaryAccount;
  }
}
