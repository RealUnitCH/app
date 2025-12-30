import 'dart:developer' as developer;

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:realunit_wallet/packages/service/dfx/dfx_registration_service.dart';
import 'package:realunit_wallet/packages/service/dfx/models/registration/dfx_registration.dart';
import 'package:realunit_wallet/packages/service/dfx/models/registration/dfx_registration_status.dart';

part 'registration_submit_state.dart';

class RegistrationSubmitCubit extends Cubit<RegistrationSubmitState> {
  final DfxRegistrationService _service;

  RegistrationSubmitCubit(this._service) : super(RegistrationSubmitInitial());

  Future<void> submit(DfxRegistration registration) async {
    try {
      emit(RegistrationSubmitLoading());
      final response = await _service.register(registration);

      emit(RegistrationSubmitSuccess(response.status));
    } catch (e) {
      developer.log(e.toString());
      emit(RegistrationSubmitFailure(e.toString()));
    }
  }
}
