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

class KycSuccess extends KycState {
  final KycStep? currentStep;
  final String? url;

  const KycSuccess({this.currentStep, this.url});

  @override
  List<Object?> get props => [currentStep, url];
}

class KycFailure extends KycState {
  final String message;
  const KycFailure(this.message);

  @override
  List<Object?> get props => [message];
}
