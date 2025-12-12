part of 'restore_wallet_cubit.dart';

class RestoreWalletState extends Equatable {
  final bool isLoading;
  final Wallet? wallet;

  const RestoreWalletState({
    this.isLoading = false,
    this.wallet,
  });

  @override
  List<Object?> get props => [isLoading, wallet];
}
