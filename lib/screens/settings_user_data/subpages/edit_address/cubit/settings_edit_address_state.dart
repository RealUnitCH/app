part of 'settings_edit_address_cubit.dart';

abstract class SettingsEditAddressState extends Equatable {
  const SettingsEditAddressState();

  @override
  List<Object?> get props => [];
}

class SettingsEditAddressInitial extends SettingsEditAddressState {
  const SettingsEditAddressInitial();
}

class SettingsEditAddressLoading extends SettingsEditAddressState {
  const SettingsEditAddressLoading();
}

class SettingsEditAddressReady extends SettingsEditAddressState {
  final String url;

  const SettingsEditAddressReady(this.url);

  @override
  List<Object?> get props => [url];
}

class SettingsEditAddressPending extends SettingsEditAddressState {
  const SettingsEditAddressPending();
}

class SettingsEditAddressSubmitting extends SettingsEditAddressState {
  final String url;

  const SettingsEditAddressSubmitting(this.url);

  @override
  List<Object?> get props => [url];
}

class SettingsEditAddressSuccess extends SettingsEditAddressState {
  const SettingsEditAddressSuccess();
}

class SettingsEditAddressFailure extends SettingsEditAddressState {
  final String message;

  const SettingsEditAddressFailure(this.message);

  @override
  List<Object?> get props => [message];
}
