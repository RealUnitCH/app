// EIP-712 schema base class.
//
// A schema is a compile-time constant description of the typed-data fields
// the client is willing to sign. The pipeline compares the backend-supplied
// `types` map against this constant **byte-equal** before any sign byte
// reaches the BitBox plugin.
//
// Why byte-equal and not "structural": F-038 (Initiative II) — a malicious
// backend could add a hidden field, reorder fields, swap types, or rename a
// field while keeping the visible message intact. The user would never see
// the extra field in the validate-UI, the BitBox would sign it anyway, and
// the operator would be stuck with a signature over an envelope they cannot
// re-derive. The only safe contract is: the client signs ONLY shapes it has
// explicitly approved in source. Any deviation is rejected up front.
//
// Equality semantics:
// - Field order matters. EIP-712 hashes the type string left-to-right; two
//   field lists with the same names but reordered produce different hashes.
// - Field names matter. A typo `delgate` vs `delegate` is a different type
//   and must drift-reject.
// - Field types matter. A backend that switches `uint256` to `int256` for
//   a numeric field is a schema mismatch.
// - Top-level type-group names matter. `'Delegation'` vs `'delegation'` is
//   a different primary type.
// - Extra top-level groups in the backend response (not just within a
//   group) also drift. The client schema is the trust root; anything else
//   is foreign.

import 'package:realunit_wallet/packages/wallet/exceptions/eip712_schema_drift_exception.dart';

/// One named field in a typed-data type group: `{name, type}`.
class Eip712FieldSpec {
  final String name;
  final String type;
  const Eip712FieldSpec(this.name, this.type);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Eip712FieldSpec && other.name == name && other.type == type);

  @override
  int get hashCode => Object.hash(name, type);

  @override
  String toString() => '{$name: $type}';
}

/// Base class for client-pinned EIP-712 schemas.
///
/// Subclasses are `const` and expose:
///  * a [schemaVersion] string for journal entries (`v1` / `v2` migrations)
///  * a [primaryType] (e.g. `RealUnitUser`, `Delegation`)
///  * a [types] map keyed by EIP-712 type-group name. Every value is the
///    in-order list of `{name, type}` field specs.
///
/// The [validate] entrypoint compares a backend-supplied `types` map against
/// the constant and throws [Eip712SchemaDriftException] on any deviation.
abstract class Eip712Schema {
  const Eip712Schema();

  String get schemaVersion;
  String get primaryType;

  /// Client-pinned type groups. Implementations return a `const` map.
  Map<String, List<Eip712FieldSpec>> get types;

  /// Re-emits the pinned [types] in the wire format the eth_sig_util
  /// V4 signer expects: a `Map<String, List<Map<String, String>>>`.
  ///
  /// Centralising this means callsites build the typed-data envelope from
  /// the **schema constant**, not from the backend response — closes F-038
  /// at the construction site, not just the validate site.
  Map<String, List<Map<String, String>>> typesAsJson() {
    return {
      for (final entry in types.entries)
        entry.key: [
          for (final field in entry.value) {'name': field.name, 'type': field.type},
        ],
    };
  }

  /// Throws [Eip712SchemaDriftException] when [backendTypes] does NOT match
  /// the pinned [types] byte-equal (order-sensitive, name-sensitive,
  /// type-sensitive, top-level-name-sensitive).
  ///
  /// [backendTypes] is the raw map decoded from the backend response. The
  /// type-group lists may contain `Map<String, dynamic>` or
  /// `Map<String, String>`; both shapes are accepted as long as each entry
  /// has exactly `name` and `type` keys with string values.
  void validate(Map<String, dynamic> backendTypes) {
    // Top-level groups must match by name (order-insensitive on the group
    // level; only field order inside a group matters for EIP-712 hashing).
    final pinnedGroups = types.keys.toSet();
    final backendGroups = backendTypes.keys.toSet();

    final extra = backendGroups.difference(pinnedGroups);
    if (extra.isNotEmpty) {
      throw Eip712SchemaDriftException(
        driftedField: extra.first,
        schemaVersion: schemaVersion,
        reason: 'extra type group: ${extra.first}',
      );
    }
    final missing = pinnedGroups.difference(backendGroups);
    if (missing.isNotEmpty) {
      throw Eip712SchemaDriftException(
        driftedField: missing.first,
        schemaVersion: schemaVersion,
        reason: 'missing type group: ${missing.first}',
      );
    }

    for (final group in types.keys) {
      final pinned = types[group]!;
      final raw = backendTypes[group];
      if (raw is! List) {
        throw Eip712SchemaDriftException(
          driftedField: group,
          schemaVersion: schemaVersion,
          reason: 'type group "$group" is not a list',
        );
      }
      if (raw.length != pinned.length) {
        throw Eip712SchemaDriftException(
          driftedField: group,
          schemaVersion: schemaVersion,
          reason:
              'type group "$group" has ${raw.length} fields, expected ${pinned.length}',
        );
      }
      for (var i = 0; i < pinned.length; i++) {
        final entry = raw[i];
        if (entry is! Map) {
          throw Eip712SchemaDriftException(
            driftedField: '$group[$i]',
            schemaVersion: schemaVersion,
            reason: 'field $i in "$group" is not a {name,type} map',
          );
        }
        final name = entry['name'];
        final type = entry['type'];
        if (name is! String || type is! String) {
          throw Eip712SchemaDriftException(
            driftedField: '$group[$i]',
            schemaVersion: schemaVersion,
            reason: 'field $i in "$group" has non-string name/type',
          );
        }
        if (entry.length != 2) {
          // Extra keys (e.g. `internalType` from solc output) would change
          // the JSON the backend signs but be invisible in the visible
          // envelope. Refuse anything beyond exactly {name, type}.
          throw Eip712SchemaDriftException(
            driftedField: '$group[$i].${entry.keys.where((k) => k != 'name' && k != 'type').first}',
            schemaVersion: schemaVersion,
            reason: 'field $i in "$group" has extra keys beyond {name,type}',
          );
        }
        final expected = pinned[i];
        if (name != expected.name) {
          throw Eip712SchemaDriftException(
            driftedField: '$group[$i].name',
            schemaVersion: schemaVersion,
            reason: 'field $i in "$group" name "$name" != pinned "${expected.name}"',
          );
        }
        if (type != expected.type) {
          throw Eip712SchemaDriftException(
            driftedField: '$group[$i].type',
            schemaVersion: schemaVersion,
            reason:
                'field "$name" in "$group" type "$type" != pinned "${expected.type}"',
          );
        }
      }
    }
  }
}
