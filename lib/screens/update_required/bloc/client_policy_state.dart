part of 'client_policy_cubit.dart';

sealed class ClientPolicyState extends Equatable {
  const ClientPolicyState();

  @override
  List<Object?> get props => [];
}

class ClientPolicyInitial extends ClientPolicyState {
  const ClientPolicyInitial();
}

class ClientPolicyLoaded extends ClientPolicyState {
  final RealUnitClientPolicy policy;
  final String? dismissedLatest;

  const ClientPolicyLoaded(this.policy, {this.dismissedLatest});

  @override
  List<Object?> get props => [policy, dismissedLatest];
}

class ClientPolicyFailOpen extends ClientPolicyState {
  const ClientPolicyFailOpen();
}
