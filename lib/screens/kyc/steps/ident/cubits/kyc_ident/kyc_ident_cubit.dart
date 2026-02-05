import 'dart:developer' as developer;

import 'package:equatable/equatable.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_idensic_mobile_sdk_plugin/flutter_idensic_mobile_sdk_plugin.dart';

part 'kyc_ident_state.dart';

enum FailureStatus { error, finallyRejected, temporarilyDeclined, failed }

class KycIdentCubit extends Cubit<KycIdentState> {
  KycIdentCubit() : super(KycIdentInitial());

  Future startIdent(String token) async {
    try {
      emit(KycIdentLoading());
      final result = await _launchSDK(token);

      switch (result.status) {
        case SNSMobileSDKStatus.Approved:
          // Equivalent to web: reviewAnswer === GREEN
          emit(KycIdentSuccess());
          break;

        case SNSMobileSDKStatus.ActionCompleted:
          emit(KycIdentSuccess());
          break;

        case SNSMobileSDKStatus.Pending:
          // Verification is pending review
          emit(KycIdentSuccess());
          break;

        case SNSMobileSDKStatus.FinallyRejected:
          // Equivalent to web: reviewAnswer === RED && reviewRejectType === FINAL
          emit(
            const KycIdentFailure(
              status: FailureStatus.finallyRejected,
              errorMessage: 'Verification was rejected',
            ),
          );
          break;

        case SNSMobileSDKStatus.TemporarilyDeclined:
          // Equivalent to web: reviewAnswer === RED && reviewRejectType === RETRY
          emit(
            const KycIdentFailure(
              status: FailureStatus.temporarilyDeclined,
              errorMessage: 'Verification was temporarily declined. Please try again.',
            ),
          );
          break;

        case SNSMobileSDKStatus.Failed:
          emit(
            const KycIdentFailure(
              status: FailureStatus.failed,
              errorMessage: 'Verification failed',
            ),
          );
          break;

        default:
          // Incomplete, Initial, or user cancelled
          emit(KycIdentInitial());
      }
    } catch (e) {
      emit(KycIdentFailure(status: FailureStatus.error, errorMessage: e.toString()));
    }
  }

  Future<SNSMobileSDKResult> _launchSDK(String token) async {
    // From your backend get an access token for the applicant to be verified.
    // The token must be generated with `levelName` and `userId`,
    // where `levelName` is the name of a level configured in your dashboard.
    //
    // The sdk will work in the production or in the sandbox environment
    // depend on which one the `accessToken` has been generated on.
    //

    // The access token has a limited lifespan and when it's expired, you must provide another one.
    // So be prepared to get a new token from your backend.
    Future<String> onTokenExpiration() async {
      // call your backend to fetch a new access token (this is just an example)
      return Future<String>.delayed(const Duration(seconds: 2), () => 'your new access token');
    }

    onStatusChanged(SNSMobileSDKStatus newStatus, SNSMobileSDKStatus prevStatus) {
      developer.log('The SDK status was changed: $prevStatus -> $newStatus');
    }

    final snsMobileSDK = SNSMobileSDK.init(token, onTokenExpiration)
        .withHandlers(onStatusChanged: onStatusChanged)
        .withDebug(true) // set debug mode if required
        .withLocale(
          const Locale('en'),
        ) // optional, for cases when you need to override the system locale
        .build();

    final SNSMobileSDKResult result = await snsMobileSDK.launch();
    developer.log('Completed with result: $result');
    return result;
  }
}
