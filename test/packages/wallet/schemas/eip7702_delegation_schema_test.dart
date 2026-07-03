// Tier-0 tests for the EIP-7702 delegation schema.
//
// Three drift scenarios that map directly to F-038 attack surfaces:
//   1. extra-field drift   — backend smuggles `secretApproval` into Delegation
//   2. missing-field drift — backend drops `salt` from Delegation
//   3. reordered-field drift — backend swaps `delegate` and `delegator`
//
// Also a couple of structural pins:
//   - The Delegation primary type matches the MetaMask Delegation Framework
//     v1.3.0 shape (5 fields, in order).
//   - The Caveat sub-type is pinned (2 fields, in order).
//   - The domain has chainId + verifyingContract (no F-041 escape hatch
//     for EIP-7702; this domain must always carry the chain binding).

import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:realunit_wallet/packages/wallet/exceptions/eip712_schema_drift_exception.dart';
import 'package:realunit_wallet/packages/wallet/schemas/eip7702_delegation_schema.dart';

const _schema = Eip7702DelegationSchema();

Map<String, dynamic> _matchingTypes() =>
    jsonDecode(jsonEncode(_schema.typesAsJson())) as Map<String, dynamic>;

void main() {
  group('Eip7702DelegationSchema', () {
    test('primary type and version', () {
      expect(_schema.primaryType, 'Delegation');
      expect(_schema.schemaVersion, 'eip7702-delegation/v1');
    });

    test('Delegation has exactly the 5 MetaMask Delegation Framework fields', () {
      // v1.3.0 of the framework defines:
      //   Delegation(address delegate,
      //              address delegator,
      //              bytes32 authority,
      //              Caveat[] caveats,
      //              uint256 salt)
      // Any drift from this shape breaks compatibility with the on-chain
      // verifier — pin the contract here so a refactor cannot silently
      // misalign.
      final delegation = _schema.types['Delegation']!;
      expect(delegation.map((f) => '${f.name}:${f.type}'), [
        'delegate:address',
        'delegator:address',
        'authority:bytes32',
        'caveats:Caveat[]',
        'salt:uint256',
      ]);
    });

    test('Caveat is pinned as 2 fields (enforcer, terms)', () {
      // The Caveat sub-type is the most likely place for a malicious
      // backend to smuggle in an extra field — the user can't see
      // individual caveats in the validate-UI today (just a count + the
      // visible amount), so pinning Caveat's shape is the defence.
      final caveat = _schema.types['Caveat']!;
      expect(caveat.map((f) => '${f.name}:${f.type}'), [
        'enforcer:address',
        'terms:bytes',
      ]);
    });

    test('domain carries chainId + verifyingContract', () {
      final domain = _schema.types['EIP712Domain']!;
      expect(domain.map((f) => f.name), [
        'name',
        'version',
        'chainId',
        'verifyingContract',
      ]);
    });

    test('extra-field drift detection (F-038 attack: secretApproval injected)', () {
      // Exact F-038 worst-case: backend adds an opaque uint256 field the
      // user never reviewed. The pipeline must refuse to sign before any
      // byte hits the BitBox plugin.
      final backend = _matchingTypes();
      backend['Delegation'] = [
        ...(backend['Delegation'] as List).cast<Map<String, dynamic>>(),
        {'name': 'secretApproval', 'type': 'uint256'},
      ];
      expect(
        () => _schema.validate(backend),
        throwsA(
          isA<Eip712SchemaDriftException>()
              .having((e) => e.driftedField, 'driftedField', 'Delegation')
              .having((e) => e.schemaVersion, 'schemaVersion', 'eip7702-delegation/v1')
              .having((e) => e.reason, 'reason', contains('6 fields, expected 5')),
        ),
      );
    });

    test('missing-field drift detection (Delegation drops salt)', () {
      // Backend silently drops `salt`; if the client built the typed-data
      // from the backend response, the on-chain verifier (which expects
      // the salt field for replay protection) would reject the signature.
      // We refuse to even start signing — the salt drop is itself the
      // signal that something is wrong.
      final backend = _matchingTypes();
      backend['Delegation'] = (backend['Delegation'] as List)
          .cast<Map<String, dynamic>>()
          .where((f) => f['name'] != 'salt')
          .toList();
      expect(
        () => _schema.validate(backend),
        throwsA(
          isA<Eip712SchemaDriftException>().having(
            (e) => e.reason,
            'reason',
            contains('4 fields, expected 5'),
          ),
        ),
      );
    });

    test('reordered-field drift detection (Delegation swaps delegate/delegator)', () {
      // EIP-712 hash is order-sensitive. Swapping `delegate` and
      // `delegator` produces a fundamentally different `encodeType`
      // string. A malicious backend that re-orders fields while keeping
      // the same names would produce a signed payload that the on-chain
      // verifier interprets with the operator's intent reversed —
      // catastrophic.
      final backend = _matchingTypes();
      final fields = (backend['Delegation'] as List).cast<Map<String, dynamic>>();
      // Swap [0] and [1] — delegate and delegator.
      final swapped = [fields[1], fields[0], ...fields.skip(2)];
      backend['Delegation'] = swapped;
      expect(
        () => _schema.validate(backend),
        throwsA(
          isA<Eip712SchemaDriftException>().having(
            (e) => e.driftedField,
            'driftedField',
            'Delegation[0].name',
          ),
        ),
      );
    });

    test('extra-group drift (backend adds a top-level type the client never reviewed)', () {
      // A subtler attack: backend adds a sibling top-level type
      // (e.g. `Permit`) and references it from a smuggled `Delegation`
      // field. We never enumerated `Permit` → reject the entire envelope.
      final backend = _matchingTypes();
      backend['Permit'] = [
        {'name': 'owner', 'type': 'address'},
        {'name': 'spender', 'type': 'address'},
      ];
      expect(
        () => _schema.validate(backend),
        throwsA(
          isA<Eip712SchemaDriftException>().having(
            (e) => e.driftedField,
            'driftedField',
            'Permit',
          ),
        ),
      );
    });

    test('Caveat shape drift (extra field on the sub-type)', () {
      // The Caveat shape is the per-caveat trust boundary; a smuggled
      // field here would attach an unreviewed condition to every caveat
      // the user signs.
      final backend = _matchingTypes();
      backend['Caveat'] = [
        ...(backend['Caveat'] as List).cast<Map<String, dynamic>>(),
        {'name': 'exempt', 'type': 'bool'},
      ];
      expect(
        () => _schema.validate(backend),
        throwsA(
          isA<Eip712SchemaDriftException>().having(
            (e) => e.driftedField,
            'driftedField',
            'Caveat',
          ),
        ),
      );
    });

    test('happy-path: byte-equal backend response is accepted', () {
      // Control case: the backend response equals the pinned schema. No
      // exception — otherwise every legit sign would drift-reject.
      expect(() => _schema.validate(_matchingTypes()), returnsNormally);
    });
  });
}
