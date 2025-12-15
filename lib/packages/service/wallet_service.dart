import 'package:bip39/bip39.dart' as bip39;
import 'package:realunit_wallet/packages/repository/settings_repository.dart';
import 'package:realunit_wallet/packages/repository/wallet_repository.dart';
import 'package:realunit_wallet/packages/wallet/wallet.dart';

class WalletService {
  final WalletRepository _repository;
  final SettingsRepository _settingsRepository;

  const WalletService(this._repository, this._settingsRepository);

  Future<Wallet> createWallet(String name) {
    final mnemonic = bip39.generateMnemonic();
    return restoreWallet(name, mnemonic);
  }

  Future<Wallet> restoreWallet(String name, String seed) async {
    final walletId = await _repository.createWallet(name, seed);
    await _settingsRepository.saveCurrentWalletId(walletId);
    return Wallet(walletId, name, seed);
  }

  Future<Wallet> getWalletById(int id) async {
    final result = (await _repository.getWalletById(id))!;
    return Wallet(result.id, result.name, result.seed);
  }

  Future<Wallet> getCurrentWallet() async {
    final id = _settingsRepository.currentWalletId!;
    return getWalletById(id);
  }

  Future<void> deleteCurrentWallet() async {
    final id = _settingsRepository.currentWalletId!;
    await _repository.deleteWallet(id);
    await _settingsRepository.removeCurrentWalletId();
  }

  bool hasWallet() => _settingsRepository.currentWalletId != null;

  bool validateSeed(String seed) => bip39.validateMnemonic(seed);
}
