part of 'verify_pin_cubit.dart';

class VerifyPinState extends Equatable {
  final String pin;
  final int failedAttempts;

  const VerifyPinState({this.pin = '', this.failedAttempts = 0});

  VerifyPinState copyWith({
    String? pin,
    int? failedAttempts,
  }) => VerifyPinState(
    pin: pin ?? this.pin,
    failedAttempts: failedAttempts ?? this.failedAttempts,
  );

  @override
  List<Object?> get props => [pin, failedAttempts];
}

class VerifyPinSuccess extends VerifyPinState {
  const VerifyPinSuccess() : super(pin: '');
}

class VerifyPinFailure extends VerifyPinState {
  const VerifyPinFailure({required super.failedAttempts}) : super(pin: '');
}

class VerifyPinTemporarilyLocked extends VerifyPinState {
  final DateTime lockedUntil;

  const VerifyPinTemporarilyLocked({
    required super.failedAttempts,
    required this.lockedUntil,
  }) : super(pin: '');

  @override
  List<Object?> get props => [...super.props, lockedUntil];
}

class VerifyPinLocked extends VerifyPinState {
  const VerifyPinLocked({required super.failedAttempts}) : super(pin: '');
}
