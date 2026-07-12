import 'dart:developer' as developer;

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:realunit_wallet/packages/service/dfx/exceptions/api_exception.dart';
import 'package:realunit_wallet/packages/service/dfx/models/registration/registration_email_status.dart';
import 'package:realunit_wallet/packages/service/dfx/real_unit_registration_service.dart';

part 'support_email_capture_state.dart';

class SupportEmailCaptureCubit extends Cubit<SupportEmailCaptureState> {
  final RealUnitRegistrationService _service;

  SupportEmailCaptureCubit(RealUnitRegistrationService service)
    : _service = service,
      super(const SupportEmailCaptureInitial());

  Future<void> submit(String email) async {
    try {
      emit(const SupportEmailCaptureLoading());
      final status = await _service.registerEmail(email);

      switch (status) {
        case RegistrationEmailStatus.emailRegistered:
          emit(const SupportEmailCaptureSuccess());
        case RegistrationEmailStatus.mergeRequested:
          // The email-merge resolution path is a multi-step
          // verification flow we don't want to drag into this minimal
          // capture page. The user is told to pick a different
          // address or contact support by email instead.
          emit(
            const SupportEmailCaptureFailure(
              error: SupportEmailCaptureError.mergeRequested,
              message: '',
            ),
          );
      }
    } on ApiException catch (e) {
      developer.log(e.toString());
      emit(
        SupportEmailCaptureFailure(
          error: SupportEmailCaptureError.unknown,
          message: e.message,
        ),
      );
    } catch (e) {
      developer.log(e.toString());
      emit(
        SupportEmailCaptureFailure(
          error: SupportEmailCaptureError.unknown,
          message: e.toString(),
        ),
      );
    }
  }
}
