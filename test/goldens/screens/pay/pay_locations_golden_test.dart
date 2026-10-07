import 'package:flutter/widgets.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:realunit_wallet/screens/pay/pay_locations_page.dart';
import 'package:realunit_wallet/styles/colors.dart';

import '../../../helper/helper.dart';

const _filtersBody = '{"blockchains":["Ethereum"],"assets":["ZCHF"]}';

const _placesBody =
    '{"places":[{"name":"SPAR Zürich","category":"grocery","lat":47.37,"lon":8.54,'
    '"supports":[{"blockchain":"Ethereum","asset":"ZCHF"}]}]}';

http.Client _client({
  int filtersStatus = 200,
  String filtersBody = _filtersBody,
  String placesBody = '{"places":[]}',
}) {
  return MockClient((request) async {
    if (request.url.path.endsWith('/filters')) {
      return http.Response(filtersBody, filtersStatus);
    }
    return http.Response(placesBody, 200);
  });
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
    builder: () => wrapForGolden(_map(_client(filtersStatus: 500, filtersBody: ''))),
  );

  goldenTest(
    'locations empty',
    fileName: 'pay_locations_page_empty',
    constraints: phoneConstraints,
    builder: () => wrapForGolden(_map(_client())),
  );

  goldenTest(
    'locations with one place',
    fileName: 'pay_locations_page_places',
    constraints: phoneConstraints,
    builder: () => wrapForGolden(_map(_client(placesBody: _placesBody))),
  );
}
