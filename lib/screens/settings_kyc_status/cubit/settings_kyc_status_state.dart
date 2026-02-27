part of 'settings_kyc_status_cubit.dart';

abstract class SettingsKycStatusState extends Equatable {
  const SettingsKycStatusState();

  @override
  List<Object?> get props => [];
}

class SettingsKycStatusInitial extends SettingsKycStatusState {
  const SettingsKycStatusInitial();
}

class SettingsKycStatusLoading extends SettingsKycStatusState {
  const SettingsKycStatusLoading();
}

class SettingsKycStatusSuccess extends SettingsKycStatusState {
  final KycLevelDto dto;

  const SettingsKycStatusSuccess({required this.dto});

  @override
  List<Object?> get props => [dto];
}

class SettingsKycStatusFailure extends SettingsKycStatusState {
  final String message;

  const SettingsKycStatusFailure(this.message);

  @override
  List<Object?> get props => [message];
}
