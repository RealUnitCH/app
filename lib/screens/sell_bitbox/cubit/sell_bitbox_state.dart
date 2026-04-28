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
  final String rawTransaction;

  SellBitboxAwaitingSwapConfirm(this.rawTransaction);

  @override
  List<Object?> get props => [rawTransaction];
}

class SellBitboxSwapping extends SellBitboxSwapState {}

class SellBitboxPreparingDeposit extends SellBitboxDepositState {}

class SellBitboxAwaitingDepositConfirm extends SellBitboxDepositState {
  final double zchfBalance;

  SellBitboxAwaitingDepositConfirm(this.zchfBalance);

  @override
  List<Object?> get props => [zchfBalance];
}

class SellBitboxDepositing extends SellBitboxDepositState {}

class SellBitboxSuccess extends SellBitboxDepositState {}

class SellBitboxError extends SellBitboxState {
  final String message;

  SellBitboxError(this.message);

  @override
  List<Object?> get props => [message];
}
