import 'package:collection/collection.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:realunit_wallet/packages/service/dfx/dfx_kyc_service.dart';
import 'package:realunit_wallet/packages/service/dfx/exceptions/api_exception.dart';
import 'package:realunit_wallet/packages/service/dfx/models/kyc/dto/kyc_level_dto.dart';
import 'package:realunit_wallet/packages/service/dfx/models/kyc/kyc_level.dart';
import 'package:realunit_wallet/packages/service/dfx/models/user/dto/user_dto.dart';
import 'package:realunit_wallet/packages/service/dfx/models/wallet/real_unit_wallet_status_dto.dart';
import 'package:realunit_wallet/packages/service/dfx/real_unit_registration_service.dart';
import 'package:realunit_wallet/packages/service/dfx/real_unit_wallet_service.dart';

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

  final DfxKycService _kycService;
  final RealUnitWalletService _walletService;
  final RealUnitRegistrationService _registrationService;
  final int _requiredLevel;

  bool _legalDisclaimerAccepted = false;

  KycCubit(
    DfxKycService kycService,
    RealUnitWalletService walletService,
    RealUnitRegistrationService registrationService, {
    int? requiredLevel,
  }) : _kycService = kycService,
       _walletService = walletService,
       _registrationService = registrationService,
       _requiredLevel = requiredLevel ?? _minLevelForActions,
       super(const KycInitial());

  Future<void> checkKyc() async {
    try {
      emit(const KycLoading());

      final results = await Future.wait([
        _walletService.getWalletStatus(),
        _kycService.getKycStatus(),
        _kycService.getUser(),
      ]);

      final status = results.elementAt(0) as RealUnitWalletStatusDto;
      final kycStatus = results.elementAt(1) as KycLevelDto;
      final user = results.elementAt(2) as UserDto;
      final level = kycStatus.kycLevel.value;

      if (user.mail == null) {
        emit(const KycSuccess(currentStep: KycStep.email));
        return;
      }

      // edge case, where email exists but level is <10. In this case email is automatically registered for RealUnit
      if (user.mail != null && level < 10) {
        await _registrationService.registerEmail(user.mail!);
        await checkKyc();
        return;
      }

      if (!status.isRegistered) {
        if (!_legalDisclaimerAccepted) {
          emit(const KycSuccess(currentStep: KycStep.legalDisclaimer));
          return;
        }
        if (level < 20) {
          emit(const KycSuccess(currentStep: KycStep.registration));
          return;
        }
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
          if (step != null) emit(KycPending(step));
          return;
        }

        await _continueKyc();
        return;
      }

      emit(const KycCompleted());
    } on ApiException catch (e) {
      // API returns 403 when 2FA verification is required before proceeding
      if (e.statusCode == 403) {
        emit(const KycSuccess(currentStep: KycStep.twoFa));
      } else {
        rethrow;
      }
    } catch (e) {
      emit(KycFailure(e.toString()));
    }
  }

  void markLegalDisclaimerAccepted() {
    _legalDisclaimerAccepted = true;
  }

  /// should only be called after realunit registration was completed
  Future<void> _continueKyc() async {
    final kycStatus = await _kycService.continueKyc();
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
