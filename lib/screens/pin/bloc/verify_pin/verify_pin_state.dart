part of 'verify_pin_cubit.dart';

class VerifyPinState extends Equatable {
  final String pin;
  final bool isBiometricAvailable;

  const VerifyPinState({
    required this.pin,
    required this.isBiometricAvailable,
  });

  VerifyPinState copyWith({
    String? pin,
    bool? isBiometricAvailable,
  }) => VerifyPinState(
    pin: pin ?? this.pin,
    isBiometricAvailable: isBiometricAvailable ?? this.isBiometricAvailable,
  );

  @override
  List<Object?> get props => [pin, isBiometricAvailable];
}

class VerifyPinSuccess extends VerifyPinState {
  const VerifyPinSuccess() : super(pin: '', isBiometricAvailable: false);
}

class VerifyPinFailure extends VerifyPinState {
  const VerifyPinFailure() : super(pin: '', isBiometricAvailable: false);
}
