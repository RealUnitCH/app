import 'dart:developer' as developer;

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:realunit_wallet/packages/service/dfx/exceptions/api_exception.dart';
import 'package:realunit_wallet/packages/service/dfx/exceptions/request_timeout_exception.dart';
import 'package:realunit_wallet/packages/service/dfx/models/registration/registration_email_status.dart';
import 'package:realunit_wallet/packages/service/dfx/real_unit_registration_service.dart';

part 'kyc_email_step_state.dart';

class KycEmailStepCubit extends Cubit<KycEmailStepState> {
  final RealUnitRegistrationService _service;

  // True while register/email runs. A second tap before the button rebuilds is
  // ignored, so no second code or merge mail is requested.
  bool _inFlight = false;

  KycEmailStepCubit(RealUnitRegistrationService service)
    : _service = service,
      super(const KycEmailStepInitial());

  Future<void> registerEmail(String email) async {
    if (_inFlight) return;
    _inFlight = true;
    try {
      emit(const KycEmailStepLoading());
      final status = await _service.registerEmail(email);
      // The page closes the cubit when the user leaves while the call runs.
      if (isClosed) return;

      if (status == RegistrationEmailStatus.verificationCodeSent) {
        emit(KycEmailStepCodeSent(email));
        return;
      }
      emit(KycEmailStepSuccess(status));
    } on ApiException catch (e) {
      developer.log(e.toString());
      if (isClosed) return;
      emit(
        KycEmailStepFailure(
          e.message.contains('does not match verified email')
              ? KycEmailStepError.emailDoesNotMatch
              : KycEmailStepError.unknown,
          e.message,
        ),
      );
    } catch (e) {
      developer.log(e.toString());
      if (isClosed) return;
      // The server did not answer in time (the request was sent); the page
      // shows its own sentence for it. Other failures keep their text.
      emit(
        e is RequestTimeoutException
            ? const KycEmailStepFailure(KycEmailStepError.timeout, '')
            : KycEmailStepFailure(KycEmailStepError.unknown, e.toString()),
      );
    } finally {
      _inFlight = false;
    }
  }
}
