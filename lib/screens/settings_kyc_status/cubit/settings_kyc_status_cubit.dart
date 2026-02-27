import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:realunit_wallet/packages/service/dfx/dfx_kyc_service.dart';
import 'package:realunit_wallet/packages/service/dfx/models/kyc/dto/kyc_level_dto.dart';

part 'settings_kyc_status_state.dart';

class SettingsKycStatusCubit extends Cubit<SettingsKycStatusState> {
  final DfxKycService _kycService;

  SettingsKycStatusCubit({required DfxKycService kycService})
    : _kycService = kycService,
      super(const SettingsKycStatusInitial());

  Future<void> getKycStatus() async {
    emit(const SettingsKycStatusLoading());
    try {
      final dto = await _kycService.getKycStatus();
      emit(SettingsKycStatusSuccess(dto: dto));
    } catch (e) {
      emit(SettingsKycStatusFailure(e.toString()));
    }
  }
}
