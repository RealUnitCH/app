import 'package:bip39/bip39.dart' as bip39;
import 'package:realunit_wallet/packages/hardware_wallet/bitbox.dart';
import 'package:realunit_wallet/packages/repository/settings_repository.dart';
import 'package:realunit_wallet/packages/repository/wallet_repository.dart';
import 'package:realunit_wallet/packages/wallet/wallet.dart';

class WalletService {
  final WalletRepository _repository;
  final SettingsRepository _settingsRepository;
  final BitboxService _bitboxService;

  const WalletService(this._bitboxService, this._repository, this._settingsRepository);

  Future<SoftwareWallet> createSeedWallet(String name) async {
    final mnemonic = bip39.generateMnemonic();
    final walletId = await _repository.createWallet(name, WalletType.software, mnemonic);
    return SoftwareWallet(walletId, name, mnemonic);
  }

  Future<BitboxWallet> createBitboxWallet(String name) async {
    final address = await _bitboxService.bitboxManager.getETHAddress(1, "m/44'/60'/0'/0/0");
    final walletId = await _repository.createViewWallet(name, WalletType.bitbox, address);
    await setCurrentWallet(walletId);
    return BitboxWallet(walletId, name, address, _bitboxService);
  }

  Future<SoftwareWallet> restoreWallet(String name, String seed) async {
    final walletId = await _repository.createWallet(name, WalletType.software, seed);
    await _settingsRepository.saveCurrentWalletId(walletId);
    return SoftwareWallet(walletId, name, seed);
  }

  Future<DebugWallet> createDebugWallet(String address) async {
    final walletId = await _repository.createViewWallet('Debug', WalletType.debug, address);
    await _settingsRepository.saveCurrentWalletId(walletId);
    return DebugWallet(walletId, 'Debug', address);
  }

  Future<AWallet> getWalletById(int id) async {
    final result = (await _repository.getWalletById(id))!;
    final walletType = WalletType.values[result.type];
    switch (walletType) {
      case WalletType.software:
        return SoftwareWallet(result.id, result.name, result.seed);
      case WalletType.bitbox:
        return BitboxWallet(result.id, result.name, result.address, _bitboxService);
      case WalletType.debug:
        return DebugWallet(result.id, result.name, result.address);
    }
  }

  Future<void> setCurrentWallet(int walletId) async =>
      await _settingsRepository.saveCurrentWalletId(walletId);

  Future<AWallet> getCurrentWallet() async {
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
