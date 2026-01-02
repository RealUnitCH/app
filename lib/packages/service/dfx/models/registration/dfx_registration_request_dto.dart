import 'package:realunit_wallet/packages/service/dfx/models/registration/kyc/kyc_personal_data.dart';

class DfxRegistrationRequestDto {
  final String type;
  final String email;
  final String name;
  final String phoneNumber;
  final String birthday;
  final String nationality;
  final String addressStreet;
  final String addressPostalCode;
  final String addressCity;
  final String addressCountry;
  final bool swissTaxResidence;
  final String registrationDate;
  final String walletAddress;
  final String signature;
  final String lang;
  final KycPersonalData kycData;
  final List<CountryAndTin>? countryAndTINs;

  const DfxRegistrationRequestDto({
    required this.type,
    required this.email,
    required this.name,
    required this.phoneNumber,
    required this.birthday,
    required this.nationality,
    required this.addressStreet,
    required this.addressPostalCode,
    required this.addressCity,
    required this.addressCountry,
    required this.swissTaxResidence,
    required this.registrationDate,
    required this.walletAddress,
    required this.signature,
    required this.lang,
    required this.kycData,
    this.countryAndTINs,
  });

  Map<String, dynamic> toJson() => {
        'email': email,
        'name': name,
        'type': type,
        'phoneNumber': phoneNumber,
        'birthday': birthday,
        'nationality': nationality,
        'addressStreet': addressStreet,
        'addressPostalCode': addressPostalCode,
        'addressCity': addressCity,
        'addressCountry': addressCountry,
        'swissTaxResidence': swissTaxResidence,
        'registrationDate': registrationDate,
        'walletAddress': walletAddress,
        'signature': signature,
        'lang': lang,
        'kycData': kycData.toJson(),
        if (countryAndTINs != null)
          'countryAndTINs': countryAndTINs!.map((e) => e.toJson()).toList(),
      };
}

class CountryAndTin {
  final String country;
  final String tin;

  const CountryAndTin({
    required this.country,
    required this.tin,
  });

  Map<String, dynamic> toJson() => {
        'country': country,
        'tin': tin,
      };
}
