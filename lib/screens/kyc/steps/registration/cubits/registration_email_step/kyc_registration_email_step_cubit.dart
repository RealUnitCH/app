import 'dart:developer' as developer;

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:realunit_wallet/packages/service/dfx/models/registration/registration_email_status.dart';
import 'package:realunit_wallet/packages/service/dfx/real_unit_registration_service.dart';

part 'kyc_registration_email_step_state.dart';

class KycRegistrationEmailStepCubit extends Cubit<KycRegistrationEmailStepState> {
  final RealUnitRegistrationService _service;

  KycRegistrationEmailStepCubit(RealUnitRegistrationService service)
      : _service = service,
        super(const KycRegistrationEmailStepInitial());

  Future<void> checkEmail(String email) async {
    try {
      emit(const KycRegistrationEmailStepLoading());
      final status = await _service.registerEmail(email);

      emit(KycRegistrationEmailStepSuccess(status));
    } catch (e) {
      developer.log(e.toString());
      emit(KycRegistrationEmailStepFailure(e.toString()));
    }
  }
}
