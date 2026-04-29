import 'dart:developer' as developer;

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:realunit_wallet/packages/service/dfx/dfx_kyc_service.dart';

part 'settings_contact_state.dart';

class SettingsContactCubit extends Cubit<SettingsContactState> {
  final DfxKycService _kycService;

  SettingsContactCubit(DfxKycService kycService)
    : _kycService = kycService,
      super(const SettingsContactInitial()) {
    init();
  }

  Future<void> init() async {
    try {
      emit(const SettingsContactLoading());
      final userDto = await _kycService.getUser();
      emit(SettingsContactSuccess(emailSet: userDto.mail != null));
    } catch (e) {
      developer.log(e.toString(), name: '$SettingsContactCubit');
      emit(SettingsContactFailure(message: e.toString()));
    }
  }
}
