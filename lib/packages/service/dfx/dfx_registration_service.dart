import 'dart:convert';

import 'package:realunit_wallet/packages/service/app_store.dart';
import 'package:realunit_wallet/packages/service/dfx/models/registration/dfx_registration.dart';
import 'package:realunit_wallet/packages/service/dfx/models/registration/dfx_registration_request_dto.dart';
import 'package:realunit_wallet/packages/service/dfx/models/registration/dfx_registration_response.dart';
import 'package:realunit_wallet/packages/service/dfx/models/registration/kyc/kyc_personal_data.dart';
import 'package:realunit_wallet/packages/wallet/eip712_signer.dart';

class DfxRegistrationService {
  static const _baseUrl = "dev.api.dfx.swiss";
  static const _registerPath = "/v1/realunit/register";

  final AppStore appStore;

  DfxRegistrationService(this.appStore);

  Future<DfxRegistrationResponseDto> register(DfxRegistration registration) async {
    final credentials = appStore.wallet.primaryAccount.primaryAddress;

    final signature = EIP712Signer.signRegistration(
      credentials: credentials,
      registration: registration,
    );
    final requestDto = DfxRegistrationRequestDto(
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

    final authToken = appStore.dfxAuthToken;

    final uri = Uri.https(_baseUrl, _registerPath);
    final response = await appStore.httpClient.post(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $authToken',
      },
      body: jsonEncode(requestDto.toJson()),
    );

    if (response.statusCode != 200 && response.statusCode != 202) {
      throw Exception("Registration failed: ${response.body}");
    }

    return DfxRegistrationResponseDto.fromJson(jsonDecode(response.body));
  }
}
