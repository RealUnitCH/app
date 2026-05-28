part of 'kyc_link_wallet_cubit.dart';

abstract class KycLinkWalletState extends Equatable {
  const KycLinkWalletState();

  @override
  List<Object?> get props => [];
}

class KycLinkWalletReady extends KycLinkWalletState {
  final RealUnitUserDataDto userData;

  const KycLinkWalletReady(this.userData);

  @override
  List<Object?> get props => [userData];
}

class KycLinkWalletSubmitting extends KycLinkWalletState {
  final RealUnitUserDataDto userData;

  const KycLinkWalletSubmitting(this.userData);

  @override
  List<Object?> get props => [userData];
}

class KycLinkWalletSuccess extends KycLinkWalletState {
  const KycLinkWalletSuccess();
}

class KycLinkWalletFailure extends KycLinkWalletState {
  final String message;
  final Object? cause;

  const KycLinkWalletFailure(this.message, {this.cause});

  @override
  List<Object?> get props => [message, cause];
}
