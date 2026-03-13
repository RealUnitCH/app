part of 'settings_edit_name_cubit.dart';

abstract class SettingsEditNameState extends Equatable {
  const SettingsEditNameState();

  @override
  List<Object?> get props => [];
}

class SettingsEditNameInitial extends SettingsEditNameState {
  const SettingsEditNameInitial();
}

class SettingsEditNameLoading extends SettingsEditNameState {
  const SettingsEditNameLoading();
}

class SettingsEditNameReady extends SettingsEditNameState {
  final String url;

  const SettingsEditNameReady(this.url);

  @override
  List<Object?> get props => [url];
}

class SettingsEditNamePending extends SettingsEditNameState {
  const SettingsEditNamePending();
}

class SettingsEditNameSubmitting extends SettingsEditNameState {
  const SettingsEditNameSubmitting();
}

class SettingsEditNameSuccess extends SettingsEditNameState {
  const SettingsEditNameSuccess();
}

class SettingsEditNameFailure extends SettingsEditNameState {
  final String message;

  const SettingsEditNameFailure(this.message);

  @override
  List<Object?> get props => [message];
}
