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

  KycEmailCodeCubit(RealUnitRegistrationService service, {required this.email})
    : _service = service,
      super(const KycEmailCodeInitial());

  Future<void> verify(String code) async {
    emit(const KycEmailCodeVerifying());
    if (!_codeConfirmed) {
      try {
        await _service.verifyEmail(code);
        _codeConfirmed = true;
      } on ApiException catch (e) {
        developer.log(e.toString());
        // The API answers a wrong, expired or used-up code with 403.
        if (e.statusCode == 403) {
          emit(const KycEmailCodeFailure(KycEmailCodeError.invalidCode));
          return;
        }
        // Another account holds the address: the API sent an account-merge
        // confirmation mail instead of storing it.
        if (e.statusCode == 409 && e.message.contains('account merge request sent')) {
          emit(const KycEmailCodeCompleted(RegistrationEmailStatus.mergeRequested));
          return;
        }
        emit(KycEmailCodeFailure(KycEmailCodeError.unknown, message: ApiException.userFacingMessage(e)));
        return;
      } catch (e) {
        developer.log(e.toString());
        emit(KycEmailCodeFailure(KycEmailCodeError.unknown, message: e.toString()));
        return;
      }
    }
    await _registerEmail();
  }

  /// Requests a new code: `register/email` sends one while the address is not
  /// proven yet.
  Future<void> resend() async {
    emit(const KycEmailCodeResending());
    await _registerEmail();
  }

  Future<void> _registerEmail() async {
    try {
      final status = await _service.registerEmail(email);
      if (status == RegistrationEmailStatus.verificationCodeSent) {
        // The address is still not proven, so the API sent a new code.
        _codeConfirmed = false;
        emit(const KycEmailCodeResent());
        return;
      }
      emit(KycEmailCodeCompleted(status));
    } on ApiException catch (e) {
      developer.log(e.toString());
      emit(KycEmailCodeFailure(KycEmailCodeError.unknown, message: ApiException.userFacingMessage(e)));
    } catch (e) {
      developer.log(e.toString());
      emit(KycEmailCodeFailure(KycEmailCodeError.unknown, message: e.toString()));
    }
  }
}
