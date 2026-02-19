import 'dart:convert';

import 'package:intl/intl.dart';
import 'package:realunit_wallet/packages/config/api_config.dart';
import 'package:realunit_wallet/packages/service/app_store.dart';
import 'package:realunit_wallet/packages/service/dfx/exceptions/api_exception.dart';
import 'package:realunit_wallet/packages/service/dfx/models/registration/dto/real_unit_account_merge_user_data_dto.dart';
import 'package:realunit_wallet/packages/service/dfx/models/registration/dto/real_unit_registration_email_request_dto.dart';
import 'package:realunit_wallet/packages/service/dfx/models/registration/dto/real_unit_registration_email_response_dto.dart';
import 'package:realunit_wallet/packages/service/dfx/models/registration/dto/real_unit_registration_request_dto.dart';
import 'package:realunit_wallet/packages/service/dfx/models/registration/dto/real_unit_registration_response_dto.dart';
import 'package:realunit_wallet/packages/service/dfx/models/registration/kyc/kyc_personal_data.dart';
import 'package:realunit_wallet/packages/service/dfx/models/registration/registration.dart';
import 'package:realunit_wallet/packages/service/dfx/models/registration/registration_email_status.dart';
import 'package:realunit_wallet/packages/service/dfx/models/registration/registration_status.dart';
import 'package:realunit_wallet/packages/wallet/eip712_signer.dart';

class RealUnitRegistrationService {
  RealUnitRegistrationService(AppStore appStore) : _appStore = appStore;

  static const _registerStatusPath = '/v1/realunit/register/status';
  static const _registerEmailPath = '/v1/realunit/register/email';
  static const _registerCompletionPath = '/v1/realunit/register/complete';
  static const _registerAccountMergeDataPath = '/v1/realunit/register/account-merge-data';
  static const _registerCompleteAccountMergePath = '/v1/realunit/register/complete-account-merge';

  final AppStore _appStore;

  String get _host => _appStore.apiConfig.apiHost;

  Future<bool> checkRegistrationStatus() async {
    final authToken = _appStore.dfxAuthToken;

    final uri = buildUri(_host, _registerStatusPath);
    final response = await _appStore.httpClient.get(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $authToken',
      },
    );

    if (response.statusCode != 200) {
      final errorJson = jsonDecode(response.body) as Map<String, dynamic>;
      throw ApiException.fromJson(errorJson);
    }
    return jsonDecode(response.body) as bool;
  }

  Future<RegistrationEmailStatus> registerEmail(String email) async {
    final authToken = _appStore.dfxAuthToken;

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
      throw ApiException.fromJson(errorJson);
    }
    final responseDto = RealUnitRegistrationEmailResponseDto.fromJson(jsonDecode(response.body));
    return responseDto.status;
  }

  Future<RegistrationStatus> completeRegistration(Registration registration) async {
    final credentials = _appStore.wallet.primaryAccount.primaryAddress;
    final name = '${registration.firstName} ${registration.lastName}'.trim();
    final addressStreet = '${registration.addressStreet} ${registration.addressStreetNumber}'
        .trim();
    final registrationDate = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final signature = Eip712Signer.signRegistration(
      credentials: credentials,
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
    final authToken = _appStore.dfxAuthToken;

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

  /// Gets RealUnit registration data from user
  Future<RealUnitAccountMergeUserDataDto> getAccountMergeUserData() async {
    final authToken = _appStore.dfxAuthToken;

    final uri = buildUri(_host, _registerAccountMergeDataPath);
    final response = await _appStore.httpClient.get(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $authToken',
      },
    );

    if (response.statusCode != 200) {
      final errorJson = jsonDecode(response.body) as Map<String, dynamic>;
      throw ApiException.fromJson(errorJson);
    }

    return RealUnitAccountMergeUserDataDto.fromJson(jsonDecode(response.body));
  }

  /// Completes RealUnit registration with data from `getAccountMergeUserData()` endpoint
  Future<RegistrationStatus> completeAccountMergeRegistration(
    RealUnitAccountMergeUserDataDto userData,
  ) async {
    final credentials = _appStore.wallet.primaryAccount.primaryAddress;
    final registrationDate = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final signature = Eip712Signer.signRegistration(
      credentials: credentials,
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

    final requestDto = RealUnitCompleteAccountMergeRegistrationDto(
      walletAddress: credentials.address.hexEip55,
      signature: signature,
      registrationDate: registrationDate,
    );

    final authToken = _appStore.dfxAuthToken;

    final uri = buildUri(_host, _registerCompleteAccountMergePath);
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
      throw ApiException.fromJson(errorJson);
    }

    final responseDto = RealUnitRegistrationResponseDto.fromJson(jsonDecode(response.body));
    return responseDto.status;
  }
}
