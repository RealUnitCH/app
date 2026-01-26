part of 'registration_step_cubit.dart';

enum RegistrationStep { email, emailVerification, personal, address, completed }

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

  bool get canGoBack => step != RegistrationStep.email && step != RegistrationStep.completed;

  String title(BuildContext context) {
    switch (step) {
      case RegistrationStep.email:
        return 'E-Mail';
      case RegistrationStep.emailVerification:
        return 'E-Mail bestätigen';
      case RegistrationStep.personal:
        return S.of(context).personalData;
      case RegistrationStep.address:
        return S.of(context).residence;
      case RegistrationStep.completed:
        return S.of(context).completed;
    }
  }
}
