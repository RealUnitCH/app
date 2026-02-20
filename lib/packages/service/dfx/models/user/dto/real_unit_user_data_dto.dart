import 'package:realunit_wallet/packages/service/dfx/models/registration/dto/real_unit_registration_request_dto.dart';
import 'package:realunit_wallet/packages/service/dfx/models/registration/kyc/kyc_personal_data.dart';

class RealUnitUserDataDto {
  final String email;
  final String name;
  final String type;
  final String phoneNumber;
  final String birthday;
  final String nationality;
  final String addressStreet;
  final String addressPostalCode;
  final String addressCity;
  final String addressCountry;
  final bool swissTaxResidence;
  final String lang;
  final List<CountryAndTin>? countryAndTINs;
  final KycPersonalData kycData;

  const RealUnitUserDataDto({
    required this.email,
    required this.name,
    required this.type,
    required this.phoneNumber,
    required this.birthday,
    required this.nationality,
    required this.addressStreet,
    required this.addressPostalCode,
    required this.addressCity,
    required this.addressCountry,
    required this.swissTaxResidence,
    required this.lang,
    this.countryAndTINs,
    required this.kycData,
  });

  factory RealUnitUserDataDto.fromJson(Map<String, dynamic> json) {
    return RealUnitUserDataDto(
      email: json['email'] as String,
      name: json['name'] as String,
      type: json['type'] as String,
      phoneNumber: json['phoneNumber'] as String,
      birthday: json['birthday'] as String,
      nationality: json['nationality'] as String,
      addressStreet: json['addressStreet'] as String,
      addressPostalCode: json['addressPostalCode'] as String,
      addressCity: json['addressCity'] as String,
      addressCountry: json['addressCountry'] as String,
      swissTaxResidence: json['swissTaxResidence'] as bool,
      lang: json['lang'] as String,
      countryAndTINs: json['countryAndTINs'] != null
          ? (json['countryAndTINs'] as List)
                .map((e) => CountryAndTin.fromJson(e as Map<String, dynamic>))
                .toList()
          : null,
      kycData: KycPersonalData.fromJson(json['kycData'] as Map<String, dynamic>),
    );
  }
}
