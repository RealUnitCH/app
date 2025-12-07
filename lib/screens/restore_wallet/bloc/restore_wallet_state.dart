part of 'restore_wallet_cubit.dart';

class RestoreWalletState {
  final bool isSeedReady;
  final bool isLoading;
  final bool isRestored;
  final SoftwareWallet? wallet;

  const RestoreWalletState(this.isSeedReady, this.isLoading, this.isRestored, [this.wallet]);

  RestoreWalletState copyWith({
    bool? isSeedReady,
    bool? isLoading,
    bool? isRestored,
    SoftwareWallet? wallet,
  }) =>
      RestoreWalletState(
        isSeedReady ?? this.isSeedReady,
        isLoading ?? this.isLoading,
        isRestored ?? this.isRestored,
        wallet ?? this.wallet,
      );
}
