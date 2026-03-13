part of 'settings_edit_address_cubit.dart';

abstract class SettingsEditAddressState extends Equatable {
  const SettingsEditAddressState();

  @override
  List<Object?> get props => [];
}

class AddressChangeInitial extends SettingsEditAddressState {
  const AddressChangeInitial();
}

class AddressChangeLoading extends SettingsEditAddressState {
  const AddressChangeLoading();
}

class AddressChangeReady extends SettingsEditAddressState {
  final String url;

  const AddressChangeReady(this.url);

  @override
  List<Object?> get props => [url];
}

class AddressChangePending extends SettingsEditAddressState {
  const AddressChangePending();
}

class AddressChangeSubmitting extends SettingsEditAddressState {
  const AddressChangeSubmitting();
}

class AddressChangeSuccess extends SettingsEditAddressState {
  const AddressChangeSuccess();
}

class AddressChangeFailure extends SettingsEditAddressState {
  final String message;

  const AddressChangeFailure(this.message);

  @override
  List<Object?> get props => [message];
}
