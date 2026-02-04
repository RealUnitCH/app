import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:realunit_wallet/packages/service/dfx/dfx_kyc_service.dart';
import 'package:realunit_wallet/packages/service/dfx/exceptions/api_exception.dart';
import 'package:realunit_wallet/packages/service/dfx/models/kyc/kyc_level.dart';

part 'kyc_state.dart';

class KycCubit extends Cubit<KycState> {
  final DfxKycService _kycService;

  KycCubit(DfxKycService kycService) : _kycService = kycService, super(const KycState());

  Future<void> checkKyc() async {
    try {
      final kycStatus = await _kycService.getKycStatus();

      if (kycStatus.kycLevel.value == 0) {
        emit(const KycSuccess(currentStep: KycStep.email));
      } else if (kycStatus.kycLevel.value <= 30) {
        await continueKyc();
      } else {
        emit(const KycSuccess());
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
    final step = kycStatus.kycSteps.firstWhere((step) => step.isCurrent);
    emit(KycSuccess(currentStep: mapper(step.name), url: kycStatus.currentStep?.session.url));
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
