// Typed failures for the wallet-to-wallet (W2W) RealUnit transfer flow
// (enter/scan recipient → amount → confirm → sign → transfer → confirm). Each
// one renders a human-readable string (enumerated in `exception_surface_test.dart`)
// so it surfaces cleanly in logs and user-facing error states instead of the
// Dart default `Instance of '...'`. Typed failures drive control flow — no
// error-string parsing.

/// The recipient string the user scanned or pasted is not a syntactically valid
/// EVM address. This is a client-side UX guard only; the API remains the final
/// authority on the address.
class InvalidRecipientAddressException implements Exception {
  /// The rejected raw input, for diagnostics.
  final String input;

  const InvalidRecipientAddressException(this.input);

  @override
  String toString() => 'InvalidRecipientAddressException: $input is not a valid wallet address';
}

/// The active wallet mode cannot produce the EIP-712 delegation + EIP-7702
/// authorization the gasless transfer requires (today: the debug wallet, and
/// hardware wallets whose firmware exposes no raw EIP-7702 signing API). The
/// flow is not branched on wallet type beyond this capability gate.
class TransferSignatureUnsupportedException implements Exception {
  /// Diagnostic detail (e.g. the underlying signer message).
  final String detail;

  const TransferSignatureUnsupportedException([
    this.detail = 'this wallet mode cannot sign gasless transfers',
  ]);

  @override
  String toString() => 'TransferSignatureUnsupportedException: $detail';
}

/// DFX cannot currently fund gas for the gasless transfer (the backend's
/// dedicated W2W gas wallet is unconfigured or below its low-balance
/// threshold). Surfaced from the API's `ServiceUnavailable` (503) as a friendly
/// "temporarily unavailable" state — the user's REALU is untouched.
class TransferGasFundingUnavailableException implements Exception {
  /// Diagnostic detail (e.g. the API message), for logs.
  final String detail;

  const TransferGasFundingUnavailableException([
    this.detail = 'gas funding for transfers is temporarily unavailable',
  ]);

  @override
  String toString() => 'TransferGasFundingUnavailableException: $detail';
}
