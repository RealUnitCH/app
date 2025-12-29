import 'dart:developer' as developer;

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:realunit_wallet/packages/service/dfx/dfx_registration_service.dart';
import 'package:realunit_wallet/packages/service/dfx/models/registration/dfx_registration.dart';

part 'kyc_submit_state.dart';

class KycSubmitCubit extends Cubit<KycSubmitState> {
  final DfxRegistrationService _service;

  KycSubmitCubit(this._service) : super(KycSubmitState.initial);

  Future<void> submit(DfxRegistration registration) async {
    try {
      emit(KycSubmitState.loading);
      final response = await _service.register(registration);

      developer.log('Registration successful! Response: ${response.toString()}');
      developer.log(response.status.toString());
      emit(KycSubmitState.successful);
    } catch (e) {
      emit(KycSubmitState.failed);
      developer.log(e.toString());
    }
  }
}
