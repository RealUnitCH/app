part of 'kyc_cubit.dart';

enum KycStep { registration, nationality, twoFa, ident, financialData }

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

class KycFailure extends KycState {
  final String message;
  const KycFailure(this.message);

  @override
  List<Object?> get props => [message];
}
