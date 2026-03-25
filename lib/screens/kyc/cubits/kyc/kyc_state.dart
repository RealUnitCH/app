part of 'kyc_cubit.dart';

enum KycStep { registration, nationality, twoFa, ident, financialData, dfxApproval }

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
  final String? email;

  const KycSuccess({required this.currentStep, this.urlOrToken, this.email});

  @override
  List<Object?> get props => [currentStep, urlOrToken, email];
}

class KycCompleted extends KycState {
  const KycCompleted();
}

class KycAccountMergeRequested extends KycState {
  const KycAccountMergeRequested();
}

class KycUnsupportedStepFailure extends KycState {
  final KycStepName stepName;
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
