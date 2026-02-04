import 'package:realunit_wallet/packages/service/dfx/models/kyc/kyc_level.dart';

class UserKycDto {
  final String hash;
  final KycLevel level;
  final bool dataComplete;

  const UserKycDto({required this.hash, required this.level, required this.dataComplete});

  factory UserKycDto.fromJson(Map<String, dynamic> json) {
    return UserKycDto(
      hash: json['hash'] as String,
      level: KycLevelExtension.fromValue(json['level'] as int),
      dataComplete: json['dataComplete'] as bool,
    );
  }

  Map<String, dynamic> toJson() {
    return {'hash': hash, 'level': level.value, 'dataComplete': dataComplete};
  }
}

class UserDto {
  final UserKycDto kyc;

  const UserDto({required this.kyc});

  factory UserDto.fromJson(Map<String, dynamic> json) {
    return UserDto(kyc: UserKycDto.fromJson(json['kyc'] as Map<String, dynamic>));
  }

  Map<String, dynamic> toJson() {
    return {'kyc': kyc.toJson()};
  }
}
