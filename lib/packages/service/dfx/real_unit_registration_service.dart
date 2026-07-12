import 'dart:convert';

import 'package:intl/intl.dart';
import 'package:realunit_wallet/packages/config/api_config.dart';
import 'package:realunit_wallet/packages/service/dfx/dfx_auth_service.dart';
import 'package:realunit_wallet/packages/service/dfx/exceptions/api_exception.dart';
import 'package:realunit_wallet/packages/service/dfx/models/registration/dto/real_unit_registration_email_request_dto.dart';
import 'package:realunit_wallet/packages/service/dfx/models/registration/dto/real_unit_registration_email_response_dto.dart';
import 'package:realunit_wallet/packages/service/dfx/models/registration/dto/real_unit_registration_register_wallet_request_dto.dart';
import 'package:realunit_wallet/packages/service/dfx/models/registration/dto/real_unit_registration_request_dto.dart';
import 'package:realunit_wallet/packages/service/dfx/models/registration/dto/real_unit_registration_response_dto.dart';
import 'package:realunit_wallet/packages/service/dfx/models/registration/kyc/kyc_personal_data.dart';
import 'package:realunit_wallet/packages/service/dfx/models/registration/registration.dart';
import 'package:realunit_wallet/packages/service/dfx/models/registration/registration_email_status.dart';
import 'package:realunit_wallet/packages/service/dfx/models/registration/registration_status.dart';
import 'package:realunit_wallet/packages/service/dfx/models/user/dto/real_unit_user_data_dto.dart';
import 'package:realunit_wallet/packages/service/dfx/models/wallet/real_unit_registration_info_dto.dart';
import 'package:realunit_wallet/packages/utils/ascii_transliterate.dart';
import 'package:realunit_wallet/packages/wallet/eip712_signer.dart';

class RealUnitRegistrationService extends DFXAuthService {
  RealUnitRegistrationService(super.appStore, super.walletService);

  static const _registrationInfoPath = '/v1/realunit/registration';
  static const _registerEmailPath = '/v1/realunit/register/email';
  static const _registerCompletionPath = '/v1/realunit/register/complete';
  static const _registerWalletPath = '/v1/realunit/register/wallet';

  int get _chainId => appStore.apiConfig.asset.chainId;

  /// Fetches the API-side registration routing decision for the current
  /// wallet. The backend computes whether this wallet needs a full
  /// registration form, a one-tap "add wallet" confirmation, is already
  /// registered, or is blocked on KYC — see `RealUnitRegistrationState`.
  /// Renamed from the deprecated `/v1/realunit/wallet/status` mirror.
  Future<RealUnitRegistrationInfoDto> getRegistrationInfo() async {
    final uri = buildUri(host, _registrationInfoPath);
    final response = await authenticatedGet(
      uri,
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode != 200) {
      final errorJson = jsonDecode(response.body) as Map<String, dynamic>;
      throw ApiException.fromJson(errorJson, httpStatusCode: response.statusCode);
    }

    return RealUnitRegistrationInfoDto.fromJson(jsonDecode(response.body));
  }

  /// registers an email on the wallet. Should always be called first when registering
  Future<RegistrationEmailStatus> registerEmail(String email) async {
    final uri = buildUri(host, _registerEmailPath);
    final response = await authenticatedPost(
      uri,
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode(
        RealUnitEmailRegistrationRequestDto(
          email: email.toLowerCase(),
        ),
      ),
    );

    if (response.statusCode != 201 && response.statusCode != 202) {
      final errorJson = jsonDecode(response.body) as Map<String, dynamic>;
      throw ApiException.fromJson(errorJson, httpStatusCode: response.statusCode);
    }
    final responseDto = RealUnitRegistrationEmailResponseDto.fromJson(jsonDecode(response.body));
    return responseDto.status;
  }

  /// registers a wallet and and adds the wallet to the new user
  Future<RegistrationStatus> completeRegistration(Registration registration) async {
    // EIP-712 registration signature requires the private key — promote the
    // view-wallet (if any) to a fully unlocked SoftwareWallet first, then
    // lock back down in the finally so a throw mid-sequence doesn't leave the
    // key resident.
    await walletService.ensureCurrentWalletUnlocked();
    try {
      return await _completeRegistration(registration);
    } finally {
      await walletService.lockCurrentWallet();
    }
  }

