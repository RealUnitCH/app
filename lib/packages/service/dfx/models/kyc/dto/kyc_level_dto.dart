import 'package:realunit_wallet/packages/service/dfx/models/kyc/dto/kyc_step_dto.dart';
import 'package:realunit_wallet/packages/service/dfx/models/kyc/kyc_level.dart';

class KycLevelDto {
  final KycLevel kycLevel;
  final List<KycStepDto> kycSteps;

  const KycLevelDto({required this.kycLevel, required this.kycSteps});

  factory KycLevelDto.fromJson(Map<String, dynamic> json) {
    return KycLevelDto(
      kycLevel: KycLevelExtension.fromValue(json['kycLevel'] as int),
      kycSteps: (json['kycSteps'] as List<dynamic>)
          .map((e) => KycStepDto.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}
