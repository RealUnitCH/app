part of 'setup_pin_cubit.dart';

enum SetupPinMode { create, confirm }

class SetupPinState extends Equatable {
  final SetupPinMode mode;
  final String currentPin;
  final bool mismatch;
  final bool isComplete;

  /// True while the confirmed PIN is being hashed and written. Guards the pad
  /// input and doubles as the in-flight flag that keeps a double-tap from
  /// writing the salt/hash pair twice (audit F-09).
  final bool isSubmitting;

  /// True when hashing or persisting the confirmed PIN threw. Surfaces a retry
  /// hint (mirrors [mismatch]) instead of stranding the user on the spinner.
  final bool storeFailed;

  const SetupPinState({
    this.mode = SetupPinMode.create,
    this.currentPin = '',
    this.mismatch = false,
    this.isComplete = false,
    this.isSubmitting = false,
    this.storeFailed = false,
  });

  SetupPinState copyWith({
    SetupPinMode? mode,
    String? currentPin,
    bool? mismatch,
    bool? isComplete,
    bool? isSubmitting,
    bool? storeFailed,
  }) => SetupPinState(
    mode: mode ?? this.mode,
    currentPin: currentPin ?? this.currentPin,
    mismatch: mismatch ?? this.mismatch,
    isComplete: isComplete ?? this.isComplete,
    isSubmitting: isSubmitting ?? this.isSubmitting,
    storeFailed: storeFailed ?? this.storeFailed,
  );

  @override
  List<Object?> get props => [mode, currentPin, mismatch, isComplete, isSubmitting, storeFailed];
}
