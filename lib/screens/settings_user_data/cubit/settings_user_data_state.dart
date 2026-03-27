part of 'settings_user_data_cubit.dart';

abstract class SettingsUserDataState extends Equatable {
  const SettingsUserDataState();

  @override
  List<Object?> get props => [];
}

class SettingsUserDataInitial extends SettingsUserDataState {
  const SettingsUserDataInitial();
}

class SettingsUserDataLoading extends SettingsUserDataState {
  const SettingsUserDataLoading();
}

class SettingsUserDataFailure extends SettingsUserDataState {
  final String message;

  const SettingsUserDataFailure(this.message);

  @override
  List<Object?> get props => [message];
}

class SettingsUserDataSuccess extends SettingsUserDataState {
  final UserData? userData;
  final String? email;
  final Set<KycStepName> pendingSteps;

  const SettingsUserDataSuccess({this.userData, this.email, this.pendingSteps = const {}});

  @override
  List<Object?> get props => [userData, email, pendingSteps];
}
