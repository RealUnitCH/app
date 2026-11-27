import 'dart:async';
import 'dart:developer' as developer;

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:realunit_wallet/packages/service/dfx/exceptions/api_exception.dart';
import 'package:realunit_wallet/packages/service/dfx/models/registration/registration_email_status.dart';
import 'package:realunit_wallet/packages/service/dfx/real_unit_registration_service.dart';

part 'support_email_capture_state.dart';

class SupportEmailCaptureCubit extends Cubit<SupportEmailCaptureState> {
  final RealUnitRegistrationService _service;

  // True while register/email runs. A second tap before the button rebuilds is
  // ignored, so no second code or merge mail is requested.
  bool _inFlight = false;

  SupportEmailCaptureCubit(RealUnitRegistrationService service)
    : _service = service,
      super(const SupportEmailCaptureInitial());

  Future<void> submit(String email) async {
    if (_inFlight) return;
    _inFlight = true;
    try {
      emit(const SupportEmailCaptureLoading());
      final status = await _service.registerEmail(email);
      // The page closes the cubit when the user leaves while the call runs.
      if (isClosed) return;

      switch (status) {
        case RegistrationEmailStatus.emailRegistered:
          emit(const SupportEmailCaptureSuccess());
        case RegistrationEmailStatus.mergeRequested:
          // The email is already known to DFX, so the API has sent an
          // account-merge confirmation email. Signal the view to route to the
          // shared email-verification flow so the user can confirm and link
          // this wallet to the existing account.
          emit(const SupportEmailCaptureMergeRequested());
        case RegistrationEmailStatus.verificationCodeSent:
          // The API stores the address only after the code it sent there is
          // confirmed. Signal the view to route to the code entry page.
          emit(SupportEmailCaptureCodeSent(email));
      }
    } on ApiException catch (e) {
      developer.log(e.toString());
      if (isClosed) return;
      emit(SupportEmailCaptureFailure(e.message));
    } catch (e) {
      developer.log(e.toString());
      if (isClosed) return;
      // A timeout has no API text; the page shows its own sentence for it.
      emit(
        e is TimeoutException
            ? const SupportEmailCaptureTimedOut()
            : SupportEmailCaptureFailure(e.toString()),
      );
    } finally {
      _inFlight = false;
    }
  }
}
