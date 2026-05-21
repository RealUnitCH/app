import 'package:equatable/equatable.dart';
import 'package:realunit_wallet/packages/service/dfx/models/country/dto/dfx_country_dto.dart';

class Country extends Equatable {
  final int id;
  final String symbol;
  final String name;
  final String? foreignName;
  // Lower is higher in country pickers. Default 999 keeps the long tail
  // alphabetic. Backend-tagged via `country.displayOrder`; replaces the
  // hardcoded `priorityCountries = ['CH','DE','IT','FR']` list.
  final int displayOrder;

  const Country({
    required this.id,
    required this.symbol,
    required this.name,
    this.foreignName,
    this.displayOrder = 999,
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
      displayOrder: displayOrder,
    );
  }
}
