import 'dart:ui';

import 'package:realunit_wallet/packages/config/network_mode.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsRepository {
  final SharedPreferences _sharedPreferences;

  SettingsRepository(this._sharedPreferences);

  Future<bool> saveCurrentWalletId(int walletId) =>
      _sharedPreferences.setInt('currentWalletId', walletId);

  Future<bool> removeCurrentWalletId() => _sharedPreferences.remove('currentWalletId');

  int? get currentWalletId => _sharedPreferences.getInt('currentWalletId');

  String get language {
    final stored = _sharedPreferences.getString('language');
    if (stored != null) return stored;

    final systemLang = PlatformDispatcher.instance.locale.languageCode;
    return systemLang == 'de' ? 'de' : 'en';
  }

  set language(String langCode) => _sharedPreferences.setString('language', langCode);

  String get currency => _sharedPreferences.getString('currency') ?? 'CHF';

  set currency(String currencyCode) => _sharedPreferences.setString('currency', currencyCode);

  bool get termsAccepted => _sharedPreferences.getBool('termsAccepted') ?? false;

  set termsAccepted(bool accepted) => _sharedPreferences.setBool('termsAccepted', accepted);

  NetworkMode get networkMode {
    final value = _sharedPreferences.getString('networkMode');
    return NetworkMode.values.firstWhere(
      (network) => network.name == value,
      orElse: () => NetworkMode.mainnet,
    );
  }

  set networkMode(NetworkMode mode) => _sharedPreferences.setString('networkMode', mode.name);

  bool get softwareTermsAccepted => _sharedPreferences.getBool('softwareTermsAccepted') ?? false;

  set softwareTermsAccepted(bool accepted) =>
      _sharedPreferences.setBool('softwareTermsAccepted', accepted);

  /// When `true`, deleting the last wallet on the device also wipes the
  /// Keychain-stored mnemonic encryption key. The default is `false` —
  /// leaving the key in place is the conservative choice because a future
  /// restore-from-encrypted-backup would otherwise be unable to decrypt
  /// any seed that came along for the ride. Users who want belt-and-braces
  /// defence-in-depth (factory-reset feel) can opt in via the advanced
  /// settings; the Initiative IV ADR documents the trade-off.
  ///
  /// Setting name kept as a plain bool in shared preferences so a
  /// reinstall picks up the user's prior choice; secure storage isn't
  /// needed for the flag itself, only for the key the flag controls.
  bool get deleteMnemonicKeyOnLastWalletDelete =>
      _sharedPreferences.getBool('deleteMnemonicKeyOnLastWalletDelete') ?? false;

  set deleteMnemonicKeyOnLastWalletDelete(bool enabled) =>
      _sharedPreferences.setBool('deleteMnemonicKeyOnLastWalletDelete', enabled);
}
