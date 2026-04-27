part of 'settings_edit_phone_number_cubit.dart';

abstract class SettingsEditPhoneNumberState extends Equatable {
  const SettingsEditPhoneNumberState();

  @override
  List<Object?> get props => [];
}

class SettingsEditPhoneNumberInitial extends SettingsEditPhoneNumberState {
  const SettingsEditPhoneNumberInitial();
}

class SettingsEditPhoneNumberSubmitting extends SettingsEditPhoneNumberState {
  const SettingsEditPhoneNumberSubmitting();
}

class SettingsEditPhoneNumberSuccess extends SettingsEditPhoneNumberState {
  const SettingsEditPhoneNumberSuccess();
}

class SettingsEditPhoneNumberFailure extends SettingsEditPhoneNumberState {
  final String message;

  const SettingsEditPhoneNumberFailure(this.message);

  @override
  List<Object?> get props => [message];
}
