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

/// Emitted when `registerWallet` aborts because the BitBox is not connected.
/// The page reacts by opening the `ConnectBitboxPage` sheet and, on a
/// successful connection, calls `retrySubmit`. Carries `userData` so the page
/// renders the idle confirm body underneath the sheet (and again if the user
/// dismisses it without connecting). Mirror of
/// `KycRegistrationSubmitBitboxRequired`.
class KycLinkWalletBitboxRequired extends KycLinkWalletState {
  final RealUnitUserDataDto userData;

  const KycLinkWalletBitboxRequired(this.userData);

  @override
  List<Object?> get props => [userData];
}
