// Tier-0 tests for the registration EIP-712 schemas (V1 + V0-legacy).
//
// These tests pin:
//   - the byte-stable representation of the schema constant — a future
//     refactor that reorders fields or renames a key will turn red here
//     before it ships
//   - the V1-includes-chainId invariant (F-041 fix)
//   - the typesAsJson() output the signer hands to eth_sig_util
//   - drift detection on a representative attack payload
//
// Why pin the byte-stable representation:
// Schema = trust root. If the schema bytes drift between releases without
// a coordinated backend rollout, every existing user's stored EIP-712
// hash diverges from what the new client signs and renewals break. The
// test below uses `serialise()`-style JSON of the schema for stability;
// it does NOT use Object.hashCode (which is salted per VM).

import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:realunit_wallet/packages/wallet/exceptions/eip712_schema_drift_exception.dart';
import 'package:realunit_wallet/packages/wallet/schemas/registration_schema.dart';

void main() {
  group('RegistrationSchemaV1', () {
    const schema = RegistrationSchemaV1();

    test('exposes the EIP-712 RealUnitUser primary type', () {
      expect(schema.primaryType, 'RealUnitUser');
      expect(schema.schemaVersion, 'registration/v1');
    });

    test('domain includes chainId + verifyingContract (F-041 fix)', () {
      // Initiative II closes F-041 by including `chainId` (cross-chain
      // replay protection) and `verifyingContract` (per-backend isolation)
      // in the registration domain. If a refactor removes either, this
      // test fails immediately — backend coordination is required and
      // this guard is the contract that flags it.
      final domain = schema.types['EIP712Domain']!;
      expect(domain.map((f) => f.name), [
        'name',
        'version',
        'chainId',
        'verifyingContract',
      ]);
      expect(domain.where((f) => f.name == 'chainId').single.type, 'uint256');
      expect(
        domain.where((f) => f.name == 'verifyingContract').single.type,
        'address',
      );
    });

    test('RealUnitUser fields are exactly the 13 V1 fields, in order', () {
      // EIP-712 hash depends on the order of fields. Pinning the exact
      // sequence (and `swissTaxResidence` typed as `bool`, F-002) means a
      // reorder or typo turns the build red before the backend stops
      // accepting the signed payload.
      final user = schema.types['RealUnitUser']!;
      expect(user.map((f) => '${f.name}:${f.type}'), [
        'email:string',
        'name:string',
        'type:string',
        'phoneNumber:string',
        'birthday:string',
        'nationality:string',
        'addressStreet:string',
        'addressPostalCode:string',
        'addressCity:string',
        'addressCountry:string',
        'swissTaxResidence:bool',
        'registrationDate:string',
        'walletAddress:address',
      ]);
    });

    test('byte-stable JSON representation', () {
      // Stable JSON serialisation of the schema. If the constant ever
      // drifts (field reorder, type swap), this snapshot is the first
      // line of defence — the test fails BEFORE any deployment.
      final wire = schema.typesAsJson();
      final snapshot = jsonEncode(wire);
      expect(
        snapshot,
        '{"EIP712Domain":'
        '[{"name":"name","type":"string"},'
        '{"name":"version","type":"string"},'
        '{"name":"chainId","type":"uint256"},'
        '{"name":"verifyingContract","type":"address"}],'
        '"RealUnitUser":'
        '[{"name":"email","type":"string"},'
        '{"name":"name","type":"string"},'
        '{"name":"type","type":"string"},'
        '{"name":"phoneNumber","type":"string"},'
        '{"name":"birthday","type":"string"},'
        '{"name":"nationality","type":"string"},'
        '{"name":"addressStreet","type":"string"},'
        '{"name":"addressPostalCode","type":"string"},'
        '{"name":"addressCity","type":"string"},'
        '{"name":"addressCountry","type":"string"},'
        '{"name":"swissTaxResidence","type":"bool"},'
        '{"name":"registrationDate","type":"string"},'
        '{"name":"walletAddress","type":"address"}]}',
      );
    });

    test('accepts a matching backend response', () {
      final backend = jsonDecode(jsonEncode(schema.typesAsJson())) as Map<String, dynamic>;
      expect(() => schema.validate(backend), returnsNormally);
    });

    test('rejects a smuggled `swissTaxResidence: string` reshape', () {
      // F-002 lurking attack: backend silently types swissTaxResidence as
      // string ("true" / "false" / "ja") instead of bool. The signed hash
      // changes, and a string-typed boolean attestation is also less
      // legally clear-cut. Reject.
      final backend = jsonDecode(jsonEncode(schema.typesAsJson())) as Map<String, dynamic>;
      final user = (backend['RealUnitUser'] as List).cast<Map<String, dynamic>>();
      final idx = user.indexWhere((f) => f['name'] == 'swissTaxResidence');
      user[idx] = {'name': 'swissTaxResidence', 'type': 'string'};
      backend['RealUnitUser'] = user;
      expect(
        () => schema.validate(backend),
        throwsA(
          isA<Eip712SchemaDriftException>()
              .having((e) => e.driftedField, 'driftedField', 'RealUnitUser[10].type')
              .having((e) => e.reason, 'reason', contains('swissTaxResidence')),
        ),
      );
    });
  });

  group('RegistrationSchemaV0 (legacy fallback)', () {
    const schema = RegistrationSchemaV0();

    test('domain has no chainId / verifyingContract', () {
      // V0 = pre-F-041 backend; kept available behind an explicit opt-in
      // for the rollout window. Once the backend is upgraded, V0 is
      // removed in a follow-up commit.
      final domain = schema.types['EIP712Domain']!;
      expect(domain.map((f) => f.name), ['name', 'version']);
    });

    test('RealUnitUser field list matches V1', () {
      // The only difference between V0 and V1 is the EIP712Domain; the
      // user fields are stable. Asserts the property so a V0/V1 swap is
      // safe inside the pipeline at the field-level.
      expect(schema.types['RealUnitUser']!, const RegistrationSchemaV1().types['RealUnitUser']!);
    });
  });
}
