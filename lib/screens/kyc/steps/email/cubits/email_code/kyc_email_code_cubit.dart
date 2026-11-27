import 'dart:developer' as developer;

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:realunit_wallet/packages/service/dfx/exceptions/api_exception.dart';
import 'package:realunit_wallet/packages/service/dfx/models/registration/registration_email_status.dart';
import 'package:realunit_wallet/packages/service/dfx/real_unit_registration_service.dart';

part 'kyc_email_code_state.dart';

/// Confirms the code that `register/email` sent to [email] and then calls
/// `register/email` again, which the API answers with the final status once
/// the address is proven.
class KycEmailCodeCubit extends Cubit<KycEmailCodeState> {
  final RealUnitRegistrationService _service;
  final String email;

  // Set once the API accepted the code. The code is used up by then, so a
  // retry after a failed second `register/email` call must not send it again.
  bool _codeConfirmed = false;

  // Set when a confirmation got no API answer: the server may still have accepted the
  // code, so a 403 on a later try can mean "already used" and is settled
  // through register/email instead of being shown as a wrong code. Cleared
  // only by a definitive answer: an accepted code, a wrong code, or a
  // register/email answer (which proves the address or sends a new code).
  bool _confirmationUnknown = false;

  // True while verify or resend runs. A second tap before the buttons rebuild
  // is ignored, so a code is not confirmed twice and no second code is sent.
  bool _inFlight = false;

  KycEmailCodeCubit(RealUnitRegistrationService service, {required this.email})
    : _service = service,
      super(const KycEmailCodeInitial());

  // The page closes the cubit when the user leaves; a request still in flight
  // then must not emit (every emit below follows an await). An accepted code
  // still gets its finishing register/email call, which completes the step.
  Future<void> verify(String code) async {
    if (isClosed || _inFlight) return;
    _inFlight = true;
    try {
      await _verify(code);
    } finally {
      _inFlight = false;
    }
  }

  /// Requests a new code: `register/email` sends one while the address is not
  /// proven yet.
  Future<void> resend() async {
    if (isClosed || _inFlight) return;
    _inFlight = true;
    try {
      emit(const KycEmailCodeResending());
      await _registerEmail();
    } finally {
      _inFlight = false;
    }
  }

  Future<void> _verify(String code) async {
    emit(const KycEmailCodeVerifying());
    if (!_codeConfirmed) {
      try {
        await _service.verifyEmail(code);
        _codeConfirmed = true;
        _confirmationUnknown = false;
      } on ApiException catch (e) {
        developer.log(e.toString());
        // 409: another account holds the address. The API checks that only
        // after it accepted (and used up) the code, so a retry must not send
        // it again: treat it like an accepted code.
        if (e.statusCode == 409) {
          _codeConfirmed = true;
          _confirmationUnknown = false;
        }
        // In that case, and for a 403 after a timed-out try (which may have
        // used the code), register/email decides the next step
        // (email_registered, merge_requested or a new code) instead of the app
        // reading the error text.
        // This runs even after the page closed: register/email only guards
        // its emits.
        if (e.statusCode == 409 || (e.statusCode == 403 && _confirmationUnknown)) {
          await _registerEmail();
          return;
        }
        if (isClosed) return;
        // The API answers a wrong, expired or used-up code with 403.
        if (e.statusCode == 403) {
          emit(const KycEmailCodeFailure(KycEmailCodeError.invalidCode));
          return;
        }
        emit(const KycEmailCodeFailure(KycEmailCodeError.unknown));
        return;
      } catch (e) {
        developer.log(e.toString());
        // No API answer (timeout, dropped connection): the request may have
        // reached the server and used the code. Treated as unknown, so a later
        // 403 is settled through register/email; if the failure happened
        // before sending, that costs at most a new code.
        _confirmationUnknown = true;
        if (isClosed) return;
        emit(const KycEmailCodeFailure(KycEmailCodeError.unknown));
        return;
      }
    }
    await _registerEmail();
  }

  Future<void> _registerEmail() async {
    try {
      final status = await _service.registerEmail(email);
      // Any answer settles a possibly used code: the address is proven, a
      // merge was requested, or a new code was sent.
      _confirmationUnknown = false;
      if (status == RegistrationEmailStatus.verificationCodeSent) {
        // The address is still not proven, so the API sent a new code.
        _codeConfirmed = false;
      }
      if (isClosed) return;
      if (status == RegistrationEmailStatus.verificationCodeSent) {
        emit(const KycEmailCodeResent());
        return;
      }
      emit(KycEmailCodeCompleted(status));
    } catch (e) {
      // API and transport errors alike: the page shows its localized generic
      // sentence, never the raw error text.
      developer.log(e.toString());
      if (isClosed) return;
      emit(const KycEmailCodeFailure(KycEmailCodeError.unknown));
    }
  }
}
