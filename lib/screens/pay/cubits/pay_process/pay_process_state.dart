part of 'pay_process_cubit.dart';

/// Why the pay flow failed. Each reason maps to a localized, user-facing
/// message in the view — the cubit carries the reason, not the copy.
enum PayProcessFailureReason {
  /// The swap quote came back invalid (e.g. not fundable for the requested
  /// ZCHF amount after the slippage buffer).
  insufficientZchf,

  /// Not enough ETH to cover gas and the faucet top-up did not arrive.
  insufficientEth,

  /// The OCP quote expired between the swap and the pay step.
  quoteExpired,

  /// Open CryptoPay settlement failed (rejected by the engine or a terminal
  /// non-completed status).
  payFailed,

  /// Open CryptoPay settlement is unavailable on the current backend
  /// environment (mainnet-only; fails fast on testnet).
  payUnsupportedEnvironment,

  /// The active wallet mode cannot sign transactions (debug wallet).
  signatureUnsupported,

  /// A BitBox is required but not connected.
  bitboxRequired,

  /// Any other unexpected error.
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
  const PayProcessSuccess();
}

class PayProcessFailure extends PayProcessState {
  final PayProcessFailureReason reason;

  /// Diagnostic detail for logs — not the user-facing copy.
  final String? message;

  const PayProcessFailure(this.reason, {this.message});

  @override
  List<Object?> get props => [reason, message];
}
