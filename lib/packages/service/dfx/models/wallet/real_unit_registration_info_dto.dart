import 'package:realunit_wallet/packages/service/dfx/models/user/dto/real_unit_user_data_dto.dart';
import 'package:realunit_wallet/packages/service/dfx/models/wallet/real_unit_registration_state.dart';

class RealUnitRegistrationInfoDto {
  /// API-side routing decision for this wallet. Drives KYC dispatch in
  /// `KycCubit._runCheckKyc` — see CONTRIBUTING.md "API as Decision
  /// Authority". `userData` is populated for `addWallet` (prior payload)
  /// and `newRegistration` (KYC pre-fill); `null` for `alreadyRegistered`
  /// (no UX needed).
  final RealUnitRegistrationState state;
  final RealUnitUserDataDto? realUnitUserDataDto;

  /// Whether the API has confirmed the account e-mail address for this wallet.
  /// Nullable on purpose: `null` means a pre-rollout backend (the field does
  /// not exist yet) or no registration at all — grandfathered accounts (in
  /// existence before the rollout) report an explicit `true`, never `null`.
  /// `KycCubit` treats `null` as "no confirmation gate" and proceeds as before —
  /// only an explicit `false` routes to the confirm step. See CONTRIBUTING.md
  /// "API as Decision Authority" (legacy backend tolerance).
  final bool? emailConfirmed;

  /// Timestamp of the confirmation, when the API reports one. Not consumed for
  /// routing (that is [emailConfirmed] alone); carried for completeness/display.
  final DateTime? confirmedDate;

  RealUnitRegistrationInfoDto({
    required this.state,
    this.realUnitUserDataDto,
    this.emailConfirmed,
    this.confirmedDate,
  });

  factory RealUnitRegistrationInfoDto.fromJson(Map<String, dynamic> json) {
    return RealUnitRegistrationInfoDto(
      state: RealUnitRegistrationState.fromJson(json['state'] as String),
      realUnitUserDataDto: json['userData'] != null
          ? RealUnitUserDataDto.fromJson(json['userData'] as Map<String, dynamic>)
          : null,
      emailConfirmed: json['emailConfirmed'] as bool?,
      confirmedDate: json['confirmedDate'] != null
          ? DateTime.parse(json['confirmedDate'] as String)
          : null,
    );
  }
}
