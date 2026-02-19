import 'package:realunit_wallet/packages/service/dfx/models/registration/registration_user_type.dart';

class KycPersonalData {
  final KycAccountType accountType;
  final String firstName;
  final String lastName;
  final String phone;
  final KycAddress address;
  final String? organizationName;
  final KycAddress? organizationAddress;

  const KycPersonalData({
    required this.accountType,
    required this.firstName,
    required this.lastName,
    required this.phone,
    required this.address,
    this.organizationName,
    this.organizationAddress,
  });

  factory KycPersonalData.fromJson(Map<String, dynamic> json) {
    return KycPersonalData(
      accountType: KycAccountType.fromJsonName(json['accountType'] as String),
      firstName: json['firstName'] as String,
      lastName: json['lastName'] as String,
      phone: json['phone'] as String,
      address: KycAddress.fromJson(json['address'] as Map<String, dynamic>),
      organizationName: json['organizationName'] as String?,
      organizationAddress: json['organizationAddress'] != null
          ? KycAddress.fromJson(json['organizationAddress'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'accountType': accountType.jsonName,
        'firstName': firstName,
        'lastName': lastName,
        'phone': phone,
        'address': address.toJson(),
        if (organizationName != null) 'organizationName': organizationName,
        if (organizationAddress != null) 'organizationAddress': organizationAddress!.toJson(),
      };
}

enum KycAccountType {
  personal(jsonName: 'Personal'),
  organization(jsonName: 'Organization'),
  soleProprietorship(jsonName: 'SoleProprietorship');

  final String jsonName;

  const KycAccountType({required this.jsonName});

  static KycAccountType fromUserType(RegistrationUserType dfxType) {
    switch (dfxType) {
      case RegistrationUserType.human:
        return KycAccountType.personal;
      case RegistrationUserType.corporation:
        return KycAccountType.organization;
    }
  }

  static KycAccountType fromJsonName(String jsonName) {
    return KycAccountType.values.firstWhere(
      (e) => e.jsonName == jsonName,
      orElse: () => KycAccountType.personal,
    );
  }
}

class KycAddress {
  final String street;
  final String? houseNumber;
  final String zip;
  final String city;
  final int country;

  const KycAddress({
    required this.street,
    this.houseNumber,
    required this.zip,
    required this.city,
    required this.country,
  });

  factory KycAddress.fromJson(Map<String, dynamic> json) {
    final countryData = json['country'];
    final countryId = countryData is Map ? countryData['id'] as int : countryData as int;
    return KycAddress(
      street: json['street'] as String,
      houseNumber: json['houseNumber'] as String?,
      zip: json['zip'] as String,
      city: json['city'] as String,
      country: countryId,
    );
  }

  Map<String, dynamic> toJson() => {
        'street': street,
        if (houseNumber != null) 'houseNumber': houseNumber,
        'zip': zip,
        'city': city,
        'country': {'id': country},
      };
}
