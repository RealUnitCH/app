// Test double for [WalletIsolate]. Subclasses the production class via
// the `forTesting()` constructor so SoftwareWallet handles can be
// constructed in unit tests without spawning a real isolate. The
// overrides are intentionally minimal — only the methods exercised by
// the cubits + services are implemented; tests that need a deeper
// IPC fidelity should use a real `WalletIsolate.spawn()` instance
// (see `test/packages/wallet/wallet_isolate_test.dart`).

import 'dart:typed_data';

import 'package:realunit_wallet/packages/wallet/wallet_isolate.dart';

class FakeWalletIsolate extends WalletIsolate {
  FakeWalletIsolate() : super.forTesting();

  /// Per-walletId slot map. Holds either the plaintext (set by
  /// `adoptPlaintext`) or `null` to model "unlocked with no mnemonic".
  /// Tests reach in via the public methods only.
  final Map<int, String> slots = {};

  /// Address each `adoptPlaintext` / `unlock` will return — defaults to
  /// the Hardhat test-mnemonic account-zero address so tests that
  /// don't care about the address get a realistic value.
  String defaultAddress = '0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266';

  /// Latest cancelRequest id received; tests assert against this to
  /// verify the lock-cancel propagation in WalletService.
  int? lastCancelledId;

  int adoptCallCount = 0;
  int unlockCallCount = 0;
  int lockCallCount = 0;

  @override
  Future<String> adoptPlaintext(int walletId, String mnemonic) async {
    adoptCallCount++;
    slots[walletId] = mnemonic;
    return defaultAddress;
  }

  @override
  Future<String> unlock(int walletId, String encryptedSeed, Uint8List keyBytes) async {
    unlockCallCount++;
    // The encrypted-seed contents are opaque to the fake — tests that
    // care about the round-trip use the real isolate. Here we just
    // populate a slot so subsequent reveal/sign paths find one.
    slots[walletId] = '<<encrypted:$encryptedSeed>>';
    return defaultAddress;
  }

  @override
  Future<void> lock(int walletId) async {
    lockCallCount++;
    slots.remove(walletId);
  }

  @override
  Future<String> deriveAddress(int walletId, int accountIndex, int addressIndex) async {
    if (!slots.containsKey(walletId)) {
      throw WalletIsolateNotUnlockedException(walletId);
    }
    return '0x000000000000000000000000000000000000000$accountIndex';
  }

  @override
  Future<({BigInt r, BigInt s, int v})> signDigest(
    int walletId,
    String derivationPath,
    Uint8List digest, {
    int? chainId,
  }) async {
    if (!slots.containsKey(walletId)) {
      throw WalletIsolateNotUnlockedException(walletId);
    }
    return (r: BigInt.one, s: BigInt.two, v: 27);
  }

  @override
  Future<Uint8List> signPersonalMessage(
    int walletId,
    String derivationPath,
    Uint8List payload, {
    int? chainId,
  }) async {
    if (!slots.containsKey(walletId)) {
      throw WalletIsolateNotUnlockedException(walletId);
    }
    return Uint8List(65); // 65 zero bytes — shape-only signature
  }

  @override
  Future<String> reveal(int walletId) async {
    final mnemonic = slots[walletId];
    if (mnemonic == null) {
      throw WalletIsolateNotUnlockedException(walletId);
    }
    return mnemonic;
  }

  @override
  Future<void> cancel(int requestId) async {
    lastCancelledId = requestId;
  }

  @override
  Future<void> dispose() async {
    slots.clear();
  }
}
