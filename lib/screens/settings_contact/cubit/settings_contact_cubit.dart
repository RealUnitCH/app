import 'dart:developer' as developer;

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:realunit_wallet/packages/service/dfx/dfx_company_info_service.dart';
import 'package:realunit_wallet/packages/service/dfx/dfx_kyc_service.dart';
import 'package:realunit_wallet/packages/service/dfx/models/company_info/dto/dfx_company_info_dto.dart';

part 'settings_contact_state.dart';

class SettingsContactCubit extends Cubit<SettingsContactState> {
  // Brand to look up in /v1/company-info. The realunit-app is the
  // RealUnit brand; future white-labels would pass a different string.
  static const _brand = 'RealUnit';

  final DfxKycService _kycService;
  final DfxCompanyInfoService _companyInfoService;

  SettingsContactCubit(
    DfxKycService kycService,
    DfxCompanyInfoService companyInfoService,
  ) : _kycService = kycService,
      _companyInfoService = companyInfoService,
      super(const SettingsContactInitial()) {
    init();
  }

  Future<void> init() async {
    try {
      emit(const SettingsContactLoading());
      final userDto = await _kycService.getUser();
      final companyInfo = await _companyInfoService.getForBrand(_brand);
      // Render Support directly from the backend's capability flag
      // (`UserCapabilitiesDto.supportAvailable`) instead of inferring
      // it from `mail != null`. The flag and the mail check happen to
      // coincide today, but the API is the authority.
      emit(
        SettingsContactSuccess(
          supportAvailable: userDto.capabilities.supportAvailable,
          companyInfo: companyInfo,
        ),
      );
    } catch (e) {
      developer.log(e.toString(), name: '$SettingsContactCubit');
      emit(SettingsContactFailure(message: e.toString()));
    }
  }
}
