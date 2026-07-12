part of 'home_bloc.dart';

final class HomeState {
  const HomeState({
    this.hasWallet = false,
    this.openWallet,
    this.isLoadingWallet = false,
    this.onboardingCompleted = false,
    this.softwareTermsAccepted = false,
    this.bitboxAddressRecoveryNeeded = false,
  });

  final bool hasWallet;
  final AWallet? openWallet;
  final bool isLoadingWallet;
  final bool onboardingCompleted;
  final bool softwareTermsAccepted;

  /// True when the persisted current wallet is a BitBox row whose address is
  /// empty/invalid — the pre-fix data corruption that crashed the dashboard
  /// build. Routes the app to the address-recovery pairing flow instead of the
  /// dashboard until the device re-supplies a valid address.
  final bool bitboxAddressRecoveryNeeded;

  HomeState copyWith({
    bool? hasWallet,
    AWallet? openWallet,
    bool? isLoadingWallet,
    bool? onboardingCompleted,
    bool? softwareTermsAccepted,
    bool? bitboxAddressRecoveryNeeded,
  }) => HomeState(
    hasWallet: hasWallet ?? this.hasWallet,
    openWallet: openWallet ?? this.openWallet,
    isLoadingWallet: isLoadingWallet ?? this.isLoadingWallet,
    onboardingCompleted: onboardingCompleted ?? this.onboardingCompleted,
    softwareTermsAccepted: softwareTermsAccepted ?? this.softwareTermsAccepted,
    bitboxAddressRecoveryNeeded:
        bitboxAddressRecoveryNeeded ?? this.bitboxAddressRecoveryNeeded,
  );
}
