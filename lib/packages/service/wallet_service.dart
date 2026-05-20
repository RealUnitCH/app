import 'package:bip39/bip39.dart' as bip39;
import 'package:realunit_wallet/packages/hardware_wallet/bitbox.dart';
import 'package:realunit_wallet/packages/repository/settings_repository.dart';
import 'package:realunit_wallet/packages/repository/wallet_repository.dart';
import 'package:realunit_wallet/packages/service/app_store.dart';
import 'package:realunit_wallet/packages/wallet/wallet.dart';

class WalletService {
  final WalletRepository _repository;
  final SettingsRepository _settingsRepository;
  final BitboxService _bitboxService;
  final AppStore _appStore;

  const WalletService(
    this._bitboxService,
    this._repository,
    this._settingsRepository,
    this._appStore,
  );

  Future<SoftwareWallet> createSeedWallet(String name) async {
    final mnemonic = bip39.generateMnemonic();
    return _persistSoftwareWallet(name, mnemonic);
  }

  Future<BitboxWallet> createBitboxWallet(String name) async {
    final address = await _bitboxService.bitboxManager.getETHAddress(1, "m/44'/60'/0'/0/0");
    final walletId = await _repository.createViewWallet(name, WalletType.bitbox, address);
    await setCurrentWallet(walletId);
    return BitboxWallet(walletId, name, address, _bitboxService);
  }

  Future<SoftwareWallet> restoreWallet(String name, String seed) async {
    final wallet = await _persistSoftwareWallet(name, seed);
    await _settingsRepository.saveCurrentWalletId(wallet.id);
    return wallet;
  }

  /// Builds the BIP32 wallet once to derive the public address, then persists
  /// `(encryptedSeed, address)` so app-start can render the dashboard from the
  /// cached address without re-running the derivation.
  Future<SoftwareWallet> _persistSoftwareWallet(String name, String seed) async {
    final fullWallet = SoftwareWallet(0, name, seed);
    final address = fullWallet.currentAccount.primaryAddress.address.hexEip55;
    final id = await _repository.createWallet(name, WalletType.software, seed, address);
    return SoftwareWallet(id, name, seed);
  }

  Future<DebugWallet> createDebugWallet(String address) async {
    final walletId = await _repository.createViewWallet('Debug', WalletType.debug, address);
    await _settingsRepository.saveCurrentWalletId(walletId);
    return DebugWallet(walletId, 'Debug', address);
  }

  /// Loads a wallet using only what's persisted in clear text — for software
  /// wallets this means a [SoftwareViewWallet] (address only, no mnemonic in
  /// memory). Use [unlockWalletById] when the private key is actually needed.
  Future<AWallet> getWalletById(int id) async {
    final info = (await _repository.getWalletInfo(id))!;
    final walletType = WalletType.values[info.type];
    switch (walletType) {
      case WalletType.software:
        // Legacy rows created before address-caching landed have an empty
        // address column — decrypt the mnemonic this one time, persist the
        // derived address back to the row, then keep using the fast path on
        // subsequent loads.
        if (info.address.isEmpty) {
          final unlocked = (await _repository.getUnlockedWalletById(id))!;
          final wallet = SoftwareWallet(unlocked.id, unlocked.name, unlocked.seed);
          await _repository.updateAddress(
            id,
            wallet.currentAccount.primaryAddress.address.hexEip55,
          );
          return wallet;
        }
        return SoftwareViewWallet(info.id, info.name, info.address);
      case WalletType.bitbox:
        return BitboxWallet(info.id, info.name, info.address, _bitboxService);
      case WalletType.debug:
        return DebugWallet(info.id, info.name, info.address);
    }
  }

  /// Decrypts the mnemonic and returns a [SoftwareWallet] ready to sign.
  /// Throws if the wallet type is not software.
  Future<SoftwareWallet> unlockWalletById(int id) async {
    final info = (await _repository.getUnlockedWalletById(id))!;
    if (WalletType.values[info.type] != WalletType.software) {
      throw StateError('unlockWalletById called for non-software wallet');
    }
    return SoftwareWallet(info.id, info.name, info.seed);
  }

  Future<void> setCurrentWallet(int walletId) async =>
      await _settingsRepository.saveCurrentWalletId(walletId);

  Future<AWallet> getCurrentWallet() async {
    final id = _settingsRepository.currentWalletId!;
    return getWalletById(id);
  }

  Future<SoftwareWallet> unlockCurrentWallet() async {
    final id = _settingsRepository.currentWalletId!;
    return unlockWalletById(id);
  }

  /// Promotes the currently loaded wallet from [SoftwareViewWallet] (address
  /// only) to a fully unlocked [SoftwareWallet] (mnemonic in memory) so the
  /// next sign operation can run. No-op for wallets that aren't locked.
  ///
  /// Owning the lifecycle here — instead of behind a callback wired onto
  /// [AppStore] — keeps the latter as a pure state container.
  Future<void> ensureCurrentWalletUnlocked() async {
    if (_appStore.wallet is! SoftwareViewWallet) return;
    _appStore.wallet = await unlockCurrentWallet();
  }

  /// Replaces the in-memory [SoftwareWallet] with its lock-screen-safe
  /// [SoftwareViewWallet] counterpart, dropping the mnemonic. Called after a
  /// sign operation completes or an idle timer fires so the private key isn't
  /// kept resident for the rest of the foreground session. No-op for wallet
  /// types that don't hold a mnemonic.
  Future<void> lockCurrentWallet() async {
    final current = _appStore.wallet;
    if (current is! SoftwareWallet) return;
    final address = current.currentAccount.primaryAddress.address.hexEip55;
    _appStore.wallet = SoftwareViewWallet(current.id, current.name, address);
  }

  Future<void> deleteCurrentWallet() async {
    final id = _settingsRepository.currentWalletId!;
    await _repository.deleteWallet(id);
    await _settingsRepository.removeCurrentWalletId();
  }

  bool hasWallet() => _settingsRepository.currentWalletId != null;

  bool validateSeed(String seed) => bip39.validateMnemonic(seed);
}
