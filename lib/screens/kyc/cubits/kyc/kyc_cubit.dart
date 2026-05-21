import 'dart:async';

import 'package:collection/collection.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:realunit_wallet/packages/service/dfx/dfx_kyc_service.dart';
import 'package:realunit_wallet/packages/service/dfx/exceptions/api_exception.dart';
import 'package:realunit_wallet/packages/service/dfx/models/kyc/dto/kyc_level_dto.dart';
import 'package:realunit_wallet/packages/service/dfx/models/kyc/kyc_level.dart';
import 'package:realunit_wallet/packages/service/dfx/models/user/dto/user_dto.dart';
import 'package:realunit_wallet/packages/service/dfx/real_unit_registration_service.dart';

part 'kyc_state.dart';

class KycCubit extends Cubit<KycState> {
  static const _requiredStepNames = {
    KycStepName.contactData,
    KycStepName.nationalityData,
    KycStepName.ident,
    KycStepName.financialData,
    KycStepName.dfxApproval,
  };

  static const _minLevelForActions = 30;
  static const _checkKycTimeout = Duration(seconds: 30);

  final DfxKycService _kycService;
  final RealUnitRegistrationService _registrationService;
  final int _requiredLevel;

  bool _legalDisclaimerAccepted = false;
  bool _emailRegistrationAttempted = false;

  // Tracks whether the EIP-712 registration signature has been produced in
  // *this* KYC entry. Wallet-agnostic — for software wallets the sign is a
  // silent local operation, for BitBox it is the visible 13-step ceremony.
  // Per-cubit-instance by design: `KycPageManager` creates a fresh `KycCubit`
  // via `BlocProvider(create:)`, so every `/kyc` entry forces a fresh sign
  // before sensitive steps and stale sessions cannot be re-used.
  bool _registrationSignProduced = false;

  // `Future.timeout` does not cancel the underlying work, so a late HTTP
  // response from an earlier call can still resume and emit state after a
  // retry. Each `checkKyc()` captures its own generation; the run body and
  // any continuations bail when their generation no longer matches the
  // current one. Acts as a cancellation token for non-cancellable work.
  int _runGeneration = 0;

  KycCubit(
    DfxKycService kycService,
    RealUnitRegistrationService registrationService, {
    int? requiredLevel,
  }) : _kycService = kycService,
       _registrationService = registrationService,
       _requiredLevel = requiredLevel ?? _minLevelForActions,
       super(const KycInitial());

  Future<void> checkKyc() async {
    final generation = ++_runGeneration;
    try {
      await _runCheckKyc(generation).timeout(_checkKycTimeout);
    } on TimeoutException {
      if (isClosed || generation != _runGeneration) return;
      emit(const KycFailure('KYC backend did not respond in time'));
    } catch (e) {
      if (isClosed || generation != _runGeneration) return;
      emit(KycFailure(e.toString()));
    }
  }

