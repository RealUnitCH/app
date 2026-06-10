import 'package:http/http.dart';
import 'package:realunit_wallet/packages/config/api_config.dart';
import 'package:realunit_wallet/packages/service/dfx/api_client.dart';
import 'package:realunit_wallet/packages/service/session_cache.dart';
import 'package:realunit_wallet/packages/wallet/wallet.dart';

class AppStore {
  final ApiConfig Function() getApiConfig;
  final SessionCache sessionCache;
  final Client httpClient;

  AWallet? _wallet;

  AppStore(this.getApiConfig, this.sessionCache, [Client? httpClient])
    : httpClient = httpClient ?? RealUnitApiClient();

  set wallet(AWallet wallet_) => _wallet = wallet_;

  AWallet get wallet {
    if (_wallet != null) return _wallet!;
    throw Exception('No Wallet set');
  }

  /// Whether [wallet] is safe to read. False during the brief window between
  /// app launch and the first `HomeBloc` event that calls the `wallet`
  /// setter (`LoadCurrentWalletEvent` for an existing wallet,
  /// `LoadWalletEvent` for a freshly created/restored one), plus the entire
  /// onboarding flow until that happens. Lets services
  /// (`WalletService.lockCurrentWallet`) early-return defensively from
  /// app-lifecycle hooks that fire before any wallet exists.
  ///
  /// Named distinctly from `WalletService.hasWallet()` — that one checks
  /// persisted state (`SettingsRepository.currentWalletId`), this one checks
  /// the in-memory load state. The two diverge during onboarding when a
  /// wallet id has been persisted but `_wallet` is not yet populated.
  bool get isWalletLoaded => _wallet != null;

  ApiConfig get apiConfig => getApiConfig();

  String get primaryAddress => wallet.currentAccount.primaryAddress.address.hex;
}
