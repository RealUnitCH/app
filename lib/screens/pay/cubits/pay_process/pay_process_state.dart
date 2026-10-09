part of 'pay_process_cubit.dart';

/// Why the pay flow failed. Each reason maps to a localized, user-facing
/// message in the view — the cubit carries the reason, not the copy.
///
/// A wallet that is not offered pay is not a failure. That case is
/// [PayProcessNotOffered].
enum PayProcessFailureReason {
  /// Any unexpected error after pay was offered.
  generic,
}

sealed class PayProcessState extends Equatable {
  const PayProcessState();

  @override
  List<Object?> get props => [];
}

class PayProcessInitial extends PayProcessState {
  const PayProcessInitial();
}

class PayProcessPreparingSwap extends PayProcessState {
  const PayProcessPreparingSwap();
}

class PayProcessWaitingForEth extends PayProcessState {
  const PayProcessWaitingForEth();
}

class PayProcessSwapping extends PayProcessState {
  const PayProcessSwapping();
}

class PayProcessRefreshingQuote extends PayProcessState {
  const PayProcessRefreshingQuote();
}

class PayProcessPaying extends PayProcessState {
  const PayProcessPaying();
}

/// Pay tx submitted; polling `/pay/:id/status` until it settles.
class PayProcessAwaitingSettlement extends PayProcessState {
  final String txId;

  const PayProcessAwaitingSettlement(this.txId);

  @override
  List<Object?> get props => [txId];
}

class PayProcessSuccess extends PayProcessState {
  final String? txHash;
  final int shareAmount;
  const PayProcessSuccess({required this.txHash, required this.shareAmount});

  @override
  List<Object?> get props => [txHash, shareAmount];
}

/// Pay is not offered for this wallet. The info page already says so, and
/// the relayer is never asked. This is not a failed payment.
class PayProcessNotOffered extends PayProcessState {
  const PayProcessNotOffered();
}

class PayProcessFailure extends PayProcessState {
  final PayProcessFailureReason reason;

  /// API `message` when the failure came from the DFX API; otherwise null so
  /// the view can fall back to local copy for hardware / process-local reasons.
  final String? message;

  const PayProcessFailure(this.reason, {this.message});

  @override
  List<Object?> get props => [reason, message];
}
