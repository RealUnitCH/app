// Typed failures for the OCP pay flow (scan → swap → pay). Each one renders a
// human-readable string (see `exception_surface_test.dart`) so it can surface
// cleanly in logs, Sentry, and user-facing error states instead of the Dart
// default `Instance of '...'`.

/// The scanned QR / pasted code is not a DFX Open CryptoPay payment link.
class InvalidPaymentLinkException implements Exception {
  final String reason;

  const InvalidPaymentLinkException(this.reason);

  @override
  String toString() => 'InvalidPaymentLinkException: $reason';
}

/// Confirm never left the device, or the server rejected it before relaying.
/// The REALU sale did not start, so the quote may be confirmed again.
/// [apiMessage] is set only when the DFX API returned the text. A local
/// failure leaves it null so the screen uses its own copy.
class PayConfirmNotSubmittedException implements Exception {
  final String message;
  final String? apiMessage;

  const PayConfirmNotSubmittedException(this.message, {this.apiMessage});

  @override
  String toString() => 'PayConfirmNotSubmittedException: $message';
}

/// The debug wallet cannot sign the EIP-7702 delegation, so Pay stops
/// before any request leaves the device.
class PaySignatureUnsupportedException implements Exception {
  // Only ever thrown / constructed as a const expression, so the zero-arg
  // body never registers a runtime line hit; toString() below is exercised.
  const PaySignatureUnsupportedException(); // coverage:ignore-line

  @override
  String toString() =>
      'PaySignatureUnsupportedException: this wallet mode cannot sign transactions';
}

/// The unsigned pay-leg (ZCHF ERC20-transfer) transaction the backend returned for signing does
/// not match its accompanying security metadata (`tokenAddress`, `recipient`, `amountWei`,
/// `chainId`), exceeds local gas/fee caps, mismatches the app's locally configured chainId, or
/// could not be parsed as the expected EIP-1559 ERC20-transfer shape. Thrown by
/// Eip1559UnsignedTxDecoder / Erc20TransferCalldataDecoder and
/// PayProcessCubit._validatePayUnsignedTx BEFORE any pay-leg signing happens, so a
/// malformed/compromised backend pay response can never be blindly signed.
///
/// Scope is the pay leg only. The earlier REALU→ZCHF swap leg
/// (`RealUnitSwapUnsignedTransactionDto`) is signed without this validation today (that DTO
/// has no comparable metadata); closing that gap needs a backend DTO extension.
class PayUnsignedTxMismatchException implements Exception {
  final String reason;

  const PayUnsignedTxMismatchException(this.reason);

  @override
  String toString() => 'PayUnsignedTxMismatchException: $reason';
}
