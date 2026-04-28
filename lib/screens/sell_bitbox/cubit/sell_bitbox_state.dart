part of 'sell_bitbox_cubit.dart';

sealed class SellBitboxState extends Equatable {
  @override
  List<Object?> get props => [];
}

sealed class SellBitboxEthState extends SellBitboxState {}

sealed class SellBitboxSwapState extends SellBitboxState {}

sealed class SellBitboxDepositState extends SellBitboxState {}

class SellBitboxBitboxRequired extends SellBitboxEthState {}

class SellBitboxCheckingEth extends SellBitboxEthState {}

class SellBitboxRequestingFaucet extends SellBitboxEthState {}

class SellBitboxWaitingForEth extends SellBitboxEthState {}

class SellBitboxEthReady extends SellBitboxEthState {}

class SellBitboxPreparingSwap extends SellBitboxSwapState {}

class SellBitboxAwaitingSwapConfirm extends SellBitboxSwapState {
  final String rawSwapTransaction;
  final String rawDepositTransaction;

  SellBitboxAwaitingSwapConfirm(this.rawSwapTransaction, this.rawDepositTransaction);

  @override
  List<Object?> get props => [rawSwapTransaction, rawDepositTransaction];
}

class SellBitboxSwapping extends SellBitboxSwapState {}

class SellBitboxAwaitingDepositConfirm extends SellBitboxDepositState {
  final String signedSwapTransaction;
  final String rawDepositTransaction;

  SellBitboxAwaitingDepositConfirm(this.signedSwapTransaction, this.rawDepositTransaction);

  @override
  List<Object?> get props => [signedSwapTransaction, rawDepositTransaction];
}

class SellBitboxDepositing extends SellBitboxDepositState {}

// Swap was broadcast successfully but deposit broadcast failed
class SellBitboxDepositRetry extends SellBitboxDepositState {
  final String signedSwapTransaction;
  final String signedDepositTransaction;
  final String errorMessage;

  SellBitboxDepositRetry(
    this.signedSwapTransaction,
    this.signedDepositTransaction,
    this.errorMessage,
  );

  @override
  List<Object?> get props => [signedSwapTransaction, signedDepositTransaction, errorMessage];
}

class SellBitboxSuccess extends SellBitboxDepositState {}

class SellBitboxError extends SellBitboxState {
  final String message;

  SellBitboxError(this.message);

  @override
  List<Object?> get props => [message];
}
