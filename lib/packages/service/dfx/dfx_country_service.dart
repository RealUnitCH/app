import 'dart:convert';

import 'package:realunit_wallet/packages/config/api_config.dart';
import 'package:realunit_wallet/packages/service/app_store.dart';
import 'package:realunit_wallet/packages/service/dfx/models/country/country.dart';
import 'package:realunit_wallet/packages/service/dfx/models/country/dto/dfx_country_dto.dart';

class DfxCountryService {
  static const _countryPath = '/v1/country';

  List<Country>? cachedCountries;

  final AppStore _appStore;

  String get _host => _appStore.apiConfig.apiHost;

  DfxCountryService(AppStore appStore) : _appStore = appStore;

  Future<List<Country>> getAllCountries() async {
    if (cachedCountries != null) return cachedCountries!;

    final uri = buildUri(_host, _countryPath);
    final response = await _appStore.httpClient.get(uri);

    if (response.statusCode == 200) {
      final jsonList = jsonDecode(response.body) as List<dynamic>;
      final countries = jsonList
          .map((json) => DfxCountryDto.fromJson(json as Map<String, dynamic>))
          .map((dto) => dto.toCountry())
          .toList();
      cachedCountries = countries;
      return cachedCountries!;
    } else {
      throw Exception('Failed to fetch countries: ${response.statusCode} ${response.body}');
    }
  }

  /// Find a country by its 2-letter symbol (e.g., 'CH')
  Future<Country> getCountryBySymbol(String symbol) async {
    final countries = await getAllCountries();
    try {
      return countries.firstWhere(
        (country) => country.symbol.toUpperCase() == symbol.toUpperCase(),
      );
    } catch (_) {
      throw Exception('Unknown country symbol: $symbol');
    }
  }
}
