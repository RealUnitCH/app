import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:realunit_wallet/packages/service/dfx/dfx_kyc_service.dart';
import 'package:realunit_wallet/packages/service/dfx/exceptions/api_exception.dart';
import 'package:realunit_wallet/packages/service/dfx/models/kyc/kyc_level.dart';

part 'kyc_state.dart';

const requiredNames = {KycStepName.contactData, KycStepName.nationalityData, KycStepName.ident};

class KycCubit extends Cubit<KycState> {
  final DfxKycService _kycService;

  KycCubit(DfxKycService kycService) : _kycService = kycService, super(const KycState());

  Future<void> checkKyc() async {
    try {
      emit(const KycLoading());
      final kycStatus = await _kycService.getKycStatus();

      if (kycStatus.kycLevel.value <= 10) {
        emit(const KycSuccess(currentStep: KycStep.email));
      } else if (kycStatus.kycLevel.value < 30) {
        final requiredSteps = kycStatus.kycSteps
            .where((step) => requiredNames.contains(step.name))
            .toList();
        if (requiredSteps.any((step) => step.status == KycStepStatus.inReview)) {
          final pendingStep = requiredSteps.firstWhere(
            (step) => step.status == KycStepStatus.inReview,
          );
          emit(KycPending(mapper(pendingStep.name)!));
          return;
        }
        await continueKyc();
      } else {
        emit(const KycSuccess(isCompleted: true));
      }
    } on ApiException catch (e) {
      if (e.statusCode == 403) {
        emit(const KycSuccess(currentStep: KycStep.twoFa));
      } else {
        rethrow;
      }
    } catch (e) {
      emit(KycFailure(e.toString()));
    }
  }

  Future<void> continueKyc() async {
    final kycStatus = await _kycService.continueKyc();
    final currentStep = kycStatus.kycSteps.firstWhere((step) => step.isCurrent);
    emit(
      KycSuccess(currentStep: mapper(currentStep.name), url: kycStatus.currentStep?.session.url),
    );
  }

  KycStep? mapper(KycStepName name) {
    if (name == KycStepName.contactData) {
      return KycStep.email;
    }
    if (name == KycStepName.personalData) {
      return KycStep.personal;
    }

    if (name == KycStepName.nationalityData) {
      return KycStep.nationality;
    }
    if (name == KycStepName.ident) {
      return KycStep.ident;
    }
    return null;
  }
}
