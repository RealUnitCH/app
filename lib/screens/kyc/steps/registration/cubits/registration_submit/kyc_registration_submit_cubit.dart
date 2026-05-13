import 'dart:developer' as developer;

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:realunit_wallet/packages/service/dfx/dfx_kyc_service.dart';
import 'package:realunit_wallet/packages/service/dfx/exceptions/api_exception.dart';
import 'package:realunit_wallet/packages/service/dfx/exceptions/bitbox_exception.dart';
import 'package:realunit_wallet/packages/service/dfx/models/country/country.dart';
import 'package:realunit_wallet/packages/service/dfx/models/registration/registration.dart';
import 'package:realunit_wallet/packages/service/dfx/models/registration/registration_status.dart';
import 'package:realunit_wallet/packages/service/dfx/models/registration/registration_user_type.dart';
import 'package:realunit_wallet/packages/service/dfx/real_unit_registration_service.dart';

part 'kyc_registration_submit_state.dart';

class KycRegistrationSubmitCubit extends Cubit<KycRegistrationSubmitState> {
  final DfxKycService _kycService;
  final RealUnitRegistrationService _registrationService;

  KycRegistrationSubmitCubit(
    RealUnitRegistrationService registrationService,
    DfxKycService kycService,
  ) : _registrationService = registrationService,
      _kycService = kycService,
      super(KycRegistrationSubmitInitial());

  Future<void> submit({
    required RegistrationUserType type,
    required String firstName,
    required String lastName,
    required String phoneNumber,
    required String birthday,
    required Country nationality,
    required String addressStreet,
    required String addressStreetNumber,
    required String addressPostalCode,
    required String addressCity,
    required Country addressCountry,
    required bool swissTaxResidence,
  }) async {
    try {
      emit(KycRegistrationSubmitLoading());

      final user = await _kycService.getUser();
      final mail = user.mail;
      if (mail != null) {
        final registration = Registration(
          type: type,
          email: mail,
          firstName: firstName,
          lastName: lastName,
          phoneNumber: phoneNumber,
          birthday: birthday,
          nationality: nationality,
          addressStreet: addressStreet,
          addressStreetNumber: addressStreetNumber,
          addressPostalCode: addressPostalCode,
          addressCity: addressCity,
          addressCountry: addressCountry,
          swissTaxResidence: swissTaxResidence,
        );

        await _doCompleteRegistration(registration);
      } else {
        emit(const KycRegistrationSubmitFailure('Mail could not be fetched'));
      }
    } catch (e) {
      developer.log(e.toString());
      emit(KycRegistrationSubmitFailure(e.toString(), cause: e));
      return;
    }
  }

  Future<void> _doCompleteRegistration(Registration registration) async {
    try {
      final status = await _registrationService.completeRegistration(registration);
      emit(KycRegistrationSubmitSuccess(status));
    } on BitboxNotConnectedException {
      emit(
        KycRegistrationSubmitBitboxRequired(registration: registration),
      );
    } on ApiException catch (e) {
      // The EIP-712 13-step sign already succeeded on the device — the user
      // has proven hardware-wallet control. The backend's logical rejection
      // (already registered / wallet linked to another account / merge
      // required) is informational, not a signal that the ceremony failed.
      // Treat the sign as completed and let `KycCubit.checkKyc()` resolve
      // the next step from the refreshed KYC status (merge page, ident,
      // ...). Network / parse errors throw a different exception type and
      // still surface as a failure below.
      developer.log('completeRegistration backend rejected after sign: $e');
      emit(const KycRegistrationSubmitSuccess(RegistrationStatus.completed));
    } catch (e) {
      developer.log(e.toString());
      emit(KycRegistrationSubmitFailure(e.toString(), cause: e));
    }
  }

  Future<void> retrySubmit(Registration registration) async {
    emit(KycRegistrationSubmitLoading());
    await _doCompleteRegistration(registration);
  }
}
