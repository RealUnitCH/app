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

  String title(BuildContext context) {
    switch (step) {
      case RegistrationStep.personal:
        return S.of(context).personal_data;
      case RegistrationStep.address:
        return S.of(context).residence;
      case RegistrationStep.completed:
        return S.of(context).completed;
    }
  }

  bool get canGoBack => step != RegistrationStep.personal && step != RegistrationStep.completed;
}
