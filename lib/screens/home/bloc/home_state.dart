part of 'home_bloc.dart';

final class HomeState {
  const HomeState({
    this.hasWallet = false,
    this.openWallet,
    this.isLoadingWallet = false,
    this.onboardingCompleted = false,
    this.softwareTermsAccepted = false,
  });

  final bool hasWallet;
  final AWallet? openWallet;
  final bool isLoadingWallet;
  final bool onboardingCompleted;
  final bool softwareTermsAccepted;

  HomeState copyWith({
    bool? hasWallet,
    AWallet? openWallet,
    bool? isLoadingWallet,
    bool? onboardingCompleted,
    bool? softwareTermsAccepted,
  }) => HomeState(
    hasWallet: hasWallet ?? this.hasWallet,
    openWallet: openWallet ?? this.openWallet,
    isLoadingWallet: isLoadingWallet ?? this.isLoadingWallet,
    onboardingCompleted: onboardingCompleted ?? this.onboardingCompleted,
    softwareTermsAccepted: softwareTermsAccepted ?? this.softwareTermsAccepted,
  );
}
