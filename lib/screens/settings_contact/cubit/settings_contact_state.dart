part of 'settings_contact_cubit.dart';

class SettingsContactState extends Equatable {
  const SettingsContactState();

  @override
  List<Object?> get props => [];
}

class SettingsContactInitial extends SettingsContactState {
  const SettingsContactInitial();
}

class SettingsContactLoading extends SettingsContactState {
  const SettingsContactLoading();
}

class SettingsContactSuccess extends SettingsContactState {
  final bool supportAvailable;
  // Backend-driven contact info for the current brand. The page renders
  // its phone / email / website / imprint from this DTO instead of
  // shipping them hardcoded.
  final DfxCompanyInfoDto? companyInfo;

  const SettingsContactSuccess({this.supportAvailable = false, this.companyInfo});

  SettingsContactSuccess copyWith({bool? supportAvailable, DfxCompanyInfoDto? companyInfo}) {
    return SettingsContactSuccess(
      supportAvailable: supportAvailable ?? this.supportAvailable,
      companyInfo: companyInfo ?? this.companyInfo,
    );
  }

  @override
  List<Object?> get props => [supportAvailable, companyInfo];
}

class SettingsContactFailure extends SettingsContactState {
  final String message;

  const SettingsContactFailure({required this.message});

  @override
  List<Object?> get props => [message];
}
