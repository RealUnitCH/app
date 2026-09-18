part of 'settings_bloc.dart';

final class SettingsState {
  const SettingsState({
    this.language = Language.en,
    this.currency = Currency.chf,
    this.networkMode = NetworkMode.mainnet,
    this.hideAmounts = false,
    this.insiderFeaturesUnlocked = false,
    this.insiderPayEnabled = false,
    this.insiderSendEnabled = false,
    this.insiderReferralEnabled = false,
    this.insiderBonusEnabled = false,
  });

  final Language language;
  final Currency currency;
  final NetworkMode networkMode;
  final bool hideAmounts;
  final bool insiderFeaturesUnlocked;
  final bool insiderPayEnabled;
  final bool insiderSendEnabled;
  final bool insiderReferralEnabled;
  final bool insiderBonusEnabled;

  bool get insiderPayOn => insiderFeaturesUnlocked && insiderPayEnabled;
  bool get insiderSendOn => insiderFeaturesUnlocked && insiderSendEnabled;
  bool get insiderReferralOn => insiderFeaturesUnlocked && insiderReferralEnabled;
  bool get insiderBonusOn => insiderFeaturesUnlocked && insiderBonusEnabled;

  SettingsState copyWith({
    Language? language,
    Currency? currency,
    NetworkMode? networkMode,
    bool? hideAmounts,
    bool? insiderFeaturesUnlocked,
    bool? insiderPayEnabled,
    bool? insiderSendEnabled,
    bool? insiderReferralEnabled,
    bool? insiderBonusEnabled,
  }) =>
      SettingsState(
        language: language ?? this.language,
        currency: currency ?? this.currency,
        networkMode: networkMode ?? this.networkMode,
        hideAmounts: hideAmounts ?? this.hideAmounts,
        insiderFeaturesUnlocked: insiderFeaturesUnlocked ?? this.insiderFeaturesUnlocked,
        insiderPayEnabled: insiderPayEnabled ?? this.insiderPayEnabled,
        insiderSendEnabled: insiderSendEnabled ?? this.insiderSendEnabled,
        insiderReferralEnabled: insiderReferralEnabled ?? this.insiderReferralEnabled,
        insiderBonusEnabled: insiderBonusEnabled ?? this.insiderBonusEnabled,
      );
}
