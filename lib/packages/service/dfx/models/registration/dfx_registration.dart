import 'package:realunit_wallet/packages/service/dfx/models/dfx_country.dart';
import 'package:realunit_wallet/packages/service/dfx/models/registration/dfx_account_type.dart';

class DfxRegistration {
  final DfxAccountType type;
  final String email;
  final String firstName;
  final String lastName;
  final String phoneNumber;
  final String birthday;
  final DfxCountry nationality;
  final String addressStreet;
  final String addressPostalCode;
  final String addressCity;
  final DfxCountry addressCountry;
  final bool swissTaxResidence;
  final String registrationDate;

  DfxRegistration({
    required this.type,
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
