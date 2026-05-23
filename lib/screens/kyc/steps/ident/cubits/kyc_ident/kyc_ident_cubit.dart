import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_idensic_mobile_sdk_plugin/flutter_idensic_mobile_sdk_plugin.dart';
import 'package:realunit_wallet/screens/kyc/steps/ident/cubits/kyc_ident/sumsub_ident_port.dart';

part 'kyc_ident_state.dart';

enum FailureStatus { error, finallyRejected, temporarilyDeclined, failed }

class KycIdentCubit extends Cubit<KycIdentState> {
  KycIdentCubit({required SumsubIdentPort identPort})
    : _identPort = identPort,
      super(const KycIdentInitial());

  final SumsubIdentPort _identPort;

  Future<void> startIdent(String token, {String localeCode = 'en'}) async {
    try {
      emit(const KycIdentLoading());
      final result = await _identPort.launch(token: token, localeCode: localeCode);
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
}
