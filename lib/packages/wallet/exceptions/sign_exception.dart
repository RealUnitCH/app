// Typed exception hierarchy root for the SignPipeline.
//
// Every error path that can come out of the pipeline (validation,
// romanisation, schema-drift, BitBox plugin, EIP-1559 type-byte mismatch)
// is a [SignException] subclass with an [arbKey] string. Cubits switch on
// the type and use [arbKey] to fetch the user-visible string from i18n —
// no `e.toString()` string-matching anywhere (the cause of F-016 / F-020 /
// F-021 etc.).
//
// Why `abstract class` and not `sealed`: Dart 3 sealed classes require all
// subclasses in the same library. The BitBox-side typed exceptions and the
// schema-drift exception live in `exceptions/` for import-graph reasons,
// while the ErrorMapper consolidates them; sealed would force a single
// file and we explicitly chose layered files. The exhaustiveness contract
// is enforced by the `ErrorMapper`'s exhaustive-test, not by the language.

/// Base of the SignPipeline typed exception hierarchy.
abstract class SignException implements Exception {
  const SignException();

  /// i18n ARB key used by cubits to render the user-visible message.
  ///
  /// Convention: keys live under `strings_*.arb` namespaced as
  /// `errorBitbox*` / `errorEip712*` / `errorEip7702*` / `errorEip1559*`.
  /// The exhaustive ErrorMapper test asserts every concrete subclass has a
  /// non-empty ARB key — see `test/packages/wallet/error_mapper_test.dart`.
  String get arbKey;
}
