import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:realunit_wallet/packages/service/dfx/dfx_kyc_service.dart';

part 'settings_edit_phone_number_state.dart';

class SettingsEditPhoneNumberCubit extends Cubit<SettingsEditPhoneNumberState> {
  final DfxKycService _kycService;

  SettingsEditPhoneNumberCubit({required DfxKycService kycService})
    : _kycService = kycService,
      super(const PhoneChangeInitial());

  Future<void> submitPhone(String phone) async {
    try {
      emit(const PhoneChangeSubmitting());
      await _kycService.updateUser({'phone': phone});
      emit(const PhoneChangeSuccess());
    } catch (e) {
      emit(PhoneChangeFailure(e.toString()));
    }
  }
}
