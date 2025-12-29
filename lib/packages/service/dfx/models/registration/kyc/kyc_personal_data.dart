class KycPersonalData {
  final String firstName;
  final String lastName;
  final String phone;
  final KycAddress address;
  final String? organizationName;
  final KycAddress? organizationAddress;

  KycPersonalData({
    required this.firstName,
    required this.lastName,
    required this.phone,
    required this.address,
    this.organizationName,
    this.organizationAddress,
  });

  Map<String, dynamic> toJson() => {
        'accountType': "Personal",
        'firstName': firstName,
        'lastName': lastName,
        'phone': phone,
        'address': address.toJson(),
        if (organizationName != null) 'organizationName': organizationName,
        if (organizationAddress != null) 'organizationAddress': organizationAddress!.toJson(),
      };
}

class KycAddress {
  final String street;
  final String? houseNumber;
  final String zip;
  final String city;
  final int country;

  KycAddress({
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
