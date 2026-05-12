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

  // Per-cubit-instance gate. Reset on every KYC entry because `KycPageManager`
  // creates a fresh `KycCubit` via `BlocProvider(create:)`, so each entry
  // forces a fresh hardware-wallet confirmation before sensitive steps.
  bool _bitboxConfirmed = false;

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

      // Disclaimer + form (name/address) + EIP-712 13-step sign always
      // precede every state past the email step, even when the user is
      // already at `>= requiredLevel`. The hardware-wallet ceremony is the
      // security gate, not the backend KYC level — without the sign a
      // returning user with a high level would otherwise be granted
      // sensitive actions on this device without ever touching the BitBox.
      if (!_legalDisclaimerAccepted) {
        emit(const KycSuccess(currentStep: KycStep.legalDisclaimer));
        return;
      }
      if (!_bitboxConfirmed) {
        emit(const KycSuccess(currentStep: KycStep.registration));
        return;
      }

      if (level < _requiredLevel) {
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

        final pendingStep = requiredSteps.firstWhereOrNull(
          (step) => step.status == KycStepStatus.inReview,
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

        await _continueKyc(generation);
        return;
      }

      emit(const KycCompleted());
    } on ApiException catch (e) {
      if (isClosed || generation != _runGeneration) return;
      // API returns 403 / code TFA_REQUIRED when 2FA verification is required
      // before proceeding.
      if (e.statusCode == 403 || e.code == 'TFA_REQUIRED') {
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

  void markBitboxConfirmed() {
    _bitboxConfirmed = true;
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
