import 'package:realunit_wallet/packages/config/api_config.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsRepository {
  final SharedPreferences _sharedPreferences;

  SettingsRepository(this._sharedPreferences);

  Future<bool> saveCurrentWalletId(int walletId) =>
      _sharedPreferences.setInt("currentWalletId", walletId);

  Future<bool> removeCurrentWalletId() => _sharedPreferences.remove("currentWalletId");

  int? get currentWalletId => _sharedPreferences.getInt("currentWalletId");

  String get language => _sharedPreferences.getString("language") ?? "de";

  set language(String langCode) => _sharedPreferences.setString("language", langCode);

  String get currency => _sharedPreferences.getString("currency") ?? "CHF";

  set currency(String currencyCode) => _sharedPreferences.setString("currency", currencyCode);

  bool get termsAccepted => _sharedPreferences.getBool("termsAccepted") ?? false;

  set termsAccepted(bool accepted) => _sharedPreferences.setBool("termsAccepted", accepted);

  /// Network mode (testnet or mainnet) - defaults to testnet for safety
  NetworkMode get networkMode {
    final value = _sharedPreferences.getString("networkMode");
    if (value == 'mainnet') return NetworkMode.mainnet;
    return NetworkMode.testnet;
  }

  set networkMode(NetworkMode mode) =>
      _sharedPreferences.setString("networkMode", mode.name);

  /// Get the current API configuration based on network mode
  ApiConfig get apiConfig => ApiConfig(networkMode: networkMode);
}
