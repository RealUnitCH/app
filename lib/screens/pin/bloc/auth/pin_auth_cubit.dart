import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:realunit_wallet/packages/repository/settings_repository.dart';
import 'package:realunit_wallet/packages/storage/secure_storage.dart';
import 'package:realunit_wallet/screens/pin/constants/pin_constants.dart';

part 'pin_auth_state.dart';

class PinAuthCubit extends Cubit<PinAuthState> {
  PinAuthCubit(
    SecureStorage secureStorage,
    SettingsRepository settingsRepository,
  ) : _secureStorage = secureStorage,
      _settingsRepository = settingsRepository,
      super(const PinAuthState());

  final SecureStorage _secureStorage;
  final SettingsRepository _settingsRepository;

  DateTime? _lastBackgroundTime;

  void initialize() {
    final isPinSetup = _settingsRepository.isPinEnabled;
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

  void onAppHidden() => _lastBackgroundTime ??= DateTime.now();

  void onAppResumed() {
    if (!state.isPinSetup) return;

    final lastBackground = _lastBackgroundTime;
    if (lastBackground == null) return;

    final elapsed = DateTime.now().difference(lastBackground);
    if (elapsed >= lockoutDuration) {
      emit(state.copyWith(isPinVerified: false));
    }
    _lastBackgroundTime = null;
  }

  void reset() {
    _settingsRepository.isPinEnabled = false;
    _settingsRepository.isBiometricEnabled = false;
    _secureStorage.deletePinHash();
    emit(const PinAuthState());
  }
}
