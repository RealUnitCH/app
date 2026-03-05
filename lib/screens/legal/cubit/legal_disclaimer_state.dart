part of 'legal_disclaimer_cubit.dart';

class LegalDisclaimerState extends Equatable {
  final int currentStep;

  static const int totalSteps = 5;

  const LegalDisclaimerState({
    this.currentStep = 0,
  });

  bool get canGoBack => currentStep > 0;

  bool get isLastStep => currentStep == totalSteps - 1;

  double get progress => (currentStep + 1) / totalSteps;

  LegalDisclaimerState copyWith({
    int? currentStep,
  }) {
    return LegalDisclaimerState(
      currentStep: currentStep ?? this.currentStep,
    );
  }

  @override
  List<Object?> get props => [currentStep];
}
