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

/// The Open CryptoPay settlement is not available on the current backend
/// environment. The payment-link engine is mainnet-only, so `pay/submit` and
/// `pay/unsigned-transaction` fail fast on dev.api.dfx.swiss (Sepolia).
class PayUnsupportedEnvironmentException implements Exception {
  const PayUnsupportedEnvironmentException();

  @override
  String toString() =>
      'PayUnsupportedEnvironmentException: Open CryptoPay settlement is only '
      'available on mainnet';
}

/// The loaded wallet cannot produce EIP-1559 signatures (today: the debug
/// wallet). The pay flow needs to sign the swap and pay transactions locally,
/// so it cannot proceed in this wallet mode.
class PaySignatureUnsupportedException implements Exception {
  // Only ever thrown / constructed as a const expression, so the zero-arg
  // body never registers a runtime line hit; toString() below is exercised.
  const PaySignatureUnsupportedException(); // coverage:ignore-line

  @override
  String toString() =>
      'PaySignatureUnsupportedException: this wallet mode cannot sign transactions';
}
