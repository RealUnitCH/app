part of 'home_bloc.dart';

final class HomeState {
  const HomeState({
    this.openWallet,
    this.isLoadingWallet = false,
    this.isFiatServiceAvailable = false,
    this.isDebugAuthenticated = false,
    this.onboardingCompleted = false,
    this.softwareTermsAccepted = false,
  });

  final AWallet? openWallet;
  final bool isLoadingWallet;
  final bool isFiatServiceAvailable;
  final bool isDebugAuthenticated;
  final bool onboardingCompleted;
  final bool softwareTermsAccepted;

  HomeState copyWith({
    AWallet? openWallet,
    bool? isLoadingWallet,
    bool? isFiatServiceAvailable,
    bool? isDebugAuthenticated,
    bool? onboardingCompleted,
    bool? softwareTermsAccepted,
  }) => HomeState(
    openWallet: openWallet ?? this.openWallet,
    isLoadingWallet: isLoadingWallet ?? this.isLoadingWallet,
    isFiatServiceAvailable: isFiatServiceAvailable ?? this.isFiatServiceAvailable,
    isDebugAuthenticated: isDebugAuthenticated ?? this.isDebugAuthenticated,
    onboardingCompleted: onboardingCompleted ?? this.onboardingCompleted,
    softwareTermsAccepted: softwareTermsAccepted ?? this.softwareTermsAccepted,
  );
}
