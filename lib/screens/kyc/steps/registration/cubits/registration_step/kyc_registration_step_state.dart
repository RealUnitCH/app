part of 'kyc_registration_step_cubit.dart';

enum KycRegistrationStep { personal, address, taxResidence }

class KycRegistrationStepState {
  final List<KycRegistrationStep> steps;
  final KycRegistrationStep step;

  const KycRegistrationStepState({
    required this.steps,
    required this.step,
  });

  int get index => steps.indexOf(step);

  int get totalSteps => steps.length;

  double get progress => (index + 1) / totalSteps;

  bool get canGoBack => step != KycRegistrationStep.personal;

  String title(BuildContext context) {
    switch (step) {
      case KycRegistrationStep.personal:
        return S.of(context).personalData;
      case KycRegistrationStep.address:
        return S.of(context).residence;
      case KycRegistrationStep.taxResidence:
        return S.of(context).taxResidence;
    }
  }
}
