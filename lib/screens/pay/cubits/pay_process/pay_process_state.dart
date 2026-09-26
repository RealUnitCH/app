part of 'pay_process_cubit.dart';

/// Why the pay flow failed. Each reason maps to a localized, user-facing
/// message in the view — the cubit carries the reason, not the copy.
enum PayProcessFailureReason {
  /// Not enough ETH to cover gas and the faucet top-up did not arrive.
  insufficientEth,

  /// The active wallet mode cannot sign transactions (debug wallet).
  signatureUnsupported,

  /// Pay is not offered for this wallet. BitBox has no Pay option.
  payUnavailable,

  /// A BitBox is required but not connected.
  bitboxRequired,

  /// Any other unexpected error.
  generic,
}

/// Why a pay confirm is offered again. This payment does not leave CHF in the
/// wallet. Retry sends the same delegation again and can sell REALU when the
/// first confirm did not arrive. Each reason maps to a localized message.
enum PayRetryReason {
  /// The quote expired before it settled. This payment leaves no CHF. Retry
  /// sends the same delegation again.
  quoteExpired,

  /// The confirm or the settlement status did not finish. No CHF from this
  /// payment is in the wallet. Retry sends the same delegation again.
  transient,

  /// The proceeds no longer cover the payment. This payment leaves no CHF.
  /// Retry sends the same delegation again.
  insufficientZchf,

  /// The unsigned tx the backend returned for signing did not match its own security metadata
  /// (token/recipient/amount/chain) — see [PayUnsignedTxMismatchException]. Never signed. Retrying
  /// re-fetches AND re-validates a fresh unsigned tx from scratch.
  unsignedTxMismatch,
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
  const PayProcessSuccess();
}

/// A pay confirm did not finish. This payment leaves no CHF in the wallet.
/// [PayProcessCubit.retryPay] sends the same delegation again and can sell
/// REALU when the first confirm did not arrive.
class PayProcessPayRetry extends PayProcessState {
  final PayRetryReason reason;

  /// API `message` when the failure came from the DFX API; otherwise null so
  /// the view can fall back to local copy for process-local reasons.
  final String? message;

  const PayProcessPayRetry(this.reason, {this.message});

  @override
  List<Object?> get props => [reason, message];
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
