import 'dart:developer';

import 'package:flutter/widgets.dart';
import 'package:flutter_idensic_mobile_sdk_plugin/flutter_idensic_mobile_sdk_plugin.dart';
import 'package:realunit_wallet/screens/kyc/steps/ident/cubits/kyc_ident/sumsub_ident_port.dart';

/// Default [SumsubIdentPort] implementation that drives the real
/// `flutter_idensic_mobile_sdk_plugin`.
///
/// This is the only place in the codebase that constructs an [SNSMobileSDK]
/// instance, so unit tests for [KycIdentCubit] never touch the native plugin.
/// The adapter sits outside `cubits/` on purpose: the cubit coverage scope in
/// `.github/workflows/pull-request.yaml` (`lib/screens/*/cubits/*`) does not
/// match this path, which reflects the `@no-integration-test` annotation
/// below.
///
/// @no-integration-test: the Sumsub SDK requires a real device flow and is not
/// exercisable from the headless `flutter_test` harness; coverage is provided
/// by the cubit-level fake port and by manual QA against the live Sumsub
/// staging environment.
class SumsubIdentSdkAdapter implements SumsubIdentPort {
  const SumsubIdentSdkAdapter();

  @override
  Future<SNSMobileSDKResult> launch({
    required String token,
    required String localeCode,
  }) async {
    // The access token has a limited lifespan and when it's expired, you must
    // provide another one. We surface this as a thrown exception so the cubit
    // maps it to a [FailureStatus.error] state — the user then has to open a
    // fresh ident session to retry.
    Future<String> onTokenExpiration() async {
      throw Exception(
        'Token expired. Please open a new ident session to get a new token.',
      );
    }

    void onStatusChanged(
      SNSMobileSDKStatus newStatus,
      SNSMobileSDKStatus prevStatus,
    ) {
      log('The SDK status was changed: $prevStatus -> $newStatus');
    }

    final snsMobileSDK = SNSMobileSDK.init(
      token,
      onTokenExpiration,
    ).withHandlers(onStatusChanged: onStatusChanged).withLocale(Locale(localeCode)).build();

    final SNSMobileSDKResult result = await snsMobileSDK.launch();
    log('Completed with result: $result');
    return result;
  }
}
