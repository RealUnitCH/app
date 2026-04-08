part of 'settings_bloc.dart';

final class SettingsState {
  const SettingsState({
    this.language = Language.en,
    this.currency = Currency.chf,
    this.networkMode = NetworkMode.mainnet,
  });

  final Language language;
  final Currency currency;
  final NetworkMode networkMode;

  SettingsState copyWith({
    Language? language,
    Currency? currency,
    NetworkMode? networkMode,
  }) =>
      SettingsState(
        language: language ?? this.language,
        currency: currency ?? this.currency,
        networkMode: networkMode ?? this.networkMode,
      );
}
