part of 'setup_pin_cubit.dart';

enum SetupPinMode { create, confirm }

class SetupPinState extends Equatable {
  final SetupPinMode mode;
  final String currentPin;
  final bool mismatch;
  final bool isComplete;

  const SetupPinState({
    this.mode = SetupPinMode.create,
    this.currentPin = '',
    this.mismatch = false,
    this.isComplete = false,
  });

  SetupPinState copyWith({
    SetupPinMode? mode,
    String? currentPin,
    bool? mismatch,
    bool? isComplete,
  }) => SetupPinState(
    mode: mode ?? this.mode,
    currentPin: currentPin ?? this.currentPin,
    mismatch: mismatch ?? this.mismatch,
    isComplete: isComplete ?? this.isComplete,
  );

  @override
  List<Object?> get props => [mode, currentPin, mismatch, isComplete];
}
