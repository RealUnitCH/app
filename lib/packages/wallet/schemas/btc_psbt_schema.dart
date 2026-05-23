// Client-pinned schema for BTC PSBT signing.
//
// PSBT (BIP-174) is NOT an EIP-712 typed-data envelope — the BitBox firmware
// signs raw PSBT bytes via the BIP-174 protocol. There is no `types` map
// to compare. We still wrap it in a schema class so:
//
//   1. The pipeline has a uniform `SignRequest → Schema → SignResult`
//      contract for all six entrypoints.
//   2. The PSBT version + `bitbox_flutter` quirk-version pin lives next to
//      the other schemas — a future PSBT v2 / Schnorr / Taproot rollout
//      bumps `schemaVersion` and the testkit scenarios that pin
//      `BtcPsbtMultiInputSign` know which version they exercise.
//   3. The pipeline can reject empty / oversized / wrong-magic-byte PSBTs
//      before they ever reach the BitBox plugin — same fail-fast philosophy
//      as the EIP-712 byte-equal compare.
//
// The base `Eip712Schema.validate` is bypassed for PSBT (no types map),
// so this schema exposes a separate `validatePsbt(Uint8List)` helper.
// Callers MUST NOT use the inherited `validate(Map)` — see assertion in the
// override below.

import 'dart:typed_data';

import 'package:realunit_wallet/packages/wallet/exceptions/sign_exception.dart';
import 'package:realunit_wallet/packages/wallet/schemas/eip712_schema.dart';

/// Raised when a PSBT byte payload fails the structural / magic-byte
/// pre-flight before reaching the BitBox plugin.
class BtcPsbtInvalidException extends SignException {
  final String reason;
  const BtcPsbtInvalidException(this.reason);
  @override
  String get arbKey => 'errorBitboxBtcPsbtInvalid';
  @override
  String toString() => 'BtcPsbtInvalidException($reason)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is BtcPsbtInvalidException && other.reason == reason);
  @override
  int get hashCode => reason.hashCode;
}

class BtcPsbtSchema extends Eip712Schema {
  const BtcPsbtSchema();

  @override
  String get schemaVersion => 'btc-psbt/v1';

  /// PSBTs have no EIP-712 primary type; we expose the protocol name so
  /// logs/journal entries are unambiguous.
  @override
  String get primaryType => 'BTC_PSBT';

  /// PSBTs carry no EIP-712 `types` map. Inheritors use [validatePsbt]
  /// instead of `validate(Map)`.
  @override
  Map<String, List<Eip712FieldSpec>> get types => const {};

  /// Always throws — PSBT does not have a typed-data envelope. Callers
  /// must use [validatePsbt] instead. Documented as a runtime invariant
  /// rather than removed entirely so the inherited class hierarchy stays
  /// uniform across the six entrypoints.
  @override
  void validate(Map<String, dynamic> backendTypes) {
    throw StateError(
      'BtcPsbtSchema.validate(Map) is invalid; PSBT has no typed-data envelope. '
      'Use validatePsbt(Uint8List) instead.',
    );
  }

  /// PSBT pre-flight: rejects empty / clearly-malformed inputs before they
  /// reach the BitBox plugin.
  ///
  /// PSBT magic bytes per BIP-174: `psbt\xff` (`0x70 0x73 0x62 0x74 0xff`).
  /// This is the minimum sanity check; the BitBox firmware performs the
  /// full BIP-174 parse on its side.
  void validatePsbt(Uint8List psbtBytes) {
    if (psbtBytes.isEmpty) {
      throw const BtcPsbtInvalidException('PSBT payload is empty');
    }
    if (psbtBytes.length < 5) {
      throw const BtcPsbtInvalidException('PSBT payload shorter than magic bytes');
    }
    const magic = [0x70, 0x73, 0x62, 0x74, 0xff];
    for (var i = 0; i < 5; i++) {
      if (psbtBytes[i] != magic[i]) {
        throw BtcPsbtInvalidException(
          'PSBT magic-byte mismatch at offset $i: '
          'got 0x${psbtBytes[i].toRadixString(16)}, expected 0x${magic[i].toRadixString(16)}',
        );
      }
    }
  }
}
