import 'package:realunit_wallet/packages/service/dfx/models/country/country.dart';
import 'package:realunit_wallet/packages/service/dfx/models/registration/registration_user_type.dart';

class Registration {
  final RegistrationUserType type;
  final String email;
  final String firstName;
  final String lastName;
  final String phoneNumber;
  final String birthday;
  final Country nationality;
  final String addressStreet;
  final String addressStreetNumber;
  final String addressPostalCode;
  final String addressCity;
  final Country addressCountry;
  final bool swissTaxResidence;
  final String registrationDate;

  const Registration({
    required this.type,
    required this.email,
    required this.firstName,
    required this.lastName,
    required this.phoneNumber,
    required this.birthday,
    required this.nationality,
    required this.addressStreet,
    required this.addressStreetNumber,
    required this.addressPostalCode,
    required this.addressCity,
    required this.addressCountry,
    required this.swissTaxResidence,
    required this.registrationDate,
  });
}
