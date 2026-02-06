part of 'registration_step_cubit.dart';

enum RegistrationStep { email, personal, address }

class RegistrationStepState {
  final List<RegistrationStep> steps;
  final RegistrationStep step;

  const RegistrationStepState({
    required this.steps,
    required this.step,
  });

  int get index => steps.indexOf(step);

  int get totalSteps => steps.length;

  double get progress => (index + 1) / totalSteps;

  bool get canGoBack => step != RegistrationStep.email;

  String title(BuildContext context) {
    switch (step) {
      case RegistrationStep.email:
        return S.of(context).registerEmail;
      case RegistrationStep.personal:
        return S.of(context).personalData;
      case RegistrationStep.address:
        return S.of(context).residence;
    }
  }
}
