import 'package:collection/collection.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:realunit_wallet/packages/service/dfx/dfx_kyc_service.dart';
import 'package:realunit_wallet/packages/service/dfx/exceptions/api_exception.dart';
import 'package:realunit_wallet/packages/service/dfx/models/kyc/dto/kyc_level_dto.dart';
import 'package:realunit_wallet/packages/service/dfx/models/kyc/kyc_level.dart';
import 'package:realunit_wallet/packages/service/dfx/real_unit_registration_service.dart';

part 'kyc_state.dart';

class KycCubit extends Cubit<KycState> {
  static const _requiredStepNames = {
    KycStepName.contactData,
    KycStepName.nationalityData,
    KycStepName.ident,
  };

  final DfxKycService _kycService;
  final RealUnitRegistrationService _registrationService;

  KycCubit(
    DfxKycService kycService,
    RealUnitRegistrationService registrationService,
  ) : _kycService = kycService,
      _registrationService = registrationService,
      super(const KycInitial());

  Future<void> checkKyc() async {
    try {
      emit(const KycLoading());

      final results = await Future.wait([
        _registrationService.checkRegistrationStatus(),
        _kycService.getKycStatus(),
      ]);

      final isRegistered = results.elementAt(0) as bool;
      final kycStatus = results.elementAt(1) as KycLevelDto;
      final level = kycStatus.kycLevel.value;

      if (!isRegistered || level < 20) {
        emit(const KycSuccess(currentStep: KycStep.registration));
        return;
      }

      if (level < 30) {
        try {
          await _continueKyc();
        } catch (_) {
          // If continue fails (e.g. no next step available), show pending for in-review steps
          final pendingStep = kycStatus.kycSteps
              .where((step) => _requiredStepNames.contains(step.name))
              .firstWhereOrNull((step) => step.status == KycStepStatus.inReview);

          if (pendingStep != null) {
            final step = _mapStepName(pendingStep.name);
            if (step != null) {
              emit(KycPending(step));
              return;
            }
          }
          rethrow;
        }
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
