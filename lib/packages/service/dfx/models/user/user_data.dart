import 'package:equatable/equatable.dart';
import 'package:realunit_wallet/packages/service/dfx/models/country/country.dart';
import 'package:realunit_wallet/packages/service/dfx/models/registration/registration_user_type.dart';

class UserData extends Equatable {
  final RegistrationUserType type;
  final String email;
  final String name;
  final String phoneNumber;
  final DateTime? birthday;
  final Country nationality;
  final String addressStreet;
  final String addressPostalCode;
  final String addressCity;
  final Country addressCountry;
  final bool swissTaxResidence;
  final String lang;

  const UserData({
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
  });

  @override
  List<Object?> get props => [
    type,
    email,
    name,
    phoneNumber,
    birthday,
    nationality,
    addressStreet,
    addressPostalCode,
    addressCity,
    addressCountry,
    swissTaxResidence,
    lang,
  ];
}
