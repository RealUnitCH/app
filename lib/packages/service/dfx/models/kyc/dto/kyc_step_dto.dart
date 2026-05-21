import 'package:realunit_wallet/packages/service/dfx/models/kyc/kyc_level.dart';

class KycStepDto {
  final KycStepName name;
  final KycStepType? type;
  final KycStepStatus status;
  final KycStepReason? reason;
  final int sequenceNumber;
  final bool isCurrent;
  // `true` when the backend's `requiredKycSteps(userData)` includes this
  // step for the current user. Authoritative — clients no longer maintain
  // a parallel set. Defaults to `false` for old API responses.
  final bool isRequired;

  const KycStepDto({
    required this.name,
    this.type,
    required this.status,
    this.reason,
    required this.sequenceNumber,
    required this.isCurrent,
    this.isRequired = false,
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
      isRequired: json['isRequired'] as bool? ?? false,
    );
  }
}
