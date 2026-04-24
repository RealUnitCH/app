import 'dart:developer' as developer;

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:realunit_wallet/packages/service/dfx/dfx_kyc_service.dart';
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
      emit(KycRegistrationSubmitFailure(e.toString()));
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
    } catch (e) {
      developer.log(e.toString());
      emit(KycRegistrationSubmitFailure(e.toString()));
    }
  }

  Future<void> retrySubmit(Registration registration) async {
    emit(KycRegistrationSubmitLoading());
    await _doCompleteRegistration(registration);
  }
}
