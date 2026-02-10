part of 'pin_auth_cubit.dart';

class PinAuthState extends Equatable {
  final bool isPinSetup;
  final bool isPinVerified;

  const PinAuthState({
    this.isPinSetup = false,
    this.isPinVerified = false,
  });

  PinAuthState copyWith({
    bool? isPinSetup,
    bool? isPinVerified,
  }) {
    return PinAuthState(
      isPinSetup: isPinSetup ?? this.isPinSetup,
      isPinVerified: isPinVerified ?? this.isPinVerified,
    );
  }

  @override
  List<Object?> get props => [isPinSetup, isPinVerified];
}
