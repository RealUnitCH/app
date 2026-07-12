import 'package:flutter_idensic_mobile_sdk_plugin/flutter_idensic_mobile_sdk_plugin.dart';

/// Boundary around the Sumsub `flutter_idensic_mobile_sdk_plugin` so that
/// [KycIdentCubit] can be exercised in unit tests without instantiating the
/// real native SDK builder.
///
/// Implementations are responsible for launching the Sumsub mobile flow and
/// returning the SDK's terminal [SNSMobileSDKResult]. The cubit owns the
/// state-mapping logic (`status -> KycIdentState`), so the port intentionally
/// stays a thin pass-through on the SDK return value rather than introducing a
/// parallel result type.
///
/// The production implementation lives at
/// `lib/screens/kyc/steps/ident/sumsub_ident_sdk_adapter.dart` — kept outside
/// the cubit folder so the SDK-side adapter sits outside the cubit coverage
/// scope (`lib/screens/*/cubits/*` in `.github/workflows/pull-request.yaml`),
/// matching its `@no-integration-test` status.
abstract class SumsubIdentPort {
  /// Launches a Sumsub identity verification flow using [token] and
  /// localises the in-flow UI via [localeCode] (e.g. `'en'`, `'de'`).
  ///
  /// Resolves with the SDK's terminal result. Throws if the SDK itself throws
  /// (for example when the access token expires mid-session and no fresh one
  /// can be obtained).
  Future<SNSMobileSDKResult> launch({
    required String token,
    required String localeCode,
  });
}
