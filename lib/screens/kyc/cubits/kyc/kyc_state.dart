part of 'kyc_cubit.dart';

enum KycStep { email, personal, nationality, twoFa, ident }

class KycState extends Equatable {
  const KycState();

  @override
  List<Object?> get props => [];
}

class KycLoading extends KycState {
  const KycLoading();
}

class KycPending extends KycState {
  final KycStep pendingStep;

  const KycPending(this.pendingStep);
}

class KycSuccess extends KycState {
  final KycStep? currentStep;
  final String? url;
  final bool isCompleted;

  const KycSuccess({this.currentStep, this.url, this.isCompleted = false});

  @override
  List<Object?> get props => [currentStep, url, isCompleted];
}

class KycFailure extends KycState {
  final String message;
  const KycFailure(this.message);

  @override
  List<Object?> get props => [message];
}
