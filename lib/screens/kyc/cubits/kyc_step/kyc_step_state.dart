part of 'kyc_step_cubit.dart';

enum KycStep { personal, address, completed }

final List<KycStep> _stepsOrder = [
  KycStep.personal,
  KycStep.address,
  KycStep.completed,
];

class KycStepState {
  final KycStep step;

  const KycStepState(this.step);

  int get index => KycStep.values.indexOf(step);

  int get totalSteps => _stepsOrder.length;

  double get progress => (index + 1) / totalSteps;

  String get title {
    switch (step) {
      case KycStep.personal:
        return 'Persönliche Daten';
      case KycStep.address:
        return 'Residenz';
      case KycStep.completed:
        return 'Abgeschlossen';
    }
  }

  bool get canGoBack => step != KycStep.personal && step != KycStep.completed;
}
