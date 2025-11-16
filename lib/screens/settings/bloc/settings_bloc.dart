import 'package:realunit_wallet/packages/repository/settings_repository.dart';
import 'package:realunit_wallet/styles/language.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'settings_event.dart';
part 'settings_state.dart';

class SettingsBloc extends Bloc<SettingsEvent, SettingsState> {
  SettingsBloc(this._settingsRepository)
      : super(SettingsState(
            language: Language.fromCode(_settingsRepository.language))) {
    on<ToggleHideAmountEvent>(_onToggleHideAmountEvent);
    on<SetLanguageEvent>(_onSetLanguageEvent);
  }

  final SettingsRepository _settingsRepository;

  void _onToggleHideAmountEvent(
      ToggleHideAmountEvent event, Emitter<SettingsState> emit) {
    emit(state.copyWith(hideAmounts: !state.hideAmounts));
  }

  void _onSetLanguageEvent(
      SetLanguageEvent event, Emitter<SettingsState> emit) {
    _settingsRepository.language = event.language.code;
    emit(state.copyWith(language: event.language));
  }
}
