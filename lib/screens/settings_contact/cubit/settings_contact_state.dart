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
  final bool emailSet;

  const SettingsContactSuccess({this.emailSet = false});

  SettingsContactSuccess copyWith({bool? loading, bool? emailSet}) {
    return SettingsContactSuccess(
      emailSet: emailSet ?? this.emailSet,
    );
  }

  @override
  List<Object?> get props => [emailSet];
}

class SettingsContactFailure extends SettingsContactState {
  final String message;

  const SettingsContactFailure({required this.message});

  @override
  List<Object?> get props => [message];
}
