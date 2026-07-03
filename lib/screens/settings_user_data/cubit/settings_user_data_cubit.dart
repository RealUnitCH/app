import 'dart:developer' as developer;

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:realunit_wallet/packages/service/dfx/dfx_country_service.dart';
import 'package:realunit_wallet/packages/service/dfx/dfx_kyc_service.dart';
import 'package:realunit_wallet/packages/service/dfx/exceptions/bitbox_exception.dart';
import 'package:realunit_wallet/packages/service/dfx/models/kyc/dto/kyc_level_dto.dart';
import 'package:realunit_wallet/packages/service/dfx/models/kyc/kyc_level.dart';
import 'package:realunit_wallet/packages/service/dfx/models/registration/registration_user_type.dart';
import 'package:realunit_wallet/packages/service/dfx/models/user/dto/user_dto.dart';
import 'package:realunit_wallet/packages/service/dfx/models/user/user_data.dart';
import 'package:realunit_wallet/packages/service/dfx/models/wallet/real_unit_registration_info_dto.dart';
import 'package:realunit_wallet/packages/service/dfx/real_unit_registration_service.dart';

part 'settings_user_data_state.dart';

class SettingsUserDataCubit extends Cubit<SettingsUserDataState> {
  static const _changeStepNames = {
    KycStepName.nameChange,
    KycStepName.addressChange,
    KycStepName.phoneChange,
  };

  final RealUnitRegistrationService _registrationService;
  final DfxCountryService _countryService;
  final DfxKycService _kycService;

  SettingsUserDataCubit({
    required RealUnitRegistrationService registrationService,
    required DfxCountryService countryService,
    required DfxKycService kycService,
  }) : _registrationService = registrationService,
       _countryService = countryService,
       _kycService = kycService,
       super(const SettingsUserDataInitial()) {
    getUserData();
  }

  Future<void> getUserData() async {
    try {
      emit(const SettingsUserDataLoading());

      final results = await Future.wait([
        _registrationService.getRegistrationInfo(),
        _kycService.getKycStatus(),
        _kycService.getUser(),
      ]);

      final result = results.elementAt(0) as RealUnitRegistrationInfoDto;
      final kycStatus = results.elementAt(1) as KycLevelDto;
      final user = results.elementAt(2) as UserDto;
      final userDataDto = result.realUnitUserDataDto;

      if (userDataDto == null) {
        emit(SettingsUserDataSuccess(email: user.mail, capabilities: user.capabilities));
        return;
      }

      final pendingSteps = kycStatus.kycSteps
          .where(
            (step) => _changeStepNames.contains(step.name) && step.status == KycStepStatus.inReview,
          )
          .map<KycStepName>((step) => step.name)
          .toSet();

      final countryResults = await Future.wait([
        _countryService.getCountryBySymbol(userDataDto.nationality),
        _countryService.getCountryBySymbol(userDataDto.addressCountry),
      ]);

      final nationalityCountry = countryResults.elementAt(0);
      final addressCountry = countryResults.elementAt(1);

      emit(
        SettingsUserDataSuccess(
          userData: UserData(
            type: RegistrationUserType.fromName(userDataDto.type),
            name: userDataDto.name,
            email: userDataDto.email,
            // The API returns '' when no birthday is on record.
            birthday: DateTime.tryParse(userDataDto.birthday),
            nationality: nationalityCountry,
            addressStreet: userDataDto.addressStreet,
            addressCity: userDataDto.addressCity,
            addressCountry: addressCountry,
            addressPostalCode: userDataDto.addressPostalCode,
            phoneNumber: userDataDto.phoneNumber,
            swissTaxResidence: userDataDto.swissTaxResidence,
            lang: userDataDto.lang,
          ),
          pendingSteps: pendingSteps,
          capabilities: user.capabilities,
        ),
      );
    } on BitboxNotConnectedException {
      emit(const SettingsUserDataBitboxDisconnected());
    } catch (e) {
      developer.log(e.toString());
      emit(const SettingsUserDataFailure());
    }
  }
}
