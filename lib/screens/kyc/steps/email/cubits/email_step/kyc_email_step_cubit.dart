import 'dart:developer' as developer;

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:realunit_wallet/packages/service/dfx/exceptions/api_exception.dart';
import 'package:realunit_wallet/packages/service/dfx/models/registration/registration_email_status.dart';
import 'package:realunit_wallet/packages/service/dfx/real_unit_registration_service.dart';

part 'kyc_email_step_state.dart';

class KycEmailStepCubit extends Cubit<KycEmailStepState> {
  final RealUnitRegistrationService _service;

  KycEmailStepCubit(RealUnitRegistrationService service)
    : _service = service,
      super(const KycEmailStepInitial());

  Future<void> registerEmail(String email) async {
    try {
      emit(const KycEmailStepLoading());
      final status = await _service.registerEmail(email);

      emit(KycEmailStepSuccess(status));
    } on ApiException catch (e) {
      developer.log(e.toString());
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
      emit(
        KycEmailStepFailure(
          KycEmailStepError.unknown,
          e.toString(),
        ),
      );
    }
  }
}
