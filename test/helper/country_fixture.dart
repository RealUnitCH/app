import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:realunit_wallet/packages/config/api_config.dart';
import 'package:realunit_wallet/packages/config/network_mode.dart';
import 'package:realunit_wallet/packages/service/app_store.dart';
import 'package:realunit_wallet/packages/service/dfx/dfx_country_service.dart';

/// Committed snapshot of the real `GET /v1/country` response (public data, no
/// PII). Fed to a [MockClient] so the real [DfxCountryService] parses the real
/// production shape — no mocking framework stubs the country data. See
/// `docs/testing.md` ("Country data in tests").
const _fixturePath = 'test/fixtures/dfx_countries.json';

/// The raw fixture body, for tests that build their own [http.Response].
String countriesFixtureJson() => File(_fixturePath).readAsStringSync();

/// A `200` response carrying the country fixture. The charset is explicit
/// because the fixture holds non-Latin-1 characters (accented foreign names);
/// without it `http.Response` would default to Latin-1 and throw. Use this to
/// resolve a deferred (`Completer`-gated) or fail-then-recover [MockClient].
http.Response countriesFixtureResponse() => http.Response(
      countriesFixtureJson(),
      200,
      headers: const {'content-type': 'application/json; charset=utf-8'},
    );

class _FixtureAppStore extends Fake implements AppStore {
  _FixtureAppStore(this._client);

  final http.Client _client;

  @override
  http.Client get httpClient => _client;

  @override
  ApiConfig get apiConfig => const ApiConfig(networkMode: NetworkMode.mainnet);
}

/// A real [DfxCountryService] whose only canned seam is [client]. The country
/// data itself is never mocked — it flows through the real service and DTO.
DfxCountryService countryServiceWithClient(http.Client client) =>
    DfxCountryService(_FixtureAppStore(client));

/// A real [DfxCountryService] that serves the committed country fixture for
/// `GET /v1/country`. Use this for golden and widget tests that need a
/// populated country dropdown.
DfxCountryService fixtureCountryService() =>
    countryServiceWithClient(MockClient((_) async => countriesFixtureResponse()));

/// A real [DfxCountryService] whose HTTP layer always fails, so
/// `getAllCountries()` throws. Drives the country field's error branch without
/// a mocktail stub.
DfxCountryService failingCountryService() => countryServiceWithClient(
      MockClient((_) async => http.Response('error', 500)),
    );
