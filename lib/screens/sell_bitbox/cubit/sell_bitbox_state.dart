part of 'sell_bitbox_cubit.dart';

abstract class SellBitboxState extends Equatable {
  @override
  List<Object?> get props => [];
}

class SellBitboxBitboxRequired extends SellBitboxState {}

// ETH check

class SellBitboxCheckingEth extends SellBitboxState {}

class SellBitboxRequestingFaucet extends SellBitboxState {}

class SellBitboxWaitingForEth extends SellBitboxState {}

class SellBitboxEthReady extends SellBitboxState {}

// REALU → ZCHF swap

class SellBitboxPreparingSwap extends SellBitboxState {}

class SellBitboxAwaitingSwapConfirm extends SellBitboxState {
  final String rawTransaction;

  SellBitboxAwaitingSwapConfirm(this.rawTransaction);

  @override
  List<Object?> get props => [rawTransaction];
}

class SellBitboxSwapping extends SellBitboxState {}

// ZCHF → DFX deposit

class SellBitboxPreparingDeposit extends SellBitboxState {}

class SellBitboxAwaitingDepositConfirm extends SellBitboxState {
  final double zchfBalance;

  SellBitboxAwaitingDepositConfirm(this.zchfBalance);

  @override
  List<Object?> get props => [zchfBalance];
}

class SellBitboxDepositing extends SellBitboxState {}

// ── Terminal

class SellBitboxSuccess extends SellBitboxState {}

class SellBitboxError extends SellBitboxState {
  final String message;

  SellBitboxError(this.message);

  @override
  List<Object?> get props => [message];
}
