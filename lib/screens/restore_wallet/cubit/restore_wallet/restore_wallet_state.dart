part of 'restore_wallet_cubit.dart';

class RestoreWalletState extends Equatable {
  final bool isLoading;

  /// True when the restore attempt threw — the UI leaves the loading state and
  /// offers a retry instead of spinning forever (issue #657 P1 B1).
  final bool hasError;
  final SoftwareWallet? wallet;

  const RestoreWalletState({
    this.isLoading = false,
    this.hasError = false,
    this.wallet,
  });

  @override
  List<Object?> get props => [isLoading, hasError, wallet];
}
