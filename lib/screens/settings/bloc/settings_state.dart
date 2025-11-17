part of 'settings_bloc.dart';

final class SettingsState {
  const SettingsState({
    this.hideAmounts = false,
    this.language = Language.en,
    this.currency = Currency.chf,
  });

  final bool hideAmounts;
  final Language language;
  final Currency currency;

  SettingsState copyWith({
    bool? hideAmounts,
    Language? language,
    Currency? currency,
  }) =>
      SettingsState(
        hideAmounts: hideAmounts ?? this.hideAmounts,
        language: language ?? this.language,
        currency: currency ?? this.currency,
      );
}
