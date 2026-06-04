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
  final BroadcastTransactionRequestDto signedSwapTransaction;
  final String rawDepositTransaction;

  SellBitboxAwaitingDepositConfirm(this.signedSwapTransaction, this.rawDepositTransaction);

  @override
  List<Object?> get props => [signedSwapTransaction, rawDepositTransaction];
}

class SellBitboxDepositing extends SellBitboxDepositState {}

// The swap was broadcast; the deposit step then failed. `broadcastTxHash` tells
// retry which step to resume: null = the deposit was never broadcast (safe to
// broadcast), non-null = the deposit is already on-chain and only the payment
// confirmation failed, so retry must confirm ONLY and never re-broadcast it
// (issue #657 P4 BB1).
class SellBitboxDepositRetry extends SellBitboxDepositState {
  final BroadcastTransactionRequestDto signedSwapTransaction;
  final BroadcastTransactionRequestDto signedDepositTransaction;
  final String? broadcastTxHash;
  final String errorMessage;

  SellBitboxDepositRetry(
    this.signedSwapTransaction,
    this.signedDepositTransaction,
    this.errorMessage, {
    this.broadcastTxHash,
  });

  @override
  List<Object?> get props =>
      [signedSwapTransaction, signedDepositTransaction, broadcastTxHash, errorMessage];
}

class SellBitboxSuccess extends SellBitboxDepositState {}

class SellBitboxError extends SellBitboxState {
  final String message;

  SellBitboxError(this.message);

  @override
  List<Object?> get props => [message];
}