  Future<void> _runCheckKyc(int generation) async {
    try {
      if (isClosed || generation != _runGeneration) return;
      emit(const KycLoading());

      final results = await Future.wait([
        _kycService.getKycStatus(),
        _kycService.getUser(),
      ]);

      if (isClosed || generation != _runGeneration) return;

      final kycStatus = results.elementAt(0) as KycLevelDto;
      final user = results.elementAt(1) as UserDto;
      final level = kycStatus.kycLevel.value;

      if (user.mail == null) {
        emit(const KycSuccess(currentStep: KycStep.email));
        return;
      }

      // edge case, where email exists but level is <10. In this case email is automatically registered for RealUnit
      if (user.mail != null && level < 10) {
        if (_emailRegistrationAttempted) {
          // Backend did not bump the level after registration; surface the
          // current state instead of recursing forever.
          emit(const KycSuccess(currentStep: KycStep.email));
          return;
        }
        _emailRegistrationAttempted = true;
        await _registrationService.registerEmail(user.mail!);
        if (isClosed || generation != _runGeneration) return;
        await _runCheckKyc(generation);
        return;
      }

      // Disclaimer + EIP-712 registration sign always precede every state
      // past the email step, even when the user is already at
      // `>= requiredLevel`. The sign is the per-session security gate, not
      // the backend KYC level — without it a returning user with a high
      // level would otherwise be granted sensitive actions on this device
      // without re-proving ownership of the wallet key.
      if (!_legalDisclaimerAccepted) {
        emit(const KycSuccess(currentStep: KycStep.legalDisclaimer));
        return;
      }
      if (!_registrationSignProduced) {
        emit(const KycSuccess(currentStep: KycStep.registration));
        return;
      }

      // Step status drives routing, not the numeric level: the backend can
      // report level >= required while individual required steps are still
      // failed/outdated/notStarted/dataRequested, and those have to be
      // re-done before the user is "completed".
      final hasMergeRequest = kycStatus.kycSteps.any(
        (step) => step.reason == KycStepReason.accountMergeRequested,
      );
      if (hasMergeRequest) {
        emit(const KycAccountMergeRequested());
        return;
      }

      final requiredSteps = kycStatus.kycSteps.where(
        (step) => _requiredStepNames.contains(step.name),
      );

      // `onHold` is semantically a backend-side wait state — the user has no
      // actionable next step, the same as `inReview`. Treat it identically so
      // a high-level user with an `onHold` required step is shown the pending
      // screen instead of falling through to `KycCompleted`.
      const pendingStatuses = {KycStepStatus.inReview, KycStepStatus.onHold};
      final pendingStep = requiredSteps.firstWhereOrNull(
        (step) => pendingStatuses.contains(step.status),
      );
      if (pendingStep != null) {
        final step = _mapStepName(pendingStep.name);
        if (step != null) {
          emit(KycPending(step));
        } else {
          emit(KycUnsupportedStepFailure(pendingStep.name));
        }
        return;
      }

      const actionableStatuses = {
        KycStepStatus.notStarted,
        KycStepStatus.inProgress,
        KycStepStatus.failed,
        KycStepStatus.outdated,
        KycStepStatus.dataRequested,
      };
      final unfinishedStep = requiredSteps.firstWhereOrNull(
        (step) => actionableStatuses.contains(step.status),
      );
      if (unfinishedStep != null) {
        await _continueKyc(generation);
        return;
      }

      if (level < _requiredLevel) {
        await _continueKyc(generation);
        return;
      }

      emit(const KycCompleted());
    } on ApiException catch (e) {
      if (isClosed || generation != _runGeneration) return;
      // The body `code` is the authoritative signal — `TfaRequiredException`
      // on the API sets `{code: 'TFA_REQUIRED', level, message}` and happens
      // to use HTTP 403 as transport. Matching on status alone would also
      // capture unrelated forbidden errors and misroute them to 2FA.
      if (e.code == 'TFA_REQUIRED') {
        emit(const KycSuccess(currentStep: KycStep.twoFa));
      } else {
        rethrow;
      }
    } catch (e) {
      if (isClosed || generation != _runGeneration) return;
      emit(KycFailure(e.toString()));
    }
  }

  void markLegalDisclaimerAccepted() {
    _legalDisclaimerAccepted = true;
  }

  /// Records that the EIP-712 registration signature has been produced in
  /// this session, so subsequent [checkKyc] calls pass the sign gate.
  /// Callers: any code path that triggers the sign — currently the
  /// new-registration form submit and the existing-customer merge confirm.
  void markRegistrationSignProduced() {
    _registrationSignProduced = true;
  }

  /// should only be called after realunit registration was completed
  Future<void> _continueKyc(int generation) async {
    final kycStatus = await _kycService.continueKyc();
    if (isClosed || generation != _runGeneration) return;
    final currentStep = kycStatus.kycSteps.firstWhere((step) => step.isCurrent);

    final kycStep = _mapStepName(currentStep.name);
    if (kycStep == null) {
      emit(KycUnsupportedStepFailure(currentStep.name));
      return;
    }

    emit(
      KycSuccess(
        currentStep: kycStep,
        urlOrToken: kycStatus.currentStep?.session.url,
      ),
    );
  }

  KycStep? _mapStepName(KycStepName name) => switch (name) {
    KycStepName.contactData => KycStep.registration,
    KycStepName.nationalityData => KycStep.nationality,
    KycStepName.ident => KycStep.ident,
    KycStepName.financialData => KycStep.financialData,
    KycStepName.dfxApproval => KycStep.dfxApproval,
    _ => null,
  };
}
