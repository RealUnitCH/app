import 'package:realunit_wallet/packages/service/dfx/models/registration/dfx_user_type.dart';

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

  static KycAccountType fromDfxAccountType(DfxUserType dfxType) {
    switch (dfxType) {
      case DfxUserType.human:
        return KycAccountType.personal;
      case DfxUserType.corporation:
        return KycAccountType.organization;
    }
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

  Map<String, dynamic> toJson() => {
        'street': street,
        if (houseNumber != null) 'houseNumber': houseNumber,
        'zip': zip,
        'city': city,
        'country': {'id': country},
      };
}
