import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:realunit_wallet/packages/service/dfx/dfx_country_service.dart';
import 'package:realunit_wallet/packages/service/dfx/dfx_kyc_service.dart';
import 'package:realunit_wallet/packages/service/dfx/models/kyc/dto/kyc_level_dto.dart';
import 'package:realunit_wallet/packages/service/dfx/models/kyc/kyc_level.dart';
import 'package:realunit_wallet/packages/service/dfx/models/registration/registration_user_type.dart';
import 'package:realunit_wallet/packages/service/dfx/models/user/user_data.dart';
import 'package:realunit_wallet/packages/service/dfx/models/wallet/real_unit_wallet_status_dto.dart';
import 'package:realunit_wallet/packages/service/dfx/real_unit_wallet_service.dart';

part 'settings_user_data_state.dart';

class SettingsUserDataCubit extends Cubit<SettingsUserDataState> {
  final RealUnitWalletService _walletService;
  final DfxCountryService _countryService;
  final DfxKycService _kycService;

  SettingsUserDataCubit({
    required RealUnitWalletService walletService,
    required DfxCountryService countryService,
    required DfxKycService kycService,
  }) : _walletService = walletService,
       _countryService = countryService,
       _kycService = kycService,
       super(const SettingsUserDataInitial()) {
    getUserData();
  }

  static const _changeStepNames = {
    KycStepName.nameChange,
    KycStepName.addressChange,
  };

  Future<void> getUserData() async {
    try {
      emit(const SettingsUserDataLoading());

      final results = await Future.wait([
        _walletService.getWalletStatus(),
        _kycService.getKycStatus(),
      ]);

      final result = results[0] as RealUnitWalletStatusDto;
      final kycStatus = results[1] as KycLevelDto;
      final userDataDto = result.realUnitUserDataDto;

      if (userDataDto == null) {
        emit(const SettingsUserDataSuccess(null));
        return;
      }

      final pendingSteps = kycStatus.kycSteps
          .where((step) =>
              _changeStepNames.contains(step.name) &&
              step.status == KycStepStatus.inReview)
          .map<KycStepName>((step) => step.name)
          .toSet();

      final nationalityCountry = await _countryService.getCountryBySymbol(userDataDto.nationality);
      final addressCountry = await _countryService.getCountryBySymbol(userDataDto.addressCountry);
      emit(
        SettingsUserDataSuccess(
          UserData(
            type: RegistrationUserType.fromName(userDataDto.type),
            name: userDataDto.name,
            email: userDataDto.email,
            birthday: DateTime.parse(userDataDto.birthday),
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
        ),
      );
    } catch (e) {
      emit(SettingsUserDataFailure(e.toString()));
    }
  }
}
