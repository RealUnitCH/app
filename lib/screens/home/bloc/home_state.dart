part of 'home_bloc.dart';

final class HomeState {
  const HomeState({
    this.openWallet,
    this.isLoadingWallet = false,
    this.isFiatServiceAvailable = false,
    this.onboardingCompleted = false,
    this.softwareTermsAccepted = false,
  });

  final AWallet? openWallet;
  final bool isLoadingWallet;
  final bool isFiatServiceAvailable;
  final bool onboardingCompleted;
  final bool softwareTermsAccepted;

  HomeState copyWith({
    AWallet? openWallet,
    bool? isLoadingWallet,
    bool? isFiatServiceAvailable,
    bool? onboardingCompleted,
    bool? softwareTermsAccepted,
  }) => HomeState(
    openWallet: openWallet ?? this.openWallet,
    isLoadingWallet: isLoadingWallet ?? this.isLoadingWallet,
    isFiatServiceAvailable: isFiatServiceAvailable ?? this.isFiatServiceAvailable,
    onboardingCompleted: onboardingCompleted ?? this.onboardingCompleted,
    softwareTermsAccepted: softwareTermsAccepted ?? this.softwareTermsAccepted,
  );
}
