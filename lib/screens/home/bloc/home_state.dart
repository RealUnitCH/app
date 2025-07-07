part of 'home_bloc.dart';

final class HomeState {
  const HomeState({
    this.openWallet,
    this.isLoadingWallet = false,
    this.isFiatServiceAvailable = false,
  });

  final Wallet? openWallet;
  final bool isLoadingWallet;
  final bool isFiatServiceAvailable;

  HomeState copyWith({
    Wallet? openWallet,
    bool? isLoadingWallet,
    bool? isFiatServiceAvailable,
  }) =>
      HomeState(
        openWallet: openWallet ?? this.openWallet,
        isLoadingWallet: isLoadingWallet ?? this.isLoadingWallet,
        isFiatServiceAvailable:
            isFiatServiceAvailable ?? this.isFiatServiceAvailable,
      );
}
