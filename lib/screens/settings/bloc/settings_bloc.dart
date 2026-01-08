import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:realunit_wallet/packages/config/network_mode.dart';
import 'package:realunit_wallet/packages/repository/settings_repository.dart';
import 'package:realunit_wallet/styles/currency.dart';
import 'package:realunit_wallet/styles/language.dart';

part 'settings_event.dart';
part 'settings_state.dart';

class SettingsBloc extends Bloc<SettingsEvent, SettingsState> {
  SettingsBloc(this._settingsRepository, this.getNewAuthToken)
      : super(SettingsState(
          language: Language.fromCode(_settingsRepository.language),
          currency: Currency.fromCode(_settingsRepository.currency),
          networkMode: _settingsRepository.networkMode,
        )) {
    on<ToggleHideAmountEvent>(_onToggleHideAmountEvent);
    on<SetCurrencyEvent>(_onSetCurrencyEvent);
    on<SetLanguageEvent>(_onSetLanguageEvent);
    on<SetNetworkModeEvent>(_onSetNetworkModeEvent);
  }

  final SettingsRepository _settingsRepository;
  final Future<void> Function() getNewAuthToken;

  void _onToggleHideAmountEvent(ToggleHideAmountEvent event, Emitter<SettingsState> emit) {
    emit(state.copyWith(hideAmounts: !state.hideAmounts));
  }

  void _onSetLanguageEvent(SetLanguageEvent event, Emitter<SettingsState> emit) {
    _settingsRepository.language = event.language.code;
    emit(state.copyWith(language: event.language));
  }

  void _onSetCurrencyEvent(SetCurrencyEvent event, Emitter<SettingsState> emit) {
    _settingsRepository.currency = event.currency.code;
    emit(state.copyWith(currency: event.currency));
  }

  Future<void> _onSetNetworkModeEvent(
      SetNetworkModeEvent event, Emitter<SettingsState> emit) async {
    _settingsRepository.networkMode = event.networkMode;
    await getNewAuthToken();
    emit(state.copyWith(networkMode: event.networkMode));
  }
}
