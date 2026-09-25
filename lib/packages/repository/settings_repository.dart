import 'dart:ui';

import 'package:realunit_wallet/packages/config/network_mode.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsRepository {
  final SharedPreferences _sharedPreferences;

  SettingsRepository(this._sharedPreferences) {
    _migrateInsiderFeature(
      featureKey: 'walletFeaturePay',
      legacyKey: 'insiderPayEnabled',
      includeUnlock: true,
    );
    _migrateInsiderFeature(
      featureKey: 'walletFeatureSend',
      legacyKey: 'insiderSendEnabled',
    );
    _migrateInsiderFeature(
      featureKey: 'walletFeaturePromoCode',
      legacyKey: 'insiderBonusEnabled',
    );
    _migrateInsiderFeature(
      featureKey: 'walletFeatureReferral',
      legacyKey: 'insiderReferralEnabled',
    );
  }

  void _migrateInsiderFeature({
    required String featureKey,
    required String legacyKey,
    bool includeUnlock = false,
  }) {
    if (_sharedPreferences.containsKey(featureKey)) {
      if (_sharedPreferences.containsKey(legacyKey)) {
        _sharedPreferences.remove(legacyKey);
      }
      return;
    }
    final legacyOn = _sharedPreferences.getBool(legacyKey) == true;
    if (!legacyOn && !(includeUnlock && insiderFeaturesUnlocked)) return;
    _sharedPreferences.setBool(featureKey, true);
    _sharedPreferences.remove(legacyKey);
  }

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

  bool get hasStoredCurrency => _sharedPreferences.getString('currency') != null;

  // Unset default is EUR. Residence-based CHF/EUR comes from the account
  // currency on GET /v2/user (applied by SettingsBloc, not persisted here).
  String get currency => _sharedPreferences.getString('currency') ?? 'EUR';

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

  bool get insiderFeaturesUnlocked =>
      _sharedPreferences.getBool('insiderFeaturesUnlocked') ?? false;
  set insiderFeaturesUnlocked(bool unlocked) =>
      _sharedPreferences.setBool('insiderFeaturesUnlocked', unlocked);

  // Does not clear a stored true, and does not override an explicit user-off.
  // User switches use the methods below.
  bool get walletFeaturePay => _sharedPreferences.getBool('walletFeaturePay') ?? false;
  set walletFeaturePay(bool value) {
    if (value && _sharedPreferences.getBool('walletFeaturePayUserOff') == true) return;
    if (!value && walletFeaturePay) return;
    _sharedPreferences.setBool('walletFeaturePay', value);
  }

  bool get walletFeatureSend => _sharedPreferences.getBool('walletFeatureSend') ?? false;
  set walletFeatureSend(bool value) {
    if (value && _sharedPreferences.getBool('walletFeatureSendUserOff') == true) return;
    if (!value && walletFeatureSend) return;
    _sharedPreferences.setBool('walletFeatureSend', value);
  }

  bool get walletFeaturePromoCode =>
      _sharedPreferences.getBool('walletFeaturePromoCode') ?? false;
  set walletFeaturePromoCode(bool value) {
    if (value && _sharedPreferences.getBool('walletFeaturePromoCodeUserOff') == true) {
      return;
    }
    if (!value && walletFeaturePromoCode) return;
    _sharedPreferences.setBool('walletFeaturePromoCode', value);
  }

  bool get walletFeatureReferral =>
      _sharedPreferences.getBool('walletFeatureReferral') ?? false;
  set walletFeatureReferral(bool value) {
    if (value && _sharedPreferences.getBool('walletFeatureReferralUserOff') == true) {
      return;
    }
    if (!value && walletFeatureReferral) return;
    _sharedPreferences.setBool('walletFeatureReferral', value);
  }

  void setWalletFeaturePayFromUser(bool enabled) {
    if (enabled) {
      _sharedPreferences.remove('walletFeaturePayUserOff');
      _sharedPreferences.setBool('walletFeaturePay', true);
    } else {
      _sharedPreferences.setBool('walletFeaturePay', false);
      _sharedPreferences.setBool('walletFeaturePayUserOff', true);
    }
  }

  void setWalletFeatureSendFromUser(bool enabled) {
    if (enabled) {
      _sharedPreferences.remove('walletFeatureSendUserOff');
      _sharedPreferences.setBool('walletFeatureSend', true);
    } else {
      _sharedPreferences.setBool('walletFeatureSend', false);
      _sharedPreferences.setBool('walletFeatureSendUserOff', true);
    }
  }

  void setWalletFeaturePromoCodeFromUser(bool enabled) {
    if (enabled) {
      _sharedPreferences.remove('walletFeaturePromoCodeUserOff');
      _sharedPreferences.setBool('walletFeaturePromoCode', true);
    } else {
      _sharedPreferences.setBool('walletFeaturePromoCode', false);
      _sharedPreferences.setBool('walletFeaturePromoCodeUserOff', true);
    }
  }

  void setWalletFeatureReferralFromUser(bool enabled) {
    if (enabled) {
      _sharedPreferences.remove('walletFeatureReferralUserOff');
      _sharedPreferences.setBool('walletFeatureReferral', true);
    } else {
      _sharedPreferences.setBool('walletFeatureReferral', false);
      _sharedPreferences.setBool('walletFeatureReferralUserOff', true);
    }
  }

  String? get dismissedClientPolicyLatest {
    final value = _sharedPreferences.getString('dismissedClientPolicyLatest');
    if (value == null || value.isEmpty) return null;
    return value;
  }

  set dismissedClientPolicyLatest(String? value) {
    if (value == null || value.isEmpty) {
      _sharedPreferences.remove('dismissedClientPolicyLatest');
    } else {
      _sharedPreferences.setString('dismissedClientPolicyLatest', value);
    }
  }
}
