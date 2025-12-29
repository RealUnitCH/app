part of 'registration_step_cubit.dart';

enum RegistrationStep { personal, address, completed }

final List<RegistrationStep> _stepsOrder = [
  RegistrationStep.personal,
  RegistrationStep.address,
  RegistrationStep.completed,
];

class RegistrationStepState {
  final RegistrationStep step;

  const RegistrationStepState(this.step);

  int get index => RegistrationStep.values.indexOf(step);

  int get totalSteps => _stepsOrder.length;

  double get progress => (index + 1) / totalSteps;

  String get title {
    switch (step) {
      case RegistrationStep.personal:
        return 'Persönliche Daten';
      case RegistrationStep.address:
        return 'Residenz';
      case RegistrationStep.completed:
        return 'Abgeschlossen';
    }
  }

  bool get canGoBack => step != RegistrationStep.personal && step != RegistrationStep.completed;
}
