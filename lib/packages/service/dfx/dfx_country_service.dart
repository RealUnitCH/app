import 'dart:convert';

import 'package:realunit_wallet/packages/service/app_store.dart';
import 'package:realunit_wallet/packages/service/dfx/models/dfx_country.dart';

class DfxCountryService {
  static const _baseUrl = "api.dfx.swiss";
  static const _countryPath = "/v1/country";

  List<DfxCountry>? cachedCountries;

  final AppStore appStore;

  DfxCountryService(this.appStore);

  Future<List<DfxCountry>> getAllCountries() async {
    if (cachedCountries != null) return cachedCountries!;

    final uri = Uri.https(_baseUrl, _countryPath);
    final response = await appStore.httpClient.get(uri);

    if (response.statusCode == 200) {
      final List<dynamic> jsonList = jsonDecode(response.body);
      final countries = jsonList.map((json) => DfxCountry.fromJson(json)).toList();
      cachedCountries = countries;
      return cachedCountries!;
    } else {
      throw Exception('Failed to fetch countries: ${response.statusCode} ${response.body}');
    }
  }

  /// Find a country by its 2-letter symbol (e.g., 'CH')
  Future<DfxCountry?> getCountryBySymbol(String symbol) async {
    final countries = await getAllCountries();
    try {
      return countries.firstWhere(
        (country) => country.symbol.toUpperCase() == symbol.toUpperCase(),
      );
    } catch (_) {
      return null;
    }
  }
}
