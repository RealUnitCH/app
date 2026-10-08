part of 'move_balance_cubit.dart';

enum MoveBalanceDirection { softwareToBitbox, bitboxToSoftware }

enum MoveBalanceFailureReason {
  walletsMissing,
  softwareEmpty,
  bitboxEmpty,
  feeExceedsBalance,
  noQuote,
  quoteMismatch,
}

sealed class MoveBalanceState extends Equatable {
  const MoveBalanceState();

  @override
  List<Object?> get props => [];
}

class MoveBalanceLoading extends MoveBalanceState {
  const MoveBalanceLoading();
}

class MoveBalanceInitial extends MoveBalanceState {
  final int softwareBalance;
  final int bitboxBalance;

  const MoveBalanceInitial({
    required this.softwareBalance,
    required this.bitboxBalance,
  });

  @override
  List<Object?> get props => [softwareBalance, bitboxBalance];
}

class MoveBalanceQuoteReady extends MoveBalanceState {
  final MoveBalanceDirection direction;
  final int amount;
  final int networkFeeRealu;
  final bool ethPaysGas;
  final int softwareBalance;
  final int bitboxBalance;

  const MoveBalanceQuoteReady({
    required this.direction,
    required this.amount,
    required this.networkFeeRealu,
    required this.ethPaysGas,
    required this.softwareBalance,
    required this.bitboxBalance,
  });

  @override
  List<Object?> get props => [
    direction,
    amount,
    networkFeeRealu,
    ethPaysGas,
    softwareBalance,
    bitboxBalance,
  ];
}

class MoveBalanceConfirming extends MoveBalanceState {
  const MoveBalanceConfirming();
}

class MoveBalanceSuccess extends MoveBalanceState {
  final MoveBalanceDirection direction;

  const MoveBalanceSuccess(this.direction);

  @override
  List<Object?> get props => [direction];
}

class MoveBalanceDisconnected extends MoveBalanceState {
  const MoveBalanceDisconnected();
}

class MoveBalanceNeedEth extends MoveBalanceState {
  final String message;

  const MoveBalanceNeedEth(this.message);

  @override
  List<Object?> get props => [message];
}

class MoveBalanceRegistrationRequired extends MoveBalanceState {
  final String message;

  const MoveBalanceRegistrationRequired(this.message);

  @override
  List<Object?> get props => [message];
}

class MoveBalanceFailure extends MoveBalanceState {
  final String message;
  final bool canRetry;
  final MoveBalanceFailureReason? reason;
  final MoveBalanceDirection? direction;

  const MoveBalanceFailure(
    this.message, {
    this.canRetry = false,
    this.reason,
    this.direction,
  });

  @override
  List<Object?> get props => [message, canRetry, reason, direction];
}
