import 'package:collection/collection.dart';
import 'package:equatable/equatable.dart';
import 'package:realunit_wallet/packages/service/dfx/models/kyc/dto/kyc_level_dto.dart';
import 'package:realunit_wallet/packages/service/dfx/models/kyc/kyc_level.dart';
import 'package:realunit_wallet/packages/service/dfx/models/kyc/kyc_step.dart';

class KycStatus extends Equatable {
  final KycLevel level;
  final List<KycStep> steps;

  const KycStatus({
    required this.level,
    required this.steps,
  });

  bool get canProceed => level.value < 50;

  bool get hasStarted =>
      steps.firstWhereOrNull((step) => step.name == KycStepName.contactData)?.status !=
      KycStepStatus.notStarted;

  factory KycStatus.fromDto(KycLevelDto dto) {
    return KycStatus(
      level: dto.kycLevel,
      steps: dto.kycSteps.map(KycStep.fromDto).toList(),
    );
  }

  @override
  List<Object?> get props => [level, steps, hasStarted, canProceed];
}
