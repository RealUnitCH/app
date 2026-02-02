import 'dart:developer' as developer;

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:realunit_wallet/packages/service/dfx/models/registration/registration.dart';
import 'package:realunit_wallet/packages/service/dfx/models/registration/registration_status.dart';
import 'package:realunit_wallet/packages/service/dfx/real_unit_registration_service.dart';

part 'registration_submit_state.dart';

class RegistrationSubmitCubit extends Cubit<RegistrationSubmitState> {
  final RealUnitRegistrationService _service;

  RegistrationSubmitCubit(RealUnitRegistrationService service)
      : _service = service,
        super(RegistrationSubmitInitial());

  Future<void> submit(Registration registration) async {
    try {
      emit(RegistrationSubmitLoading());
      final status = await _service.completeRegistration(registration);

      emit(RegistrationSubmitSuccess(status));
    } catch (e) {
      developer.log(e.toString());
      emit(RegistrationSubmitFailure(e.toString()));
    }
  }
}
