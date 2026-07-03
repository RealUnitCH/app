// Tier-0 tests for the BTC PSBT pseudo-schema.
//
// PSBT is not typed-data, so the schema's job is two-fold:
//   1. expose the same `Eip712Schema` API surface as the other schemas (so
//      the pipeline can iterate over a uniform schema set)
//   2. pre-flight the raw PSBT bytes — empty / too-short / wrong-magic —
//      with a typed exception before they reach the BitBox plugin.

import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:realunit_wallet/packages/wallet/schemas/btc_psbt_schema.dart';

const _schema = BtcPsbtSchema();

void main() {
  group('BtcPsbtSchema', () {
    test('schemaVersion + primaryType are pinned', () {
      // Version is the migration hook for PSBT-v2 / Schnorr rollout. The
      // testkit's `BtcPsbtMultiInputSign` scenario references this exact
      // string so the coverage-honesty CI knows which version it covers.
      final schemaFactory = BtcPsbtSchema.new;
      final runtimeSchema = schemaFactory();
      expect(runtimeSchema.types, isEmpty);
      expect(_schema.schemaVersion, 'btc-psbt/v1');
      expect(_schema.primaryType, 'BTC_PSBT');
    });

    test('validate(Map) explicitly errors out', () {
      // PSBT has no typed-data envelope — calling validate(Map) is a
      // programming error. We surface it as a StateError instead of
      // silently passing, so a future caller that mis-routes a PSBT
      // through the EIP-712 path gets a loud failure.
      expect(
        () => _schema.validate(const {}),
        throwsA(isA<StateError>()),
      );
    });

    test('validatePsbt accepts a well-formed PSBT prefix', () {
      // BIP-174 magic bytes: psbt\xff. Anything that starts with this
      // five-byte prefix is structurally valid at this layer; the actual
      // BIP-174 parse happens inside the BitBox firmware.
      final ok = Uint8List.fromList([0x70, 0x73, 0x62, 0x74, 0xff, 0x00, 0x00]);
      expect(() => _schema.validatePsbt(ok), returnsNormally);
    });

    test('validatePsbt rejects empty payloads', () {
      // Don't send zero bytes through the BLE/USB pipe — the device would
      // either time out or return an unhelpful generic error.
      expect(
        () => _schema.validatePsbt(Uint8List(0)),
        throwsA(
          isA<BtcPsbtInvalidException>().having(
            (e) => e.reason,
            'reason',
            contains('empty'),
          ),
        ),
      );
    });

    test('validatePsbt rejects payloads shorter than the magic-bytes prefix', () {
      // A 4-byte payload is impossible per BIP-174 — fail fast.
      expect(
        () => _schema.validatePsbt(Uint8List.fromList([0x70, 0x73, 0x62, 0x74])),
        throwsA(
          isA<BtcPsbtInvalidException>().having(
            (e) => e.reason,
            'reason',
            contains('shorter than magic'),
          ),
        ),
      );
    });

    test('validatePsbt rejects a payload with a wrong magic byte', () {
      // The fifth byte must be 0xff per BIP-174. A 0x00 here is a clear
      // protocol mismatch — surface the exact offset for triage.
      expect(
        () => _schema.validatePsbt(Uint8List.fromList([0x70, 0x73, 0x62, 0x74, 0x00, 0x00, 0x00])),
        throwsA(
          isA<BtcPsbtInvalidException>().having(
            (e) => e.reason,
            'reason',
            allOf(contains('offset 4'), contains('0x0'), contains('0xff')),
          ),
        ),
      );
    });
  });
}
