import 'dart:async';
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

  // Set when a confirmation timed out: the server may still have accepted the
  // code, so a 403 on the next try can mean "already used" and is settled
  // through register/email instead of being shown as a wrong code.
  bool _confirmationUnknown = false;

  KycEmailCodeCubit(RealUnitRegistrationService service, {required this.email})
    : _service = service,
      super(const KycEmailCodeInitial());

  // The page closes the cubit when the user leaves; a request still in flight
  // then must not emit (every emit below follows an await). An accepted code
  // still gets its finishing register/email call, which completes the step.
  Future<void> verify(String code) async {
    if (isClosed) return;
    emit(const KycEmailCodeVerifying());
    if (!_codeConfirmed) {
      try {
        await _service.verifyEmail(code);
        _codeConfirmed = true;
        _confirmationUnknown = false;
      } on ApiException catch (e) {
        developer.log(e.toString());
        if (isClosed) return;
        final confirmationUnknown = _confirmationUnknown;
        _confirmationUnknown = false;
        // 409: another account holds the address. 403 after a timed-out try:
        // that try may have used the code. In both cases register/email
        // decides the next step (email_registered, merge_requested or a new
        // code) instead of the app reading the error text.
        if (e.statusCode == 409 || (e.statusCode == 403 && confirmationUnknown)) {
          await _registerEmail();
          return;
        }
        // The API answers a wrong, expired or used-up code with 403.
        if (e.statusCode == 403) {
          emit(const KycEmailCodeFailure(KycEmailCodeError.invalidCode));
          return;
        }
        emit(KycEmailCodeFailure(KycEmailCodeError.unknown, message: ApiException.userFacingMessage(e)));
        return;
      } catch (e) {
        developer.log(e.toString());
        if (e is TimeoutException) _confirmationUnknown = true;
        if (isClosed) return;
        emit(KycEmailCodeFailure(KycEmailCodeError.unknown, message: _messageOf(e)));
        return;
      }
    }
    await _registerEmail();
  }

  /// Requests a new code: `register/email` sends one while the address is not
  /// proven yet.
  Future<void> resend() async {
    if (isClosed) return;
    emit(const KycEmailCodeResending());
    await _registerEmail();
  }

  Future<void> _registerEmail() async {
    try {
      final status = await _service.registerEmail(email);
      if (isClosed) return;
      if (status == RegistrationEmailStatus.verificationCodeSent) {
        // The address is still not proven, so the API sent a new code.
        _codeConfirmed = false;
        emit(const KycEmailCodeResent());
        return;
      }
      emit(KycEmailCodeCompleted(status));
    } on ApiException catch (e) {
      developer.log(e.toString());
      if (isClosed) return;
      emit(KycEmailCodeFailure(KycEmailCodeError.unknown, message: ApiException.userFacingMessage(e)));
    } catch (e) {
      developer.log(e.toString());
      if (isClosed) return;
      emit(KycEmailCodeFailure(KycEmailCodeError.unknown, message: _messageOf(e)));
    }
  }

  // A timeout has no API text; the page then shows its generic sentence.
  static String _messageOf(Object error) => error is TimeoutException ? '' : error.toString();
}
