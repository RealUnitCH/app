import 'dart:developer';

import 'package:equatable/equatable.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_idensic_mobile_sdk_plugin/flutter_idensic_mobile_sdk_plugin.dart';

part 'kyc_ident_state.dart';

enum FailureStatus { error, finallyRejected, temporarilyDeclined, failed }

class KycIdentCubit extends Cubit<KycIdentState> {
  KycIdentCubit() : super(const KycIdentInitial());

  Future<void> startIdent(String token, {String localeCode = 'en'}) async {
    try {
      emit(const KycIdentLoading());
      var result = await _launchSDK(token, localeCode);
      switch (result.status) {
        case SNSMobileSDKStatus.Approved:
          // Equivalent to web: reviewAnswer === GREEN
          emit(const KycIdentSuccess());
          break;

        case SNSMobileSDKStatus.ActionCompleted:
          emit(const KycIdentSuccess());
          break;

        case SNSMobileSDKStatus.Pending:
          emit(const KycIdentSuccess());
          break;

        case SNSMobileSDKStatus.FinallyRejected:
          // Equivalent to web: reviewAnswer === RED && reviewRejectType === FINAL
          emit(
            const KycIdentFailure(
              status: FailureStatus.finallyRejected,
            ),
          );
          break;

        case SNSMobileSDKStatus.TemporarilyDeclined:
          // Equivalent to web: reviewAnswer === RED && reviewRejectType === RETRY
          emit(
            const KycIdentFailure(
              status: FailureStatus.temporarilyDeclined,
            ),
          );
          break;

        case SNSMobileSDKStatus.Failed:
          emit(
            const KycIdentFailure(
              status: FailureStatus.failed,
            ),
          );
          break;

        default:
          // Incomplete, Initial, or user cancelled
          emit(const KycIdentInitial());
      }
    } catch (e) {
      emit(
        KycIdentFailure(
          status: FailureStatus.error,
          errorMessage: e.toString(),
        ),
      );
    }
  }

  Future<SNSMobileSDKResult> _launchSDK(String token, String locale) async {
    // The access token has a limited lifespan and when it's expired, you must provide another one.
    Future<String> onTokenExpiration() async {
      throw Exception('Token expired. Please open a new ident session to get a new token.');
    }

    onStatusChanged(SNSMobileSDKStatus newStatus, SNSMobileSDKStatus prevStatus) {
      log('The SDK status was changed: $prevStatus -> $newStatus');
    }

    final snsMobileSDK = SNSMobileSDK.init(token, onTokenExpiration)
        .withHandlers(onStatusChanged: onStatusChanged)
        .withLocale(
          Locale(locale),
        )
        .build();

    final SNSMobileSDKResult result = await snsMobileSDK.launch();
    log('Completed with result: $result');
    return result;
  }
}
