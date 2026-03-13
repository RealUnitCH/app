part of 'settings_edit_name_cubit.dart';

abstract class SettingsEditNameState extends Equatable {
  const SettingsEditNameState();

  @override
  List<Object?> get props => [];
}

class NameChangeInitial extends SettingsEditNameState {
  const NameChangeInitial();
}

class NameChangeLoading extends SettingsEditNameState {
  const NameChangeLoading();
}

class NameChangeReady extends SettingsEditNameState {
  final String url;

  const NameChangeReady(this.url);

  @override
  List<Object?> get props => [url];
}

class NameChangePending extends SettingsEditNameState {
  const NameChangePending();
}

class NameChangeSubmitting extends SettingsEditNameState {
  const NameChangeSubmitting();
}

class NameChangeSuccess extends SettingsEditNameState {
  const NameChangeSuccess();
}

class NameChangeFailure extends SettingsEditNameState {
  final String message;

  const NameChangeFailure(this.message);

  @override
  List<Object?> get props => [message];
}
