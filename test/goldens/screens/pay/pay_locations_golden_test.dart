import 'dart:convert';
import 'dart:io';

import 'package:alchemist/alchemist.dart' show precacheImages;
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:realunit_wallet/screens/pay/pay_locations.dart';
import 'package:realunit_wallet/screens/pay/pay_locations_page.dart';
import 'package:realunit_wallet/styles/colors.dart';

import '../../../helper/helper.dart';

const _placesBody =
    '{"places":[{"name":"SPAR Zürich","category":"grocery","lat":47.37,"lon":8.54,'
    '"supports":[{"blockchain":"Ethereum","asset":"ZCHF"}]}]}';

final String _publishedPlacesBody = File(
  'test/goldens/screens/pay/fixtures/dev_places_ethereum_zchf.json',
).readAsStringSync();

http.Client _client({
  int placesStatus = 200,
  String placesBody = '{"places":[]}',
}) {
  return MockClient((request) async {
    if (request.url.toString() != payLocationsPlacesUrl) {
      return http.Response('unexpected', 500);
    }
    return http.Response.bytes(
      utf8.encode(placesBody),
      placesStatus,
      headers: const {'content-type': 'application/json; charset=utf-8'},
    );
  });
}

/// The street snapshot is mounted only after the place response. Load it, then precache.
Future<void> _pumpPayLocations(WidgetTester tester) async {
  await tester.pumpAndSettle();
  await precacheImages(tester);
}

Widget _map(http.Client client) {
  return PayLocationsPage(
    httpClient: client,
    mapBuilder: (_) => const ColoredBox(color: RealUnitColors.neutral100),
  );
}

void main() {
  // The indicator animates forever, so the loading shot is the first frame.
  goldenTest(
    'locations loading',
    fileName: 'pay_locations_page_loading',
    constraints: phoneConstraints,
    pumpBeforeTest: pumpOnce,
    builder: () => wrapForGolden(const PayLocationsPage(loadOnStart: false)),
  );

  goldenTest(
    'locations error',
    fileName: 'pay_locations_page_error',
    constraints: phoneConstraints,
    builder: () => wrapForGolden(_map(_client(placesStatus: 500, placesBody: ''))),
  );

  goldenTest(
    'published locations',
    fileName: 'pay_locations_page_empty',
    constraints: phoneConstraints,
    pumpBeforeTest: _pumpPayLocations,
    builder: () => wrapForGolden(
      PayLocationsPage(httpClient: _client(placesBody: _publishedPlacesBody)),
    ),
  );

  goldenTest(
    'locations with nothing published',
    fileName: 'pay_locations_page_unpublished',
    constraints: phoneConstraints,
    pumpBeforeTest: _pumpPayLocations,
    builder: () => wrapForGolden(PayLocationsPage(httpClient: _client())),
  );

  goldenTest(
    'locations with one place',
    fileName: 'pay_locations_page_places',
    constraints: phoneConstraints,
    pumpBeforeTest: _pumpPayLocations,
    builder: () => wrapForGolden(
      PayLocationsPage(httpClient: _client(placesBody: _placesBody)),
    ),
  );

  goldenTest(
    'locations with no search match',
    fileName: 'pay_locations_page_no_match',
    constraints: phoneConstraints,
    pumpBeforeTest: _pumpPayLocations,
    builder: () => wrapForGolden(
      PayLocationsPage(
        httpClient: _client(placesBody: _publishedPlacesBody),
        initialQuery: 'zzzz',
      ),
    ),
  );

  goldenTest(
    'locations activity daily',
    fileName: 'pay_locations_page_activity_daily',
    constraints: phoneConstraints,
    pumpBeforeTest: _pumpPayLocations,
    builder: () => wrapForGolden(
      PayLocationsPage(httpClient: _client(placesBody: _activityBody('daily'))),
    ),
  );

  goldenTest(
    'locations activity weekly',
    fileName: 'pay_locations_page_activity_weekly',
    constraints: phoneConstraints,
    pumpBeforeTest: _pumpPayLocations,
    builder: () => wrapForGolden(
      PayLocationsPage(httpClient: _client(placesBody: _activityBody('within7Days'))),
    ),
  );

  goldenTest(
    'locations activity monthly',
    fileName: 'pay_locations_page_activity_monthly',
    constraints: phoneConstraints,
    pumpBeforeTest: _pumpPayLocations,
    builder: () => wrapForGolden(
      PayLocationsPage(httpClient: _client(placesBody: _activityBody('within30Days'))),
    ),
  );

  goldenTest(
    'locations activity idle',
    fileName: 'pay_locations_page_activity_idle',
    constraints: phoneConstraints,
    pumpBeforeTest: _pumpPayLocations,
    builder: () => wrapForGolden(
      PayLocationsPage(httpClient: _client(placesBody: _activityBody('olderThan30Days'))),
    ),
  );

  goldenTest(
    'location details daily',
    fileName: 'pay_locations_detail_daily',
    constraints: phoneConstraints,
    pumpBeforeTest: _pumpOpenedDetails,
    builder: () => wrapForGolden(
      PayLocationsPage(httpClient: _client(placesBody: _detailBody('daily'))),
    ),
  );

  goldenTest(
    'location details weekly',
    fileName: 'pay_locations_detail_weekly',
    constraints: phoneConstraints,
    pumpBeforeTest: _pumpOpenedDetails,
    builder: () => wrapForGolden(
      PayLocationsPage(httpClient: _client(placesBody: _detailBody('within7Days'))),
    ),
  );

  goldenTest(
    'location details monthly',
    fileName: 'pay_locations_detail_monthly',
    constraints: phoneConstraints,
    pumpBeforeTest: _pumpOpenedDetails,
    builder: () => wrapForGolden(
      PayLocationsPage(httpClient: _client(placesBody: _detailBody('within30Days'))),
    ),
  );

  goldenTest(
    'location details idle',
    fileName: 'pay_locations_detail_idle',
    constraints: phoneConstraints,
    pumpBeforeTest: _pumpOpenedDetails,
    builder: () => wrapForGolden(
      PayLocationsPage(httpClient: _client(placesBody: _detailBody('olderThan30Days'))),
    ),
  );

  goldenTest(
    'location details none',
    fileName: 'pay_locations_detail_none',
    constraints: phoneConstraints,
    pumpBeforeTest: _pumpOpenedDetails,
    builder: () => wrapForGolden(
      PayLocationsPage(httpClient: _client(placesBody: _detailBody('none'))),
    ),
  );
}

String _activityBody(String activity) {
  return '{"places":[{"name":"SPAR Zürich","lat":47.37,"lon":8.54,'
      '"activity":"$activity",'
      '"supports":[{"blockchain":"Ethereum","asset":"ZCHF"}]}]}';
}

String _detailBody(String activity) {
  return '{"places":[{"id":"npub1shop","name":"SPAR Zürich","category":"Lebensmittel",'
      '"lat":47.37,"lon":8.54,"activity":"$activity",'
      '"description":"Ein Geschäft mit ZCHF.",'
      '"techProvider":"DFX.swiss","shopType":"SPAR",'
      '"street":"Bahnhofstrasse","houseNumber":"1",'
      '"postalCode":"8001","city":"Zürich","country":"Schweiz",'
      '"supports":[{"blockchain":"Ethereum","asset":"ZCHF"}]}]}';
}

Future<void> _pumpOpenedDetails(WidgetTester tester) async {
  await tester.pumpAndSettle();
  await precacheImages(tester);
  await tester.ensureVisible(find.text('SPAR Zürich'));
  await tester.tap(find.text('SPAR Zürich'));
  await tester.pumpAndSettle();
}
