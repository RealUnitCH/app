import 'dart:developer' as developer;

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:realunit_wallet/packages/service/dfx/dfx_kyc_service.dart';
import 'package:realunit_wallet/packages/service/dfx/exceptions/api_exception.dart';
import 'package:realunit_wallet/packages/service/dfx/models/user/dto/user_dto.dart';

part 'settings_contact_state.dart';

class SettingsContactCubit extends Cubit<SettingsContactState> {
  final DfxKycService _kycService;

  SettingsContactCubit(DfxKycService kycService)
    : _kycService = kycService,
      super(const SettingsContactInitial());

  Future<void> init() async {
    try {
      emit(const SettingsContactLoading());
      final user = await _kycService.getUser();
      emit(
        SettingsContactSuccess(
          capability: user.capabilities.createSupportTicket,
        ),
      );
    } on ApiException catch (e) {
      developer.log(e.toString());
      emit(SettingsContactFailure(message: e.message));
    } catch (e) {
      developer.log(e.toString());
      emit(SettingsContactFailure(message: e.toString()));
    }
  }
}
