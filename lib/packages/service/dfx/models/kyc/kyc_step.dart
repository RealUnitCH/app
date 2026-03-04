import 'package:equatable/equatable.dart';
import 'package:realunit_wallet/packages/service/dfx/models/kyc/kyc_level.dart';

class KycStep extends Equatable {
  final KycStepName name;
  final KycStepType? type;
  final KycStepStatus status;
  final KycStepReason? reason;
  final int sequenceNumber;
  final bool isCurrent;

  const KycStep({
    required this.name,
    this.type,
    required this.status,
    this.reason,
    required this.sequenceNumber,
    required this.isCurrent,
  });

  factory KycStep.fromDto(dynamic dto) {
    return KycStep(
      name: dto.name,
      type: dto.type,
      status: dto.status,
      reason: dto.reason,
      sequenceNumber: dto.sequenceNumber,
      isCurrent: dto.isCurrent,
    );
  }

  @override
  List<Object?> get props => [name, type, status, reason, sequenceNumber, isCurrent];
}
