import 'dart:convert';

import 'package:intl/intl.dart';
import 'package:realunit_wallet/packages/config/api_config.dart';
import 'package:realunit_wallet/packages/hardware_wallet/bitbox_credentials.dart';
import 'package:realunit_wallet/packages/service/app_store.dart';
import 'package:realunit_wallet/packages/service/dfx/exceptions/api_exception.dart';
import 'package:realunit_wallet/packages/service/dfx/exceptions/bitbox_exception.dart';
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
import 'package:realunit_wallet/packages/wallet/eip712_signer.dart';

class RealUnitRegistrationService {
  RealUnitRegistrationService(AppStore appStore) : _appStore = appStore;

  static const _registerEmailPath = '/v1/realunit/register/email';
  static const _registerCompletionPath = '/v1/realunit/register/complete';
  static const _registerWalletPath = '/v1/realunit/register/wallet';

  final AppStore _appStore;

  String get _host => _appStore.apiConfig.apiHost;

  int get _chainId => _appStore.apiConfig.asset.chainId;

  /// registers an email on the wallet. Should always be called first when registering
  Future<RegistrationEmailStatus> registerEmail(String email) async {
    final authToken = _appStore.sessionCache.authToken;

    final uri = buildUri(_host, _registerEmailPath);
    final response = await _appStore.httpClient.post(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $authToken',
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
    final credentials = _appStore.wallet.primaryAccount.primaryAddress;
    if (credentials is BitboxCredentials && !credentials.isConnected) {
      throw const BitboxNotConnectedException();
    }
    final name = '${registration.firstName} ${registration.lastName}'.trim();
    final addressStreet = '${registration.addressStreet} ${registration.addressStreetNumber}'
        .trim();
    final registrationDate = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final signature = await Eip712Signer.signRegistration(
      credentials: credentials,
      chainId: _chainId,
      email: registration.email.toLowerCase(),
      name: name,
      type: registration.type.jsonName,
      phoneNumber: registration.phoneNumber,
      birthday: registration.birthday,
      nationality: registration.nationality.symbol,
      addressStreet: addressStreet,
      addressPostalCode: registration.addressPostalCode,
      addressCity: registration.addressCity,
      addressCountry: registration.addressCountry.symbol,
      swissTaxResidence: registration.swissTaxResidence,
      registrationDate: registrationDate,
    );

    final requestDto = RealUnitRegistrationRequestDto(
      type: registration.type.jsonName,
      email: registration.email.toLowerCase(),
      name: name,
      phoneNumber: registration.phoneNumber,
      birthday: registration.birthday,
      nationality: registration.nationality.symbol,
      addressStreet: addressStreet,
      addressPostalCode: registration.addressPostalCode,
      addressCity: registration.addressCity,
      addressCountry: registration.addressCountry.symbol,
      swissTaxResidence: registration.swissTaxResidence,
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
    final authToken = _appStore.sessionCache.authToken;

    final uri = buildUri(_host, _registerCompletionPath);
    final response = await _appStore.httpClient.post(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $authToken',
      },
      body: jsonEncode(requestDto),
    );

    if (response.statusCode != 201 && response.statusCode != 202) {
      final messages = jsonDecode(response.body)['message'] is List
          ? List<String>.from(jsonDecode(response.body)['message'])
          : <String>[jsonDecode(response.body)['message']];

      throw Exception(messages.join('\n'));
    }

    final responseDto = RealUnitRegistrationResponseDto.fromJson(jsonDecode(response.body));
    return responseDto.status;
  }

  /// registers a wallet and adds the wallet to an existing user
  Future<RegistrationStatus> registerWallet(
    RealUnitUserDataDto userData,
  ) async {
    final credentials = _appStore.wallet.primaryAccount.primaryAddress;
    if (credentials is BitboxCredentials && !credentials.isConnected) {
      throw const BitboxNotConnectedException();
    }
    final registrationDate = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final signature = await Eip712Signer.signRegistration(
      credentials: credentials,
      chainId: _chainId,
      email: userData.email,
      name: userData.name,
      type: userData.type,
      phoneNumber: userData.phoneNumber,
      birthday: userData.birthday,
      nationality: userData.nationality,
      addressStreet: userData.addressStreet,
      addressPostalCode: userData.addressPostalCode,
      addressCity: userData.addressCity,
      addressCountry: userData.addressCountry,
      swissTaxResidence: userData.swissTaxResidence,
      registrationDate: registrationDate,
    );

    final requestDto = RealUnitRegisterWalletRequestDto(
      walletAddress: credentials.address.hexEip55,
      signature: signature,
      registrationDate: registrationDate,
    );

    final authToken = _appStore.sessionCache.authToken;

    final uri = buildUri(_host, _registerWalletPath);
    final response = await _appStore.httpClient.post(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $authToken',
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
