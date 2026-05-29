// Tier-0 base-class tests for Eip712Schema + the byte-equal compare
// invariant against backend-supplied types maps.
//
// These tests pin the contract:
//   - extra type group         → drift
//   - missing type group       → drift
//   - extra field in a group   → drift
//   - missing field in a group → drift
//   - reordered fields         → drift  (EIP-712 hashes are order-sensitive)
//   - renamed field            → drift
//   - wrong type on a field    → drift
//   - extra key beyond {name,type} → drift (e.g. `internalType` smuggled in)
//   - non-string name/type     → drift
//   - non-list type group      → drift
//   - identical maps           → accept (no throw)
//
// The schema below is a deliberately minimal test fixture so the asserts
// stay focused on the comparator. Real-world schemas (registration,
// EIP-7702, KYC) inherit the same comparator via `Eip712Schema`.

import 'package:flutter_test/flutter_test.dart';
import 'package:realunit_wallet/packages/wallet/exceptions/eip712_schema_drift_exception.dart';
import 'package:realunit_wallet/packages/wallet/schemas/eip712_schema.dart';

class _TwoFieldSchema extends Eip712Schema {
  const _TwoFieldSchema();

  @override
  String get schemaVersion => 'test/v1';

  @override
  String get primaryType => 'Foo';

  @override
  Map<String, List<Eip712FieldSpec>> get types => const {
    'EIP712Domain': [
      Eip712FieldSpec('name', 'string'),
      Eip712FieldSpec('version', 'string'),
    ],
    'Foo': [
      Eip712FieldSpec('alpha', 'string'),
      Eip712FieldSpec('beta', 'uint256'),
    ],
  };
}

const _schema = _TwoFieldSchema();

Map<String, dynamic> _matching() => {
  'EIP712Domain': [
    {'name': 'name', 'type': 'string'},
    {'name': 'version', 'type': 'string'},
  ],
  'Foo': [
    {'name': 'alpha', 'type': 'string'},
    {'name': 'beta', 'type': 'uint256'},
  ],
};

