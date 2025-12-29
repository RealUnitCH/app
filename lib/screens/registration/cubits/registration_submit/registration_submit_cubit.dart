import 'dart:developer' as developer;

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:realunit_wallet/packages/service/dfx/dfx_registration_service.dart';
import 'package:realunit_wallet/packages/service/dfx/models/registration/dfx_registration.dart';

part 'registration_submit_state.dart';

class RegistrationSubmitCubit extends Cubit<RegistrationSubmitState> {
  final DfxRegistrationService _service;

  RegistrationSubmitCubit(this._service) : super(RegistrationSubmitState.initial);

  Future<void> submit(DfxRegistration registration) async {
    try {
      emit(RegistrationSubmitState.loading);
      final response = await _service.register(registration);

      developer.log('Registration successful! Response: ${response.toString()}');
      developer.log(response.status.toString());
      emit(RegistrationSubmitState.successful);
    } catch (e) {
      emit(RegistrationSubmitState.failed);
      developer.log(e.toString());
    }
  }
}
