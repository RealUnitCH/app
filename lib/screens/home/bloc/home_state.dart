part of 'home_bloc.dart';

final class HomeState {
  const HomeState({
    this.openWallet,
    this.isLoadingWallet = false,
    this.isFiatServiceAvailable = false,
    this.onboardingCompleted = false,
  });

  final AWallet? openWallet;
  final bool isLoadingWallet;
  final bool isFiatServiceAvailable;
  final bool onboardingCompleted;

  HomeState copyWith({
    AWallet? openWallet,
    bool? isLoadingWallet,
    bool? isFiatServiceAvailable,
    bool? onboardingCompleted,
  }) =>
      HomeState(
        openWallet: openWallet ?? this.openWallet,
        isLoadingWallet: isLoadingWallet ?? this.isLoadingWallet,
        isFiatServiceAvailable: isFiatServiceAvailable ?? this.isFiatServiceAvailable,
        onboardingCompleted: onboardingCompleted ?? this.onboardingCompleted,
      );
}
