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
  const SettingsUserDataFailure();
}

class SettingsUserDataBitboxDisconnected extends SettingsUserDataState {
  const SettingsUserDataBitboxDisconnected();
}

class SettingsUserDataSuccess extends SettingsUserDataState {
  final UserData? userData;
  final String? email;
  final Set<KycStepName> pendingSteps;
  // API-driven per-action gates from `/v2/user.capabilities`. The page
  // uses these to decide whether to render Edit buttons — replacing the
  // local `pendingSteps == inReview` interpretation.
  final UserCapabilitiesDto capabilities;

  /// API gate from registration info. True only when the API reports an
  /// already-registered wallet with a required name update and no manual
  /// review; manual review has precedence. False adds no widget, so the
  /// default user-data screen stays unchanged.
  final bool shareRegisterNameSigningRequired;

  const SettingsUserDataSuccess({
    this.userData,
    this.email,
    this.pendingSteps = const {},
    this.capabilities = const UserCapabilitiesDto(),
    this.shareRegisterNameSigningRequired = false,
  });

  @override
  List<Object?> get props => [
    userData,
    email,
    pendingSteps,
    capabilities,
    shareRegisterNameSigningRequired,
  ];
}
