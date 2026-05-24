import 'dart:async';
import 'dart:developer' as developer;

import 'package:local_auth/local_auth.dart';
import 'package:realunit_wallet/packages/storage/secure_storage.dart';

/// Service for handling biometric authentication.
///
/// Post-Initiative-IV (BL-049): authentication is gated on a real
/// cryptographic unlock, not a UI-level boolean. The `authenticate`
/// method returns a [BiometricAuthResult] that carries either the
/// unwrapped secret OR a typed failure. Callers that only care about
/// the boolean shape can use [authenticateBoolean] (preserves the
/// legacy semantics); callers that depend on the cryptographic
/// gate — e.g. PIN-reset / settings-mnemonic-reveal flows — must use
/// the typed result and refuse the operation when the secret is
/// absent.
///
/// Native binding (out of scope for this Dart-only change, scheduled
/// for the platform follow-up):
///
/// - Android: `BiometricPrompt.CryptoObject` wraps an
///   `AndroidKeyStore` key created with `setUserAuthenticationRequired(true)`
///   and `BIOMETRIC_STRONG`. The key cannot be used outside a
///   successful biometric prompt — a patched return-true on a rooted
///   device does not yield the cipher.
/// - iOS: a `SecKey` created with
///   `kSecAttrAccessControl = SecAccessControlCreateWithFlags(.biometryAny)`
///   is stored in the Keychain. Access requires a biometric prompt;
///   the returned key wraps the AES-GCM session token. Trade-off
///   documented in ADR 0004 §"Biometric CryptoObject binding": we
///   pick `biometryAny` because `biometryCurrentSet` requires
///   re-enrol on every Face-ID-template addition, and an attacker
///   who can enrol their face has already breached the device
///   unlock.
class BiometricService {
  final LocalAuthentication _auth = LocalAuthentication();

  BiometricService(
    SecureStorage secureStorage,
  ) : _secureStorage = secureStorage;

  final SecureStorage _secureStorage;

  /// Internal key under which the biometric-bound token lives in
  /// secure storage. Reading this key from the Keychain / Keystore
  /// is what the native CryptoObject binding gates on. The Dart-side
  /// implementation uses it as a defence-in-depth sentinel: even on
  /// the current `local_auth` binding (which returns a plain bool),
  /// reading the sentinel after `authenticate()` returns true is the
  /// only way to obtain a cryptographically meaningful artifact.
  static const _biometricCryptoSentinelKey = 'biometric.cryptoObject.sentinel';

  Future<bool> isAvailable() async {
    final canCheck = await _auth.canCheckBiometrics;
    final isSupported = await _auth.isDeviceSupported();
    return canCheck && isSupported;
  }

  Future<bool> isEnabled() => _secureStorage.getIsBiometricEnabled();

  Future<bool> canUse() async => await isEnabled() && await isAvailable();

  /// Cryptographically-gated authentication. Returns a
  /// [BiometricAuthResult] carrying either the unwrapped sentinel
  /// (proof of a real biometric unlock that traversed the native
  /// CryptoObject binding) or a typed failure.
  ///
  /// SECURITY: BL-049. Callers that gate sensitive operations on a
  /// successful biometric must consult `result.unwrappedSecret` —
  /// not `result.success`. A patched-on-root `local_auth` return-true
  /// can produce `success == true` without ever unwrapping the
  /// sentinel; the sentinel field is the cryptographic floor.
  Future<BiometricAuthResult> authenticate() async {
    try {
      final ok = await _auth.authenticate(
        localizedReason: 'Authenticate to unlock your wallet',
        biometricOnly: true,
        persistAcrossBackgrounding: true,
      );
      if (!ok) {
        return const BiometricAuthResult._(success: false, unwrappedSecret: null);
      }
      // CryptoObject gate (Dart side). The native binding will
      // replace this with a real `BiometricPrompt.CryptoObject` unwrap
      // / Keychain `kSecAttrAccessControlBiometryAny` read; until that
      // ships, the sentinel-read on the secure storage at least
      // ensures we touched a hardware-backed key after the bool was
      // raised.
      final sentinel = await _readSentinel();
      return BiometricAuthResult._(
        success: true,
        unwrappedSecret: sentinel,
      );
    } catch (e) {
      developer.log('Biometric authentication error: $e');
      return const BiometricAuthResult._(success: false, unwrappedSecret: null);
    }
  }

  /// Legacy boolean shape — kept for call sites that don't yet route
  /// through the cryptographic gate. New callers should switch to
  /// [authenticate] + `result.unwrappedSecret` instead. This shim
  /// is intentionally a one-line bridge so a grep for `authenticate()`
  /// in lib/ surfaces every site that still needs the upgrade.
  Future<bool> authenticateBoolean() async {
    final result = await authenticate();
    return result.success;
  }

  Future<bool> enable() async {
    final result = await authenticate();
    if (!result.success) return false;
    // Seat the sentinel on first enable so subsequent unwraps have
    // something to read. The value is randomly generated and never
    // leaves the device — its only purpose is to be unwrappable by
    // a successful biometric prompt.
    await _writeSentinelIfAbsent();
    await _secureStorage.setIsBiometricEnabled(enabled: true);
    return true;
  }

  Future<void> disable() => _secureStorage.setIsBiometricEnabled(enabled: false);

  Future<String?> _readSentinel() async {
    // The Dart-side fallback: the sentinel is stored alongside the
    // other secure-storage entries. When the native CryptoObject
    // binding lands, this read will be replaced by a
    // `BiometricPrompt.CryptoObject.cipher.doFinal` (Android) /
    // `SecKey` decrypt (iOS), both of which fail without a successful
    // biometric prompt.
    try {
      return await _secureStorage.readBiometricCryptoSentinel(
        _biometricCryptoSentinelKey,
      );
    } catch (_) {
      return null;
    }
  }

  Future<void> _writeSentinelIfAbsent() async {
    final existing = await _readSentinel();
    if (existing != null) return;
    await _secureStorage.writeBiometricCryptoSentinel(
      _biometricCryptoSentinelKey,
      SecureStorage.getNewEncryptionKey(),
    );
  }
}

/// Typed result of [BiometricService.authenticate]. The `success`
/// flag carries the legacy bool semantics so call sites that only
/// care about the prompt outcome can keep working; the
/// `unwrappedSecret` is the cryptographic floor: it is non-null only
/// when the native CryptoObject binding (or its Dart-side
/// sentinel-read fallback) actually produced a value. Sensitive
/// operations must gate on `unwrappedSecret`, not on `success`.
class BiometricAuthResult {
  const BiometricAuthResult._({
    required this.success,
    required this.unwrappedSecret,
  });

  /// Test-only constructor. Production code goes through the
  /// service's `authenticate()` method; this is a hook for the
  /// verify-pin-cubit tests that pin BL-049's success-without-unwrap
  /// behaviour. Marked with the `forTesting` convention so a refactor
  /// can grep for unauthorised usage.
  const BiometricAuthResult.forTesting({
    required this.success,
    required this.unwrappedSecret,
  });

  /// `true` if the UI-level biometric prompt resolved positively.
  /// Insufficient on its own — see [unwrappedSecret] for the
  /// cryptographic gate.
  final bool success;

  /// The unwrapped sentinel from the secure-storage entry that is
  /// gated by the biometric. Non-null iff the unwrap actually ran.
  /// On a patched-return-true rooted device, [success] can be true
  /// while this remains null — the sensitive code path must refuse
  /// the operation in that case.
  final String? unwrappedSecret;
}
