/// Raised when a BitBox device fails to hand back a usable ETH address — either
/// at pairing time ([WalletService.createBitboxWallet]) or while self-healing a
/// wallet that was persisted with an empty/invalid address
/// ([WalletService.healCurrentBitboxAddress]).
///
/// Persisting an empty address used to crash the dashboard on the next launch:
/// `EthereumAddress.fromHex("")` throws an uncaught `ArgumentError` inside the
/// build phase, which surfaces as a grey [ErrorWidget] in release. Surfacing a
/// typed exception lets the pairing / recovery flow fall back to its retry path
/// instead.
class BitboxAddressUnavailableException implements Exception {
  const BitboxAddressUnavailableException();

  @override
  String toString() => 'BitBox did not return a valid wallet address';
}
