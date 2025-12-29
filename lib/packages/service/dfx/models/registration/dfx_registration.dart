class DfxRegistration {
  final String email;
  final String firstName;
  final String lastName;
  final String phoneNumber;
  final String birthday;
  final String nationality;
  final String addressStreet;
  final String addressPostalCode;
  final String addressCity;
  final String addressCountry;
  final bool swissTaxResidence;
  final String registrationDate;

  DfxRegistration({
    required this.email,
    required this.firstName,
    required this.lastName,
    required this.phoneNumber,
    required this.birthday,
    required this.nationality,
    required this.addressStreet,
    required this.addressPostalCode,
    required this.addressCity,
    required this.addressCountry,
    required this.swissTaxResidence,
    required this.registrationDate,
  });
}
