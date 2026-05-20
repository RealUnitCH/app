/// Thrown when a sign operation hits a [SoftwareViewWallet] — the mnemonic is
/// still encrypted on disk and the caller must unlock the wallet (via
/// `WalletService.unlockCurrentWallet`) before signing.
class WalletLockedException implements Exception {
  const WalletLockedException();

  @override
  String toString() => 'Wallet is locked';
}
