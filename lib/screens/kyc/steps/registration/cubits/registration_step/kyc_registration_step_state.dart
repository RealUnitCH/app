part of 'kyc_registration_step_cubit.dart';

enum KycRegistrationStep { email, personal, address }

class KycRegistrationStepState {
  final List<KycRegistrationStep> steps;
  final KycRegistrationStep step;
  final int stepOffset;

  const KycRegistrationStepState({
    required this.steps,
    required this.step,
    this.stepOffset = 0,
  });

  int get index => steps.indexOf(step);

  int get totalSteps => steps.length + stepOffset;

  double get progress => (index + 1 + stepOffset) / totalSteps;

  bool get canGoBack => step != KycRegistrationStep.email;

  String title(BuildContext context) {
    switch (step) {
      case KycRegistrationStep.email:
        return S.of(context).registerEmail;
      case KycRegistrationStep.personal:
        return S.of(context).personalData;
      case KycRegistrationStep.address:
        return S.of(context).residence;
    }
  }
}