  Future<RegistrationStatus> _completeRegistration(Registration registration) async {
    final credentials = appStore.wallet.primaryAccount.primaryAddress;
    // BitBox firmware rejects non-ASCII bytes in EIP-712 string fields.
    // Transliterate everything that goes into the signed envelope AND the
    // matching DTO copy so the signed hash matches the backend-stored data
    // byte-for-byte. KYC personal data below keeps the original spelling so
    // ID-verification still sees the legal name with diacritics.
    final email = toBitboxSafeAscii(registration.email.toLowerCase());
    final name = toBitboxSafeAscii(
      '${registration.firstName} ${registration.lastName}'.trim(),
    );
    final phoneNumber = toBitboxSafeAscii(registration.phoneNumber);
    final birthday = toBitboxSafeAscii(registration.birthday);
    final addressStreet = toBitboxSafeAscii(
      '${registration.addressStreet} ${registration.addressStreetNumber}'.trim(),
    );
    final addressPostalCode = toBitboxSafeAscii(registration.addressPostalCode);
    final addressCity = toBitboxSafeAscii(registration.addressCity);
    final registrationDate = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final signature = await Eip712Signer.signRegistration(
      credentials: credentials,
      chainId: _chainId,
      email: email,
      name: name,
      type: registration.type.jsonName,
      phoneNumber: phoneNumber,
      birthday: birthday,
      nationality: registration.nationality.symbol,
      addressStreet: addressStreet,
      addressPostalCode: addressPostalCode,
      addressCity: addressCity,
      addressCountry: registration.addressCountry.symbol,
      swissTaxResidence: registration.swissTaxResidence,
      registrationDate: registrationDate,
    );

    final requestDto = RealUnitRegistrationRequestDto(
      type: registration.type.jsonName,
      email: email,
      name: name,
      phoneNumber: phoneNumber,
      birthday: birthday,
      nationality: registration.nationality.symbol,
      addressStreet: addressStreet,
      addressPostalCode: addressPostalCode,
      addressCity: addressCity,
      addressCountry: registration.addressCountry.symbol,
      swissTaxResidence: registration.swissTaxResidence,
      countryAndTINs: registration.countryAndTINs,
      registrationDate: registrationDate,
      walletAddress: credentials.address.hexEip55,
      signature: signature,
      lang: 'DE',
      kycData: KycPersonalData(
        accountType: KycAccountType.fromUserType(registration.type),
        firstName: registration.firstName,
        lastName: registration.lastName,
        phone: registration.phoneNumber,
        address: KycAddress(
          street: registration.addressStreet,
          houseNumber: registration.addressStreetNumber,
          zip: registration.addressPostalCode,
          city: registration.addressCity,
          country: registration.addressCountry.id,
        ),
      ),
    );

    final uri = buildUri(host, _registerCompletionPath);
    final response = await authenticatedPost(
      uri,
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode(requestDto),
    );

    if (response.statusCode != 201 && response.statusCode != 202) {
      final errorJson = jsonDecode(response.body) as Map<String, dynamic>;
      throw ApiException.fromJson(errorJson, httpStatusCode: response.statusCode);
    }

    final responseDto = RealUnitRegistrationResponseDto.fromJson(jsonDecode(response.body));
    return responseDto.status;
  }

  /// registers a wallet and adds the wallet to an existing user
  Future<RegistrationStatus> registerWallet(
    RealUnitUserDataDto userData,
  ) async {
    await walletService.ensureCurrentWalletUnlocked();
    try {
      return await _registerWallet(userData);
    } finally {
      await walletService.lockCurrentWallet();
    }
  }

  Future<RegistrationStatus> _registerWallet(RealUnitUserDataDto userData) async {
    final credentials = appStore.wallet.primaryAccount.primaryAddress;
    final registrationDate = DateFormat('yyyy-MM-dd').format(DateTime.now());
    // Same ASCII guard as completeRegistration — see comment there.
    final signature = await Eip712Signer.signRegistration(
      credentials: credentials,
      chainId: _chainId,
      email: toBitboxSafeAscii(userData.email),
      name: toBitboxSafeAscii(userData.name),
      type: userData.type,
      phoneNumber: toBitboxSafeAscii(userData.phoneNumber),
      birthday: toBitboxSafeAscii(userData.birthday),
      nationality: userData.nationality,
      addressStreet: toBitboxSafeAscii(userData.addressStreet),
      addressPostalCode: toBitboxSafeAscii(userData.addressPostalCode),
      addressCity: toBitboxSafeAscii(userData.addressCity),
      addressCountry: userData.addressCountry,
      swissTaxResidence: userData.swissTaxResidence,
      registrationDate: registrationDate,
    );

    final requestDto = RealUnitRegisterWalletRequestDto(
      walletAddress: credentials.address.hexEip55,
      signature: signature,
      registrationDate: registrationDate,
    );

    final uri = buildUri(host, _registerWalletPath);
    final response = await authenticatedPost(
      uri,
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode(requestDto),
    );

    if (response.statusCode != 201 && response.statusCode != 202) {
      final errorJson = jsonDecode(response.body) as Map<String, dynamic>;
      throw ApiException.fromJson(errorJson, httpStatusCode: response.statusCode);
    }

    final responseDto = RealUnitRegistrationResponseDto.fromJson(jsonDecode(response.body));
    return responseDto.status;
  }
}
