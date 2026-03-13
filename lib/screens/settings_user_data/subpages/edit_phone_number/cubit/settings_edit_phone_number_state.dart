part of 'settings_edit_phone_number_cubit.dart';

abstract class SettingsEditPhoneNumberState extends Equatable {
  const SettingsEditPhoneNumberState();

  @override
  List<Object?> get props => [];
}

class PhoneChangeInitial extends SettingsEditPhoneNumberState {
  const PhoneChangeInitial();
}

class PhoneChangeSubmitting extends SettingsEditPhoneNumberState {
  const PhoneChangeSubmitting();
}

class PhoneChangeSuccess extends SettingsEditPhoneNumberState {
  const PhoneChangeSuccess();
}

class PhoneChangeFailure extends SettingsEditPhoneNumberState {
  final String message;

  const PhoneChangeFailure(this.message);

  @override
  List<Object?> get props => [message];
}
