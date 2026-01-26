import 'dart:developer' as developer;

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:realunit_wallet/packages/service/dfx/models/registration/registration_email_status.dart';
import 'package:realunit_wallet/packages/service/dfx/real_unit_registration_service.dart';

part 'registration_email_step_state.dart';

class RegistrationEmailStepCubit extends Cubit<RegistrationEmailStepState> {
  final RealUnitRegistrationService _service;

  RegistrationEmailStepCubit(RealUnitRegistrationService service)
      : _service = service,
        super(RegistrationEmailStepInitial());

  Future<void> checkEmail(String email) async {
    try {
      emit(RegistrationEmailStepLoading());
      final status = await _service.registerEmail(email);

      emit(RegistrationEmailStepSuccess(status));
    } catch (e) {
      developer.log(e.toString());
      emit(RegistrationEmailStepFailure(e.toString()));
    }
  }
}
