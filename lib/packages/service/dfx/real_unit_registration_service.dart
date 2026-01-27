import 'dart:convert';

import 'package:realunit_wallet/packages/config/api_config.dart';
import 'package:realunit_wallet/packages/service/app_store.dart';
import 'package:realunit_wallet/packages/service/dfx/exceptions/api_exception.dart';
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
  static const _registerEmailPath = '/v1/realunit/register/email';
  static const _registerCompletionPath = '/v1/realunit/register/complete';

  static const _registerPath = '/v1/realunit/register';

  String get _host => _appStore.apiConfig.apiHost;

  final AppStore _appStore;

  RealUnitRegistrationService(AppStore appStore) : _appStore = appStore;

  Future<RegistrationEmailStatus> registerEmail(String email) async {
    final authToken = _appStore.dfxAuthToken;

    final uri = buildUri(_host, _registerEmailPath);
    final response = await _appStore.httpClient.post(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $authToken',
      },
      body: jsonEncode(RealUnitEmailRegistrationRequestDto(email: email)),
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
    final signature = Eip712Signer.signRegistration(
      credentials: credentials,
      registration: registration,
    );
    final requestDto = RealUnitRegistrationRequestDto(
      type: registration.type.jsonName,
      email: registration.email,
      name: '${registration.firstName} ${registration.lastName}',
      phoneNumber: registration.phoneNumber,
      birthday: registration.birthday,
      nationality: registration.nationality.symbol,
      addressStreet: registration.addressStreet,
      addressPostalCode: registration.addressPostalCode,
      addressCity: registration.addressCity,
      addressCountry: registration.addressCountry.symbol,
      swissTaxResidence: true,
      registrationDate: registration.registrationDate,
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
      body: jsonEncode(requestDto.toJson()),
    );

    if (response.statusCode != 201 && response.statusCode != 202) {
      final errorJson = jsonDecode(response.body) as Map<String, dynamic>;
      throw ApiException.fromJson(errorJson);
    }

    final responseDto = RealUnitRegistrationResponseDto.fromJson(jsonDecode(response.body));
    return responseDto.status;
  }

  Future<RegistrationStatus> register(Registration registration) async {
    final credentials = _appStore.wallet.primaryAccount.primaryAddress;
    final signature = Eip712Signer.signRegistration(
      credentials: credentials,
      registration: registration,
    );
    final requestDto = RealUnitRegistrationRequestDto(
      type: registration.type.jsonName,
      email: registration.email,
      name: '${registration.firstName} ${registration.lastName}',
      phoneNumber: registration.phoneNumber,
      birthday: registration.birthday,
      nationality: registration.nationality.symbol,
      addressStreet: registration.addressStreet,
      addressPostalCode: registration.addressPostalCode,
      addressCity: registration.addressCity,
      addressCountry: registration.addressCountry.symbol,
      swissTaxResidence: true,
      registrationDate: registration.registrationDate,
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
          zip: registration.addressPostalCode,
          city: registration.addressCity,
          country: registration.addressCountry.id,
        ),
      ),
    );
    final authToken = _appStore.dfxAuthToken;

    final uri = buildUri(_host, _registerPath);
    final response = await _appStore.httpClient.post(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $authToken',
      },
      body: jsonEncode(requestDto.toJson()),
    );

    if (response.statusCode != 200 && response.statusCode != 202) {
      final messages = jsonDecode(response.body)['message'] is List
          ? List<String>.from(jsonDecode(response.body)['message'])
          : <String>[jsonDecode(response.body)['message']];

      throw Exception(messages.join('\n'));
    }

    final responseDto = RealUnitRegistrationResponseDto.fromJson(jsonDecode(response.body));
    return responseDto.status;
  }
}
