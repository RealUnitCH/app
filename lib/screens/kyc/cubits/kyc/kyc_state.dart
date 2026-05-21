part of 'kyc_cubit.dart';

enum KycStep {
  email,
  registration,
  legalDisclaimer,
  nationality,
  twoFa,
  ident,
  financialData,
  dfxApproval,
}

abstract class KycState extends Equatable {
  const KycState();

  @override
  List<Object?> get props => [];
}

class KycInitial extends KycState {
  const KycInitial();
}

class KycLoading extends KycState {
  const KycLoading();
}

class KycPending extends KycState {
  final KycStep pendingStep;

  const KycPending(this.pendingStep);

  @override
  List<Object?> get props => [pendingStep];
}

class KycSuccess extends KycState {
  final KycStep currentStep;
  final String? urlOrToken;

  const KycSuccess({required this.currentStep, this.urlOrToken});

  @override
  List<Object?> get props => [currentStep, urlOrToken];
}

class KycCompleted extends KycState {
  const KycCompleted();
}

class KycAccountMergeRequested extends KycState {
  const KycAccountMergeRequested();
}

class KycUnsupportedStepFailure extends KycState {
  // Null when the backend says `PendingReview` but the step list contains no
  // `isRequired` step we can name — we still surface the failure (never a
  // silent `KycCompleted`) but cannot point the user at a specific step.
  final KycStepName? stepName;
  const KycUnsupportedStepFailure(this.stepName);

  @override
  List<Object?> get props => [stepName];
}

class KycFailure extends KycState {
  final String message;
  const KycFailure(this.message);

  @override
  List<Object?> get props => [message];
}
