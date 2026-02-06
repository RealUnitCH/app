import 'package:collection/collection.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:realunit_wallet/packages/service/dfx/dfx_kyc_service.dart';
import 'package:realunit_wallet/packages/service/dfx/exceptions/api_exception.dart';
import 'package:realunit_wallet/packages/service/dfx/models/kyc/kyc_level.dart';

part 'kyc_state.dart';

class KycCubit extends Cubit<KycState> {
  static const _requiredStepNames = {
    KycStepName.contactData,
    KycStepName.nationalityData,
    KycStepName.ident,
  };

  final DfxKycService _kycService;

  KycCubit(DfxKycService kycService) : _kycService = kycService, super(const KycInitial());

  Future<void> checkKyc() async {
    try {
      emit(const KycLoading());

      final kycStatus = await _kycService.getKycStatus();
      final level = kycStatus.kycLevel.value;

      if (level < 20) {
        emit(const KycSuccess(currentStep: KycStep.registration));
        return;
      }

      if (level < 30) {
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

  /// should only be called after realunit registration was completed
  Future<void> _continueKyc() async {
    final kycStatus = await _kycService.continueKyc();
    final currentStep = kycStatus.kycSteps.firstWhere((step) => step.isCurrent);

    final kycStep = _mapStepName(currentStep.name);
    if (kycStep == null) throw Exception('current Step could not be found');

    emit(KycSuccess(currentStep: kycStep, urlOrToken: kycStatus.currentStep?.session.url));
  }

  KycStep? _mapStepName(KycStepName name) => switch (name) {
    KycStepName.contactData => KycStep.registration,
    KycStepName.nationalityData => KycStep.nationality,
    KycStepName.ident => KycStep.ident,
    _ => null,
  };
}
