// Forward-declared schema-drift exception.
//
// Kept in its own file because `Eip712Schema.validate` needs to throw it,
// and `ErrorMapper` needs to import it as part of the typed `SignException`
// hierarchy. Defining it in either location alone would create an import
// cycle through `error_mapper.dart`. Re-exported from there for callers
// that already import the ErrorMapper.

import 'package:realunit_wallet/packages/wallet/exceptions/sign_exception.dart';

/// Raised when a backend-supplied EIP-712 `types` map deviates from the
/// client-pinned [Eip712Schema] constant — the central defence against
/// F-038 / F-039 (Initiative II).
///
/// [driftedField] points at the first deviation found (e.g. `Delegation[3].type`
/// or `Caveat`). [schemaVersion] identifies which client schema rejected
/// the response so the journal entry has enough context to plan the
/// migration. [reason] is a short human-readable description; consumers
/// should NOT pattern-match on it (it is a debug aid, not an API).
class Eip712SchemaDriftException extends SignException {
  final String driftedField;
  final String schemaVersion;
  final String reason;

  const Eip712SchemaDriftException({
    required this.driftedField,
    required this.schemaVersion,
    required this.reason,
  });

  @override
  String get arbKey => 'errorEip712SchemaDrift';

  @override
  String toString() =>
      'Eip712SchemaDriftException(field=$driftedField, schema=$schemaVersion, reason=$reason)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Eip712SchemaDriftException &&
          other.driftedField == driftedField &&
          other.schemaVersion == schemaVersion &&
          other.reason == reason);

  @override
  int get hashCode => Object.hash(driftedField, schemaVersion, reason);
}
