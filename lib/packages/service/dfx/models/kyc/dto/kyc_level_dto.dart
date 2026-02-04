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

  Map<String, dynamic> toJson() {
    return {'kycLevel': kycLevel.value, 'kycSteps': kycSteps.map((e) => e.toJson()).toList()};
  }
}

class KycStepDto {
  final KycStepName name;
  final KycStepType? type;
  final KycStepStatus status;
  final KycStepReason? reason;
  final int sequenceNumber;
  final bool isCurrent;

  const KycStepDto({
    required this.name,
    this.type,
    required this.status,
    this.reason,
    required this.sequenceNumber,
    required this.isCurrent,
  });

  factory KycStepDto.fromJson(Map<String, dynamic> json) {
    return KycStepDto(
      name: KycStepNameExtension.fromValue(json['name'] as String),
      type: json['type'] != null ? KycStepTypeExtension.fromValue(json['type'] as String) : null,
      status: KycStepStatusExtension.fromValue(json['status'] as String),
      reason: json['reason'] != null
          ? KycStepReasonExtension.fromValue(json['reason'] as String)
          : null,
      sequenceNumber: json['sequenceNumber'] as int,
      isCurrent: json['isCurrent'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name.value,
      if (type != null) 'type': type!.value,
      'status': status.value,
      if (reason != null) 'reason': reason!.value,
      'sequenceNumber': sequenceNumber,
      'isCurrent': isCurrent,
    };
  }
}
