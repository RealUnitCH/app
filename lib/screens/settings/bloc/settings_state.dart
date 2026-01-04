part of 'settings_bloc.dart';

final class SettingsState {
  const SettingsState({
    this.hideAmounts = false,
    this.language = Language.en,
    this.currency = Currency.chf,
    this.networkMode = NetworkMode.testnet,
  });

  final bool hideAmounts;
  final Language language;
  final Currency currency;
  final NetworkMode networkMode;

  SettingsState copyWith({
    bool? hideAmounts,
    Language? language,
    Currency? currency,
    NetworkMode? networkMode,
  }) =>
      SettingsState(
        hideAmounts: hideAmounts ?? this.hideAmounts,
        language: language ?? this.language,
        currency: currency ?? this.currency,
        networkMode: networkMode ?? this.networkMode,
      );
}
