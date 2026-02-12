part of 'verify_pin_cubit.dart';

class VerifyPinState extends Equatable {
  final String pin;

  const VerifyPinState({required this.pin});

  VerifyPinState copyWith({
    String? pin,
  }) => VerifyPinState(
    pin: pin ?? this.pin,
  );

  @override
  List<Object?> get props => [pin];
}

class VerifyPinSuccess extends VerifyPinState {
  const VerifyPinSuccess() : super(pin: '');
}

class VerifyPinFailure extends VerifyPinState {
  const VerifyPinFailure() : super(pin: '');
}
