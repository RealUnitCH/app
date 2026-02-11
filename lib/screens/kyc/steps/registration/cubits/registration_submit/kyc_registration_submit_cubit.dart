import 'dart:developer' as developer;

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:realunit_wallet/packages/service/dfx/models/registration/registration.dart';
import 'package:realunit_wallet/packages/service/dfx/models/registration/registration_status.dart';
import 'package:realunit_wallet/packages/service/dfx/real_unit_registration_service.dart';

part 'kyc_registration_submit_state.dart';

class KycRegistrationSubmitCubit extends Cubit<KycRegistrationSubmitState> {
  final RealUnitRegistrationService _service;

  KycRegistrationSubmitCubit(RealUnitRegistrationService service)
      : _service = service,
        super(KycRegistrationSubmitInitial());

  Future<void> submit(Registration registration) async {
    try {
      emit(KycRegistrationSubmitLoading());
      final status = await _service.completeRegistration(registration);

      emit(KycRegistrationSubmitSuccess(status));
    } catch (e) {
      developer.log(e.toString());
      emit(KycRegistrationSubmitFailure(e.toString()));
    }
  }
}
