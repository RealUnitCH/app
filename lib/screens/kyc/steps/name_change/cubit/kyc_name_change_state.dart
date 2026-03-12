part of 'kyc_name_change_cubit.dart';

abstract class KycNameChangeState extends Equatable {
  const KycNameChangeState();

  @override
  List<Object?> get props => [];
}

class KycNameChangeInitial extends KycNameChangeState {
  const KycNameChangeInitial();
}

class KycNameChangeLoading extends KycNameChangeState {
  const KycNameChangeLoading();
}

class KycNameChangeSuccess extends KycNameChangeState {
  const KycNameChangeSuccess();
}

class KycNameChangeFailure extends KycNameChangeState {
  final String message;

  const KycNameChangeFailure(this.message);

  @override
  List<Object?> get props => [message];
}
