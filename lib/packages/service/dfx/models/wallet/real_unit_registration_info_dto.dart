import 'package:realunit_wallet/packages/service/dfx/models/user/dto/real_unit_user_data_dto.dart';
import 'package:realunit_wallet/packages/service/dfx/models/wallet/real_unit_registration_state.dart';

class RealUnitRegistrationInfoDto {
  /// API-side routing decision for this wallet. Drives KYC dispatch in
  /// `KycCubit._runCheckKyc` — see CONTRIBUTING.md "API as Decision
  /// Authority". `userData` is populated whenever a registration row exists —
  /// `alreadyRegistered` and `addWallet` both carry the stored signed payload —
  /// and for `newRegistration` when DFX KYC data can pre-fill the form. It is
  /// `null` only when the stored registration has no signed payload, or when
  /// there is no verified personal data to pre-fill from.
  ///
  /// `alreadyRegistered` is NOT a no-payload case: the personal-data KYC step
  /// is reached only through that branch and seeds its correction form from
  /// this payload, so treating it as null would dead-end that step.
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

  /// Whether this wallet's RealUnit registration is parked in manual review —
  /// the Aktionariat forward failed and it awaits a manual re-forward by staff.
  /// `true` only for the current wallet (`alreadyRegistered`); `false`/absent
  /// otherwise. Nullable on purpose: `null` means a pre-rollout backend (the
  /// field does not exist yet). `KycCubit` treats `null`/`false` as "no
  /// manual-review gate" and proceeds as before — only an explicit `true` routes
  /// to the review screen. See CONTRIBUTING.md "API as Decision Authority"
  /// (legacy backend tolerance).
  final bool? manualReview;

  /// Company rejection sentence when [manualReview] is true. Optional and
  /// absent on older servers; a missing key, JSON null, or a blank string is
  /// stored as null.
  final String? rejectionMessage;

  /// Whether DFX has approved a new personal name that must be signed into the
  /// existing Aktionariat registration. Nullable on purpose: `null` means a
  /// pre-rollout backend (the field does not exist yet) or no gate. Only an
  /// explicit JSON `true` opens the gate — a missing key, JSON null, or a
  /// non-bool is stored as null. Same legacy rule as [emailConfirmed] and
  /// [manualReview]. See CONTRIBUTING.md "API as Decision Authority".
  final bool? nameUpdateRequired;

  /// Exact `name` field to sign when [nameUpdateRequired] is true. The API
  /// already sends BitBox ASCII. A missing key, JSON null, a non-string, or
  /// an empty string is stored as null. The value is not trimmed: it is the
  /// string that gets signed.
  final String? shareRegisterName;

  RealUnitRegistrationInfoDto({
    required this.state,
    this.realUnitUserDataDto,
    this.emailConfirmed,
    this.confirmedDate,
    this.manualReview,
    this.rejectionMessage,
    this.nameUpdateRequired,
    this.shareRegisterName,
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
      manualReview: json['manualReview'] as bool?,
      rejectionMessage: _optionalRejectionMessage(json['rejectionMessage']),
      nameUpdateRequired: _optionalBool(json['nameUpdateRequired']),
      shareRegisterName: _optionalNonEmptyString(json['shareRegisterName']),
    );
  }
}

/// Wire bool: only a JSON bool is kept. Missing, null, or a non-bool is null.
bool? _optionalBool(Object? value) => value is bool ? value : null;

/// Wire string that must be signed as-is. Missing, null, non-string, or empty
/// is null. A non-empty string is returned unchanged.
String? _optionalNonEmptyString(Object? value) {
  if (value is! String || value.isEmpty) return null;
  return value;
}

/// Wire `rejectionMessage`: missing, JSON null, non-string, or blank → null.
String? _optionalRejectionMessage(Object? value) {
  if (value is! String) return null;
  if (value.trim().isEmpty) return null;
  return value;
}
