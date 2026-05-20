import 'package:http/http.dart';
import 'package:realunit_wallet/packages/config/api_config.dart';
import 'package:realunit_wallet/packages/service/session_cache.dart';
import 'package:realunit_wallet/packages/wallet/wallet.dart';

class AppStore {
  final ApiConfig Function() getApiConfig;
  final SessionCache sessionCache;
  final httpClient = Client();

  AWallet? _wallet;

  /// Callback that decrypts the mnemonic and returns a fully unlocked
  /// [SoftwareWallet]. Wired up after DI registers `WalletService`; null until
  /// then. Used by [ensureUnlocked] so callers don't have to import the
  /// service layer just to upgrade a view-wallet.
  Future<AWallet> Function()? _unlocker;

  AppStore(this.getApiConfig, this.sessionCache);

  set wallet(AWallet wallet_) => _wallet = wallet_;

  AWallet get wallet {
    if (_wallet != null) return _wallet!;
    throw Exception('No Wallet set');
  }

  ApiConfig get apiConfig => getApiConfig();

  String get primaryAddress => wallet.currentAccount.primaryAddress.address.hex;

  void attachUnlocker(Future<AWallet> Function() unlocker) {
    _unlocker = unlocker;
  }

  /// Upgrades the current wallet from [SoftwareViewWallet] (address only) to a
  /// fully unlocked [SoftwareWallet] (mnemonic in memory) so the next sign
  /// operation can run. No-op for wallets that aren't locked, or when no
  /// unlocker has been wired (e.g. tests).
  Future<void> ensureUnlocked() async {
    if (_wallet is! SoftwareViewWallet) return;
    final unlocker = _unlocker;
    if (unlocker == null) return;
    _wallet = await unlocker();
  }
}
