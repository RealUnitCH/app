import 'package:realunit_wallet/packages/service/dfx/models/user/dto/real_unit_user_data_dto.dart';
import 'package:realunit_wallet/packages/service/dfx/models/wallet/real_unit_registration_state.dart';

class RealUnitWalletStatusDto {
  /// API-side routing decision for this wallet. Drives KYC dispatch in
  /// `KycCubit._runCheckKyc` — see CONTRIBUTING.md "API as Decision
  /// Authority". `userData` is populated for `addWallet` (prior payload)
  /// and `newRegistration` (KYC pre-fill); `null` for `alreadyRegistered`
  /// (no UX needed) and `kycRequired` (edge case).
  final RealUnitRegistrationState state;
  final RealUnitUserDataDto? realUnitUserDataDto;

  RealUnitWalletStatusDto({
    required this.state,
    this.realUnitUserDataDto,
  });

  factory RealUnitWalletStatusDto.fromJson(Map<String, dynamic> json) {
    return RealUnitWalletStatusDto(
      state: RealUnitRegistrationState.fromJson(json['state'] as String),
      realUnitUserDataDto: json['userData'] != null
          ? RealUnitUserDataDto.fromJson(json['userData'] as Map<String, dynamic>)
          : null,
    );
  }
}
