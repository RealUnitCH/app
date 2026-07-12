import 'package:clock/clock.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:realunit_wallet/packages/storage/secure_storage.dart';
import 'package:realunit_wallet/screens/pin/constants/pin_constants.dart';

part 'pin_auth_state.dart';

class PinAuthCubit extends Cubit<PinAuthState> {
  PinAuthCubit(
    SecureStorage secureStorage,
  ) : _secureStorage = secureStorage,
      super(const PinAuthState());

  final SecureStorage _secureStorage;

  DateTime? _lastBackgroundTime;

  Future<void> initialize() async {
    final isPinSetup = await _secureStorage.hasPinHash();
    emit(
      state.copyWith(
        isPinSetup: isPinSetup,
        isPinVerified: !isPinSetup,
      ),
    );
  }

  void onPinSetupComplete() => emit(
    state.copyWith(isPinSetup: true, isPinVerified: true),
  );

  void onPinVerified() => emit(state.copyWith(isPinVerified: true));

  void onAppHidden() => _lastBackgroundTime ??= clock.now();

  void onAppResumed() {
    if (!state.isPinSetup) return;

    final lastBackground = _lastBackgroundTime;
    if (lastBackground == null) return;

    final elapsed = clock.now().difference(lastBackground);
    if (elapsed >= lockoutDuration) {
      emit(state.copyWith(isPinVerified: false));
    }
    _lastBackgroundTime = null;
  }

  Future<void> reset() async {
    await Future.wait([
      _secureStorage.deletePinHash(),
      _secureStorage.deleteBiometricEnabled(),
      _secureStorage.resetPinLockout(),
    ]);
    emit(const PinAuthState());
  }
}
