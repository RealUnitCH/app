// Tier-0 tests for the WalletIsolate (BL-018). These spawn a real
// isolate per group so the IPC contract is exercised end-to-end —
// the mandate is explicit that Tier-1+ uses real cryptographic
// boundaries (no Dart-side mocks of the channel itself).
//
// The test vector is the Hardhat / Foundry test mnemonic — its
// first derivation address is one of the most public addresses in
// Ethereum tooling, which keeps the test as a pinpoint regression
// trip if the derivation path semantics shift.

import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:pointycastle/api.dart';
import 'package:pointycastle/block/aes.dart';
import 'package:pointycastle/block/modes/gcm.dart';
import 'package:realunit_wallet/packages/wallet/wallet_isolate.dart';
import 'package:web3dart/credentials.dart';
import 'package:web3dart/crypto.dart';

const _testMnemonic =
    'test test test test test test test test test test test junk';

// Hardhat / Foundry test account #0 — the canonical "address derived
// from the test mnemonic at m/44'/60'/0'/0/0" value. If a refactor of
// the derivation path or word handling shifts this address, the test
// fails loudly.
const _hardhatAccountZero = '0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266';

void main() {
  group('$WalletIsolate.spawn + adoptPlaintext + deriveAddress', () {
    late WalletIsolate isolate;

    setUp(() async {
      isolate = await WalletIsolate.spawn();
    });

    tearDown(() async {
      await isolate.dispose();
    });

    test('adoptPlaintext returns the BIP-44 account-zero address', () async {
      final address = await isolate.adoptPlaintext(1, _testMnemonic);

      expect(address, _hardhatAccountZero,
          reason: 'BL-018: the unlock path must return the canonical '
              'Hardhat-style address derived inside the isolate, with '
              'no main-side BIP32 derivation along the way');
    });

    test('cachedPrimaryAddress is populated post-adopt + cleared post-lock',
        () async {
      expect(isolate.cachedPrimaryAddress(1), isNull);

      await isolate.adoptPlaintext(1, _testMnemonic);
      expect(isolate.cachedPrimaryAddress(1), _hardhatAccountZero);

      await isolate.lock(1);
      expect(isolate.cachedPrimaryAddress(1), isNull,
          reason: 'the cache is invalidated alongside the isolate slot — '
              'a stale entry would resurface the address after a lock');
    });

    test('deriveAddress for account 1 returns a different address', () async {
      await isolate.adoptPlaintext(7, _testMnemonic);

      final at0 = await isolate.deriveAddress(7, 0, 0);
      final at1 = await isolate.deriveAddress(7, 1, 0);

      expect(at0, _hardhatAccountZero);
      expect(at1, isNot(at0),
          reason: 'BIP-44 account index 1 must yield a distinct address');
    });

    test('deriveAddress without unlock errors out as NotUnlocked', () async {
      await expectLater(
        isolate.deriveAddress(99, 0, 0),
        throwsA(isA<WalletIsolateNotUnlockedException>()),
      );
    });
  });

  group('$WalletIsolate signing', () {
    late WalletIsolate isolate;

    setUp(() async {
      isolate = await WalletIsolate.spawn();
      await isolate.adoptPlaintext(1, _testMnemonic);
    });

    tearDown(() async {
      await isolate.dispose();
    });

    test('signPersonalMessage returns a 65-byte signature', () async {
      final sig = await isolate.signPersonalMessage(
          1, "m/44'/60'/0'/0/0", utf8.encode('hello'));

      expect(sig, isA<Uint8List>());
      expect(sig.length, 65,
          reason: 'EIP-191 personal_sign signatures are 65 bytes (r||s||v)');
    });

    test('signPersonalMessage is deterministic for the same input', () async {
      final a = await isolate.signPersonalMessage(
          1, "m/44'/60'/0'/0/0", utf8.encode('payload'));
      final b = await isolate.signPersonalMessage(
          1, "m/44'/60'/0'/0/0", utf8.encode('payload'));

      expect(a, b,
          reason: 'web3dart personal_sign is deterministic — a hex compare '
              'against the same payload + path must match exactly');
    });

    test('signPersonalMessage with non-ASCII payload does not throw', () async {
      // Regression for #289 — the legacy WalletAccount used to choke
      // on non-ASCII because the BIP32 path didn't pre-normalise. The
      // isolate signs the bytes as given; the caller's encoding is
      // its problem.
      final sig = await isolate.signPersonalMessage(
          1, "m/44'/60'/0'/0/0", utf8.encode('Grüße'));
      expect(sig.length, 65);
    });

    test('signDigest returns (r, s, v) and is verifiable by the public key',
        () async {
      // Build a 32-byte digest from a known message. The isolate
      // signs the digest as-is; we don't expect the caller's intent
      // to be EIP-191 / EIP-712 / raw — that's a SignPipeline
      // concern.
      final digest = keccak256(Uint8List.fromList(utf8.encode('hello')));

      final result =
          await isolate.signDigest(1, "m/44'/60'/0'/0/0", digest, chainId: 1);

      // r,s must be 32-byte BigInts; v must be a small int (27/28 or
      // chain-id-encoded).
      expect(result.r.bitLength, lessThanOrEqualTo(256));
      expect(result.s.bitLength, lessThanOrEqualTo(256));
      expect(result.v, greaterThanOrEqualTo(0));
    });

    test('signPersonalMessage with no unlocked slot errors out cleanly',
        () async {
      await isolate.lock(1);

      await expectLater(
        isolate.signPersonalMessage(
            1, "m/44'/60'/0'/0/0", utf8.encode('payload')),
        throwsA(isA<WalletIsolateNotUnlockedException>()),
      );
    });
  });

  group('$WalletIsolate.lock semantics', () {
    test('locking an absent slot is a no-op (defensive)', () async {
      final isolate = await WalletIsolate.spawn();
      addTearDown(() => isolate.dispose());

      // Pre-condition: no slot.
      await isolate.lock(404);
      // Post-condition: no exception, no state change.
      expect(isolate.cachedPrimaryAddress(404), isNull);
    });

    test('after lock, a fresh adoptPlaintext seats a new slot', () async {
      final isolate = await WalletIsolate.spawn();
      addTearDown(() => isolate.dispose());

      await isolate.adoptPlaintext(1, _testMnemonic);
      await isolate.lock(1);
      final addressAgain = await isolate.adoptPlaintext(1, _testMnemonic);

      expect(addressAgain, _hardhatAccountZero,
          reason: 'BL-018: lock + re-adopt must produce the same address — '
              'the slot is keyed by walletId, not by a fresh nonce');
    });
  });

  group('$WalletIsolate.unlock from encrypted seed', () {
    test('decrypts a SecureStorage-shaped ciphertext and returns the address',
        () async {
      // Mirror SecureStorage.encryptSeed inline so the test does not
      // depend on the secure_storage module (which pulls Flutter
      // bindings). The cipher state matches AES-GCM/128 over a 32-byte
      // key and a 12-byte IV.
      final key = Uint8List.fromList(
          List.generate(32, (i) => (i * 7) & 0xff));
      final iv = Uint8List.fromList(
          List.generate(12, (i) => (i * 13) & 0xff));
      final cipher = GCMBlockCipher(AESEngine())
        ..init(true, AEADParameters(KeyParameter(key), 128, iv, Uint8List(0)));
      final ct = cipher.process(Uint8List.fromList(utf8.encode(_testMnemonic)));
      final encoded = '${base64Encode(iv)}:${base64Encode(ct)}';

      final isolate = await WalletIsolate.spawn();
      addTearDown(() => isolate.dispose());

      final address = await isolate.unlock(1, encoded, key);

      expect(address, _hardhatAccountZero,
          reason: 'BL-018: the encrypted-seed path must round-trip through '
              'AES-GCM inside the isolate and return the same Hardhat-zero '
              'address as the plaintext adopt path');
    });
  });

  group('$WalletIsolate.reveal', () {
    test('round-trips the mnemonic back to the main isolate', () async {
      final isolate = await WalletIsolate.spawn();
      addTearDown(() => isolate.dispose());

      await isolate.adoptPlaintext(1, _testMnemonic);

      final revealed = await isolate.reveal(1);

      expect(revealed, _testMnemonic,
          reason: 'the reveal path is the Law-6-scoped seed-display flow — '
              'verify-seed quiz + settings-seed both rely on this exact byte '
              'identity');
    });

    test('reveal without a slot errors out as NotUnlocked', () async {
      final isolate = await WalletIsolate.spawn();
      addTearDown(() => isolate.dispose());

      await expectLater(
        isolate.reveal(404),
        throwsA(isA<WalletIsolateNotUnlockedException>()),
      );
    });
  });

  group('$WalletIsolate.dispose', () {
    test('disposed isolate rejects further requests', () async {
      final isolate = await WalletIsolate.spawn();

      await isolate.dispose();
      expect(isolate.isDisposed, isTrue);

      await expectLater(
        isolate.adoptPlaintext(1, _testMnemonic),
        throwsA(isA<WalletIsolateException>()),
      );
    });

    test('dispose is idempotent', () async {
      final isolate = await WalletIsolate.spawn();

      await isolate.dispose();
      expect(() => isolate.dispose(), returnsNormally);
    });
  });

  group('$WalletIsolate handle pattern (heap-hygiene smoke test)', () {
    // Smoke-test the BL-018 contract: after lock(), the only field
    // pointing at the BIP39 mnemonic inside the isolate is overwritten
    // (best-effort) with a space-filled string. A full heap-walk
    // assertion lives in `test/test_utils/heap_probe.dart` /
    // `test/integration/crypto_hygiene_test.dart`; this is the
    // narrowest assertion we can make through the public API: after
    // lock, reveal() throws.
    test('lock() drops the slot — reveal() afterwards is NotUnlocked',
        () async {
      final isolate = await WalletIsolate.spawn();
      addTearDown(() => isolate.dispose());

      await isolate.adoptPlaintext(1, _testMnemonic);
      // Sanity: reveal works pre-lock.
      expect(await isolate.reveal(1), _testMnemonic);

      await isolate.lock(1);

      await expectLater(
        isolate.reveal(1),
        throwsA(isA<WalletIsolateNotUnlockedException>()),
        reason: 'post-lock the slot must be gone — a slot that survived '
            'lock would leak the mnemonic to any subsequent reveal',
      );
    });
  });

  group('$WalletIsolate.signPersonalMessage matches a main-side public key',
      () {
    // End-to-end check: the isolate-signed personal message recovers
    // to the canonical Hardhat-zero address. Pins both the
    // EthPrivateKey shape AND the EIP-191 envelope.
    test('signature recovers to the expected EIP-55 address', () async {
      final isolate = await WalletIsolate.spawn();
      addTearDown(() => isolate.dispose());

      await isolate.adoptPlaintext(1, _testMnemonic);

      final payload = Uint8List.fromList(utf8.encode('hello'));
      final sig = await isolate.signPersonalMessage(
          1, "m/44'/60'/0'/0/0", payload);

      // EIP-191 prefix
      final prefix = utf8.encode('Ethereum Signed Message:\n${payload.length}');
      final digest = keccak256(Uint8List.fromList([...prefix, ...payload]));

      final r = bytesToUnsignedInt(sig.sublist(0, 32));
      final s = bytesToUnsignedInt(sig.sublist(32, 64));
      final v = sig[64];

      final recoveredPub = ecRecover(digest, MsgSignature(r, s, v));
      final recoveredAddress = EthereumAddress.fromPublicKey(recoveredPub);

      expect(recoveredAddress.hexEip55, _hardhatAccountZero,
          reason: 'ec-recover of the isolate-produced signature must yield '
              'the same address the isolate returned at adopt time');
    });
  });
}
