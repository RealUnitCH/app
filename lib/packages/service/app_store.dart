import 'package:http/http.dart';
import 'package:realunit_wallet/packages/config/api_config.dart';
import 'package:realunit_wallet/packages/service/session_cache.dart';
import 'package:realunit_wallet/packages/wallet/wallet.dart';

class AppStore {
  final ApiConfig Function() getApiConfig;
  final SessionCache sessionCache;
  final httpClient = Client();

  AWallet? _wallet;

  AppStore(this.getApiConfig, this.sessionCache);

  set wallet(AWallet wallet_) => _wallet = wallet_;

  AWallet get wallet {
    if (_wallet != null) return _wallet!;
    throw Exception('No Wallet set');
  }

  ApiConfig get apiConfig => getApiConfig();

  String get primaryAddress => wallet.currentAccount.primaryAddress.address.hex;
}
