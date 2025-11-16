import 'package:bip32/bip32.dart';
import 'package:bip39/bip39.dart';
import 'package:realunit_wallet/packages/wallet/wallet_account.dart';

class Wallet {
  final int id;
  final String seed;
  String name;

  /// The Primary account is the account derived from the account index 0
  late final WalletAccount primaryAccount;
  late final BIP32 _bip32;

  late WalletAccount _currentAccount;

  WalletAccount get currentAccount => _currentAccount;

  Wallet(this.id, this.name, this.seed) {
    final seedBytes = mnemonicToSeed(seed);
    _bip32 = BIP32.fromSeed(seedBytes);
    primaryAccount = WalletAccount(_bip32, 0);
    _currentAccount = primaryAccount;
  }

  void selectAccount(int index) =>
      _currentAccount = WalletAccount(_bip32, index);
}
