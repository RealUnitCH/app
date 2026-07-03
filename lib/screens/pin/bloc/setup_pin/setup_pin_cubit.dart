import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:realunit_wallet/packages/service/biometric/biometric_auth_outcome.dart';
import 'package:realunit_wallet/packages/service/biometric_service.dart';
import 'package:realunit_wallet/packages/storage/secure_storage.dart';
import 'package:realunit_wallet/screens/pin/constants/pin_constants.dart';

part 'setup_pin_state.dart';

class SetupPinCubit extends Cubit<SetupPinState> {
  SetupPinCubit(
    SecureStorage secureStorage,
    BiometricService biometricService,
  ) : _secureStorage = secureStorage,
      _biometricService = biometricService,
      super(const SetupPinState());

  final SecureStorage _secureStorage;
  final BiometricService _biometricService;

  String? _createPin;

  void addDigit(int digit) {
    if (state.isSubmitting) return;
    if (state.currentPin.length >= pinLength) return;

    final newPin = '${state.currentPin}$digit';
    emit(state.copyWith(currentPin: newPin, mismatch: false, storeFailed: false));

    if (newPin.length == pinLength) {
      _onPinComplete(newPin);
    }
  }

  void deleteDigit() {
    if (state.isSubmitting) return;
    if (state.currentPin.isEmpty) return;
    emit(
      state.copyWith(
        currentPin: state.currentPin.substring(0, state.currentPin.length - 1),
        mismatch: false,
        storeFailed: false,
      ),
    );
  }

  void _onPinComplete(String pin) {
    switch (state.mode) {
      case SetupPinMode.create:
        _createPin = pin;
        emit(
          state.copyWith(
            mode: SetupPinMode.confirm,
            currentPin: '',
          ),
        );
        break;
      case SetupPinMode.confirm:
        _confirmPin(pin);
        break;
    }
  }

  Future<void> _confirmPin(String confirmPin) async {
    // In-flight guard: a second completion arriving while PBKDF2 is still
    // running is ignored, so the salt/hash pair is written exactly once and can
    // never be torn by an interleaved second write (audit F-09). Defensive —
    // `addDigit` already refuses input while `isSubmitting`, so this line is not
    // reachable through the UI, only a direct re-entry.
    if (state.isSubmitting) return; // coverage:ignore-line

    if (confirmPin != _createPin) {
      emit(
        state.copyWith(
          currentPin: '',
          mismatch: true,
        ),
      );
      return;
    }

    emit(state.copyWith(isSubmitting: true));
    try {
      final salt = SecureStorage.generatePinSalt();
      final hash = await SecureStorage.hashPinAsync(confirmPin, salt);
      if (isClosed) return;
      // Written sequentially (hash first) rather than via Future.wait so a
      // failure is attributed and surfaced instead of completing silently. A
      // torn pair stays bounded: a full retry rewrites both consistently.
      await _secureStorage.setPinHash(hash);
      if (isClosed) return;
      await _secureStorage.setPinSalt(salt);
      if (isClosed) return;
      emit(state.copyWith(isSubmitting: false, isComplete: true));
    } catch (_) {
      // A hash/keychain failure must not strand the user on the spinner with no
      // pad. Restore the input and flag the error so they can retry instead of
      // dead-ending (mirrors VerifyPinCubit._checkPin's recovery).
      if (isClosed) return;
      emit(state.copyWith(currentPin: '', isSubmitting: false, storeFailed: true));
    }
  }

  void reset() => emit(const SetupPinState());

  Future<bool> isBiometricAvailable() => _biometricService.isAvailable();

  // The outcome is unused by the onboarding sheet (a cancel just leaves
  // biometrics off), but the type follows BiometricService.enable().
  Future<BiometricAuthOutcome> enableBiometrics() => _biometricService.enable();
}
