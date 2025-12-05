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
}
