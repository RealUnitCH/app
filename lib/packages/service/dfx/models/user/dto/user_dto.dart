import 'package:realunit_wallet/packages/service/dfx/models/kyc/kyc_level.dart';

class UserDto {
  final String? mail;
  final UserKycDto kyc;

  const UserDto({this.mail, required this.kyc});

  factory UserDto.fromJson(Map<String, dynamic> json) {
    return UserDto(
      mail: json['mail'] as String?,
      kyc: UserKycDto.fromJson(json['kyc'] as Map<String, dynamic>),
    );
  }
}

class UserKycDto {
  final String hash;
  final KycLevel level;
  final bool dataComplete;
  // Authoritative trading-permission flag from the backend. `true` ⇔ the
  // user may perform sensitive actions right now (level ≥ 30 + all required
  // steps Completed + no Outdated/InProgress Ident or FinancialData). The
  // app no longer compares `level` against a hardcoded threshold.
  // Defaults to `false` for old API responses (safe default — old clients
  // would have computed it themselves).
  final bool canTrade;

  const UserKycDto({
    required this.hash,
    required this.level,
    required this.dataComplete,
    this.canTrade = false,
  });

  factory UserKycDto.fromJson(Map<String, dynamic> json) {
    return UserKycDto(
      hash: json['hash'] as String,
      level: KycLevelExtension.fromValue(json['level'] as int),
      dataComplete: json['dataComplete'] as bool,
      canTrade: json['canTrade'] as bool? ?? false,
    );
  }
}
