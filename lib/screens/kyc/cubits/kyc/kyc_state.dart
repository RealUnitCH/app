part of 'kyc_cubit.dart';

enum KycStep {
  email,
  registration,
  linkWallet,
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

  /// Server-side user record attached to the routing decision. Populated when
  /// `RealUnitRegistrationService.getRegistrationInfo()` returns userData
  /// alongside the state (`AddWallet` always, `NewRegistration` when the
  /// backend has fallback data). The cubit forwards the DTO so downstream
  /// pages do not need to re-fetch — see CONTRIBUTING.md "Single round-trip
  /// per decision".
  final RealUnitUserDataDto? realUnitUserData;

  const KycSuccess({
    required this.currentStep,
    this.urlOrToken,
    this.realUnitUserData,
  });

  @override
  List<Object?> get props => [currentStep, urlOrToken, realUnitUserData];
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

/// Emitted when `getRegistrationInfo()` reports `kycRequired` — i.e. the
/// wallet cannot be added without first completing the identity verification
/// flow. Distinct from `KycUnsupportedStepFailure` so the user sees a
/// tailored "complete your verification" message instead of the generic
/// "step (-) cannot be completed" fallback.
class KycRequiredFailure extends KycState {
  const KycRequiredFailure();
}

/// Emitted when the wallet currently in use cannot produce EIP-712 signatures
/// (today: the address+signature debug wallet) and the API has routed the
/// user to a state (`NewRegistration` / `AddWallet`) that would require one.
/// Signing capability is a physical property of the wallet — see
/// `docs/wallet-modes.md` for the full table.
class KycSignatureUnsupportedFailure extends KycState {
  const KycSignatureUnsupportedFailure();
}
