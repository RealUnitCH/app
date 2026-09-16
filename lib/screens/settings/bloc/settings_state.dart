part of 'settings_bloc.dart';

final class SettingsState {
  const SettingsState({
    this.language = Language.en,
    this.currency = Currency.chf,
    this.networkMode = NetworkMode.mainnet,
    this.hideAmounts = false,
    this.insiderFeaturesUnlocked = false,
    this.insiderPayEnabled = false,
  });

  final Language language;
  final Currency currency;
  final NetworkMode networkMode;
  final bool hideAmounts;
  final bool insiderFeaturesUnlocked;
  final bool insiderPayEnabled;

  SettingsState copyWith({
    Language? language,
    Currency? currency,
    NetworkMode? networkMode,
    bool? hideAmounts,
    bool? insiderFeaturesUnlocked,
    bool? insiderPayEnabled,
  }) =>
      SettingsState(
        language: language ?? this.language,
        currency: currency ?? this.currency,
        networkMode: networkMode ?? this.networkMode,
        hideAmounts: hideAmounts ?? this.hideAmounts,
        insiderFeaturesUnlocked: insiderFeaturesUnlocked ?? this.insiderFeaturesUnlocked,
        insiderPayEnabled: insiderPayEnabled ?? this.insiderPayEnabled,
      );
}
