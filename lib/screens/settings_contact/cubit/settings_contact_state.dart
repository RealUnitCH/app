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

  const SettingsContactSuccess({this.supportAvailable = false});

  SettingsContactSuccess copyWith({bool? supportAvailable}) {
    return SettingsContactSuccess(
      supportAvailable: supportAvailable ?? this.supportAvailable,
    );
  }

  @override
  List<Object?> get props => [supportAvailable];
}

class SettingsContactFailure extends SettingsContactState {
  final String message;

  const SettingsContactFailure({required this.message});

  @override
  List<Object?> get props => [message];
}
