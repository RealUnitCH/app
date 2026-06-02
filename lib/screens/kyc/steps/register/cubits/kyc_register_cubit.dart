import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:realunit_wallet/packages/service/dfx/exceptions/bitbox_exception.dart';
import 'package:realunit_wallet/packages/service/dfx/models/country/country.dart';
import 'package:realunit_wallet/packages/service/dfx/models/registration/registration.dart';
import 'package:realunit_wallet/packages/service/dfx/models/registration/registration_user_type.dart';
import 'package:realunit_wallet/packages/service/dfx/models/user/dto/real_unit_user_data_dto.dart';
import 'package:realunit_wallet/packages/service/dfx/real_unit_registration_service.dart';

part 'kyc_register_state.dart';

/// Drives the streamlined "Aktionariat registration" confirm-and-sign page.
///
/// The userData is supplied by the parent `KycCubit` (which already fetched it
/// via `getRegistrationInfo()` as part of its routing decision) — this cubit
/// never re-fetches. On submit it forwards the prefilled values to
/// `RealUnitRegistrationService.completeRegistration`, which is the same
/// wire-level call that the previous form page used. Mirror of
/// `KycLinkWalletCubit` for the `NewRegistration` branch — distinct because
/// the API endpoint is `/register/complete` instead of `/register/wallet`.
class KycRegisterCubit extends Cubit<KycRegisterState> {
  final RealUnitRegistrationService _registrationService;

  KycRegisterCubit(
    RealUnitRegistrationService registrationService,
    RealUnitUserDataDto userData,
  ) : _registrationService = registrationService,
      super(_initialFor(userData));

  static KycRegisterState _initialFor(RealUnitUserDataDto userData) {
    return _isProfileComplete(userData)
        ? KycRegisterReady(userData)
        : const KycRegisterProfileIncomplete();
  }

  /// Defensive guard against incomplete prefill payloads. The server contract
  /// for `NewRegistration` always returns a fully populated record, but a
  /// small number of accounts with partial DFX KYC data can slip through —
  /// rather than 400-ing during signature submit, surface a terminal info
  /// state so the user can complete their profile via a separate flow.
  ///
  /// `email` and `address.country` are checked alongside the other required
  /// fields: `email` flows into the EIP-712 envelope built by
  /// `RealUnitRegistrationService.completeRegistration` and a server-side
  /// validation would reject an empty value; `address.country` is an `int`
  /// whose unset default is `0` (a prefill arriving with `country: 0`
  /// otherwise bypasses the guard and triggers a server 400 instead of
  /// routing to the profile-incomplete surface).
  static bool _isProfileComplete(RealUnitUserDataDto u) {
    final kyc = u.kycData;
    final address = kyc.address;
    return u.email.trim().isNotEmpty &&
        u.name.isNotEmpty &&
        u.phoneNumber.isNotEmpty &&
        u.birthday.isNotEmpty &&
        u.nationality.isNotEmpty &&
        u.addressStreet.isNotEmpty &&
        u.addressPostalCode.isNotEmpty &&
        u.addressCity.isNotEmpty &&
        u.addressCountry.isNotEmpty &&
        kyc.firstName.isNotEmpty &&
        kyc.lastName.isNotEmpty &&
        kyc.phone.isNotEmpty &&
        address.street.isNotEmpty &&
        address.city.isNotEmpty &&
        address.zip.isNotEmpty &&
        address.country != 0;
  }

  Future<void> submit(RealUnitUserDataDto userData) async {
    try {
      emit(KycRegisterSubmitting(userData));
      // `completeRegistration` accepts a `Registration` value object — the
      // page already validated the fields are non-empty via the profile-
      // complete check, so the country lookups below are guarded by `!`
      // intentionally. The wire-level POST to `/v1/realunit/register/complete`
      // is unchanged from the previous form-based page.
      final registration = Registration(
        type: RegistrationUserType.fromName(userData.type),
        email: userData.email,
        firstName: userData.kycData.firstName,
        lastName: userData.kycData.lastName,
        phoneNumber: userData.phoneNumber,
        birthday: userData.birthday,
        nationality: Country(
          id: 0,
          symbol: userData.nationality,
          name: userData.nationality,
          kycAllowed: true,
        ),
        addressStreet: userData.addressStreet,
        addressStreetNumber: userData.kycData.address.houseNumber ?? '',
        addressPostalCode: userData.addressPostalCode,
        addressCity: userData.addressCity,
        addressCountry: Country(
          id: userData.kycData.address.country,
          symbol: userData.addressCountry,
          name: userData.addressCountry,
          kycAllowed: true,
        ),
        swissTaxResidence: userData.swissTaxResidence,
      );
      await _registrationService.completeRegistration(registration);
      emit(const KycRegisterSuccess());
    } on BitboxNotConnectedException {
      // Recoverable: the page listens for this state and surfaces the
      // existing `showBitboxReconnectSheet` so the user can re-pair and
      // retry — the registration ceremony is a one-time, heavyweight legal
      // disclaimer + EIP-712 sign, so collapsing a transient BLE drop into
      // a SnackBar would force the user to start over.
      emit(KycRegisterBitboxRequired(userData));
    } catch (e) {
      emit(KycRegisterFailure(e.toString(), cause: e));
    }
  }

  /// Reverts to the interactive Ready surface after the user cancels the
  /// reconnect sheet without re-pairing. Kept separate from `submit` so the
  /// page never has to construct a transient state by hand.
  void revertToReady(RealUnitUserDataDto userData) {
    emit(KycRegisterReady(userData));
  }
}