void main() {
  group('Eip712FieldSpec', () {
    test('value equality, hashCode and diagnostics include name and type', () {
      final amount = ['amount'].single;
      final recipient = ['recipient'].single;
      final uint256 = ['uint256'].single;
      final address = ['address'].single;
      final a = Eip712FieldSpec(amount, uint256);
      final b = Eip712FieldSpec(amount, uint256);
      expect(a, b);
      expect(a.hashCode, b.hashCode);
      expect(a, isNot(Eip712FieldSpec(recipient, uint256)));
      expect(a, isNot(Eip712FieldSpec(amount, address)));
      expect(a.toString(), '{amount: uint256}');
    });
  });

  group('Eip712Schema.validate', () {
    test('accepts a byte-equal map (control case)', () {
      // The baseline: backend response equals the pinned schema. validate()
      // must not throw — otherwise every legitimate sign would drift-reject.
      expect(() => _schema.validate(_matching()), returnsNormally);
    });

    test('rejects an extra type group', () {
      // F-038 worst-case scenario at the group level: backend smuggles in a
      // new top-level type (`Secret`) the client never reviewed.
      final backend = _matching();
      backend['Secret'] = [
        {'name': 'hidden', 'type': 'uint256'},
      ];
      expect(
        () => _schema.validate(backend),
        throwsA(
          isA<Eip712SchemaDriftException>()
              .having((e) => e.driftedField, 'driftedField', 'Secret')
              .having((e) => e.schemaVersion, 'schemaVersion', 'test/v1'),
        ),
      );
    });

    test('rejects a missing type group', () {
      // Schema downgrade attempt — backend drops a group the client expects.
      // Without the missing-check the client would build a typed-data with
      // an empty group and sign a degenerate hash.
      final backend = _matching();
      backend.remove('Foo');
      expect(
        () => _schema.validate(backend),
        throwsA(
          isA<Eip712SchemaDriftException>().having((e) => e.driftedField, 'driftedField', 'Foo'),
        ),
      );
    });

    test('rejects an extra field within a group', () {
      // F-038 exact attack: extra field `{secretApproval, uint256}` in a
      // group the user thinks they reviewed.
      final backend = _matching();
      backend['Foo'] = [
        {'name': 'alpha', 'type': 'string'},
        {'name': 'beta', 'type': 'uint256'},
        {'name': 'secretApproval', 'type': 'uint256'},
      ];
      expect(
        () => _schema.validate(backend),
        throwsA(
          isA<Eip712SchemaDriftException>().having(
            (e) => e.reason,
            'reason',
            contains('3 fields, expected 2'),
          ),
        ),
      );
    });

    test('rejects a missing field within a group', () {
      // Backend silently drops a field the schema expects — sign would
      // succeed against a shorter type string, but the backend stored hash
      // would mismatch. Reject up front.
      final backend = _matching();
      backend['Foo'] = [
        {'name': 'alpha', 'type': 'string'},
      ];
      expect(
        () => _schema.validate(backend),
        throwsA(isA<Eip712SchemaDriftException>()),
      );
    });

    test('rejects a reordered field list', () {
      // EIP-712 hashes the type string left-to-right: swapping field order
      // produces a different `encodeType` and therefore a different hash.
      // A backend that reorders would silently produce a different signed
      // payload — reject so the client never signs the reorder.
      final backend = _matching();
      backend['Foo'] = [
        {'name': 'beta', 'type': 'uint256'},
        {'name': 'alpha', 'type': 'string'},
      ];
      expect(
        () => _schema.validate(backend),
        throwsA(
          isA<Eip712SchemaDriftException>().having(
            (e) => e.driftedField,
            'driftedField',
            'Foo[0].name',
          ),
        ),
      );
    });

    test('rejects a renamed field', () {
      // Same position, same type, different name — different `encodeType`
      // string, different hash.
      final backend = _matching();
      backend['Foo'] = [
        {'name': 'alpha', 'type': 'string'},
        {'name': 'gamma', 'type': 'uint256'},
      ];
      expect(
        () => _schema.validate(backend),
        throwsA(
          isA<Eip712SchemaDriftException>().having(
            (e) => e.driftedField,
            'driftedField',
            'Foo[1].name',
          ),
        ),
      );
    });

    test('rejects a wrong type on a field', () {
      // `uint256` vs `int256` is a different solidity type — same name,
      // different ABI signature, different hash.
      final backend = _matching();
      backend['Foo'] = [
        {'name': 'alpha', 'type': 'string'},
        {'name': 'beta', 'type': 'int256'},
      ];
      expect(
        () => _schema.validate(backend),
        throwsA(
          isA<Eip712SchemaDriftException>().having(
            (e) => e.driftedField,
            'driftedField',
            'Foo[1].type',
          ),
        ),
      );
    });

    test('rejects an extra key beyond {name, type}', () {
      // solc emits `internalType` alongside `name`/`type`; some EIP-712
      // libs treat it as a no-op decoration. We refuse anything beyond the
      // two-key shape because (a) the JSON the backend SIGNS would
      // potentially include those extra keys, (b) extending the accepted
      // shape erodes the byte-equality contract for future fields.
      final backend = _matching();
      backend['Foo'] = [
        {'name': 'alpha', 'type': 'string'},
        {'name': 'beta', 'type': 'uint256', 'internalType': 'uint256'},
      ];
      expect(
        () => _schema.validate(backend),
        throwsA(
          isA<Eip712SchemaDriftException>().having(
            (e) => e.reason,
            'reason',
            contains('extra keys'),
          ),
        ),
      );
    });

    test('rejects a non-string name', () {
      // A backend returning `{name: 42, type: "string"}` is malformed; we
      // refuse the request instead of letting the typed-data builder
      // coerce a non-string into something signable.
      final backend = _matching();
      backend['Foo'] = [
        {'name': 'alpha', 'type': 'string'},
        {'name': 42, 'type': 'uint256'},
      ];
      expect(
        () => _schema.validate(backend),
        throwsA(isA<Eip712SchemaDriftException>()),
      );
    });

    test('rejects a non-list type group', () {
      // Defensive: the backend returns an object where a list was expected.
      // Without this guard the cast `raw as List` would crash with a
      // generic CastError instead of a typed drift exception.
      final backend = _matching();
      backend['Foo'] = {'alpha': 'string'};
      expect(
        () => _schema.validate(backend),
        throwsA(
          isA<Eip712SchemaDriftException>().having(
            (e) => e.reason,
            'reason',
            contains('is not a list'),
          ),
        ),
      );
    });

    test('rejects a non-map field entry', () {
      final backend = _matching();
      backend['Foo'] = [
        'alpha:string',
        {'name': 'beta', 'type': 'uint256'},
      ];
      expect(
        () => _schema.validate(backend),
        throwsA(
          isA<Eip712SchemaDriftException>().having(
            (e) => e.reason,
            'reason',
            contains('not a {name,type} map'),
          ),
        ),
      );
    });

    test('property: validate accepts iff backend == pinned (per field)', () {
      // Mutates each field one at a time and asserts validate rejects.
      // Acts as a generated fuzz for the comparator's per-cell sensitivity
      // without resorting to a separate fast-check/glados dependency.
      for (var groupIndex = 0; groupIndex < _schema.types.length; groupIndex++) {
        final groupName = _schema.types.keys.elementAt(groupIndex);
        final fields = _schema.types[groupName]!;
        for (var fieldIndex = 0; fieldIndex < fields.length; fieldIndex++) {
          final mutated = _matching();
          final list = (mutated[groupName] as List)
              .map((e) => Map<String, dynamic>.from(e as Map))
              .toList();
          // Flip the `name` of the field at (groupIndex, fieldIndex).
          list[fieldIndex] = {
            'name': '${list[fieldIndex]['name']}_MUTATED',
            'type': list[fieldIndex]['type'],
          };
          mutated[groupName] = list;
          expect(
            () => _schema.validate(mutated),
            throwsA(isA<Eip712SchemaDriftException>()),
            reason: 'must reject mutation at $groupName[$fieldIndex].name',
          );
        }
      }
    });

    test('typesAsJson() round-trips into a wire-format map', () {
      // The wire form the signer hands to eth_sig_util is
      // `Map<String, List<Map<String, String>>>`. typesAsJson() builds it
      // from the pinned schema (not from the backend response — that's the
      // whole point of pinning), so callers don't have a chance to leak
      // backend-supplied fields into the signed envelope.
      final wire = _schema.typesAsJson();
      expect(wire['Foo'], [
        {'name': 'alpha', 'type': 'string'},
        {'name': 'beta', 'type': 'uint256'},
      ]);
      expect(wire['EIP712Domain']!.length, 2);
    });
  });
}
