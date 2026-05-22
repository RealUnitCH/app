import 'package:equatable/equatable.dart';
import 'package:realunit_wallet/packages/service/dfx/models/country/dto/dfx_country_dto.dart';

class Country extends Equatable {
  final int id;
  final String symbol;
  final String name;
  final String? foreignName;
  // Whether the backend accepts this country as a person's nationality.
  final bool nationalityAllowed;
  // Whether the backend accepts this country as a residence/address country.
  final bool locationAllowed;

  const Country({
    required this.id,
    required this.symbol,
    required this.name,
    required this.nationalityAllowed,
    required this.locationAllowed,
    this.foreignName,
  });

  @override
  List<Object?> get props => [id];
}

extension DfxCountryDtoMapper on DfxCountryDto {
  Country toCountry() {
    return Country(
      id: id,
      symbol: symbol,
      name: name,
      foreignName: foreignName,
      nationalityAllowed: nationalityAllowed,
      locationAllowed: locationAllowed,
    );
  }
}
