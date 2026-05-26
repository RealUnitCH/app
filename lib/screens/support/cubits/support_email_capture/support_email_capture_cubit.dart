import 'dart:developer' as developer;

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:realunit_wallet/packages/service/dfx/exceptions/api_exception.dart';
import 'package:realunit_wallet/packages/service/dfx/real_unit_registration_service.dart';

part 'support_email_capture_state.dart';

/// Minimal email-only registration used as a prerequisite for opening a
/// support ticket. Intentionally NOT coupled to the KYC flow — this is a
/// stand-alone capture page that only needs to land an email on the
/// backend so `POST /v1/support/issue` accepts the next request.
///
/// On success the view pops back to `SupportPage` with `true`; the page's
/// `BlocListener` then chains the original create-ticket navigation.
class SupportEmailCaptureCubit extends Cubit<SupportEmailCaptureState> {
  final RealUnitRegistrationService _registrationService;

  SupportEmailCaptureCubit(RealUnitRegistrationService registrationService)
    : _registrationService = registrationService,
      super(const SupportEmailCaptureInitial());

  Future<void> submit(String email) async {
    emit(const SupportEmailCaptureSubmitting());

    try {
      await _registrationService.registerEmail(email);
      emit(const SupportEmailCaptureSuccess());
    } on ApiException catch (e) {
      developer.log('Email registration failed: ${e.message}', name: '$SupportEmailCaptureCubit');
      emit(SupportEmailCaptureFailure(message: e.message));
    } catch (e) {
      developer.log('Email registration failed: $e', name: '$SupportEmailCaptureCubit');
      emit(SupportEmailCaptureFailure(message: e.toString()));
    }
  }
}
