import 'dart:convert';
import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:realunit_wallet/screens/pay/pay_locations.dart';
import 'package:realunit_wallet/screens/pay/pay_locations_lakes.dart';
import 'package:realunit_wallet/screens/pay/pay_locations_outline.dart';
import 'package:realunit_wallet/screens/pay/pay_locations_page.dart';

import '../../helper/pump_golden_app.dart';

void main() {
  test('requests only ZCHF on Ethereum', () {
    expect(
      payLocationsPlacesUrl,
      'https://api.opencryptopay.io/map/places?blockchain=Ethereum&asset=ZCHF',
    );
    expect(payLocationsBlockchain, 'Ethereum');
    expect(payLocationsAsset, 'ZCHF');
  });

  test('a places body must be a map whose places field is a list', () {
    expect(payLocationsPlacesBodyIsList({'places': []}), isTrue);
    expect(
      payLocationsPlacesBodyIsList({
        'places': <Object?>[{}],
      }),
      isTrue,
    );
    expect(payLocationsPlacesBodyIsList([]), isFalse);
    expect(payLocationsPlacesBodyIsList(null), isFalse);
    expect(payLocationsPlacesBodyIsList(1), isFalse);
    expect(payLocationsPlacesBodyIsList({'places': <String, Object>{}}), isFalse);
    expect(payLocationsPlacesBodyIsList(<String, Object>{}), isFalse);
  });

  test('drops a place without ZCHF on Ethereum', () {
    final pins = keepPayLocationPins({
      'places': [
        {
          'name': 'Shop',
          'lat': 47,
          'lon': 8,
          'supports': [
            {'blockchain': 'Ethereum', 'asset': 'USDT'},
            {'blockchain': 'Polygon', 'asset': 'ZCHF'},
            {'blockchain': 'Ethereum', 'asset': 'dEURO'},
          ],
        },
      ],
    });

    expect(pins, isEmpty);
  });

  test('drops a place with a non-finite coordinate', () {
    final pins = keepPayLocationPins({
      'places': [
        {
          'name': 'Shop',
          'lat': double.nan,
          'lon': 8,
          'supports': [
            {'blockchain': 'Ethereum', 'asset': 'ZCHF'},
          ],
        },
      ],
    });

    expect(pins, isEmpty);
  });

  test('drops a place without a usable name', () {
    final pins = keepPayLocationPins({
      'places': [
        {'lat': 47, 'lon': 8},
        {'name': '', 'lat': 47.1, 'lon': 8.1},
        {'name': '   ', 'lat': 47.2, 'lon': 8.2},
        {'name': 12, 'lat': 47.3, 'lon': 8.3},
        {'name': ' SPAR ', 'lat': 47.4, 'lon': 8.4},
      ],
    });

    expect(pins, hasLength(1));
    expect(pins.single.name, 'SPAR');
  });

  test('keeps or drops a place by its supports field', () {
    List<String> namesOf(Object? supports, {bool includeSupports = true}) {
      return keepPayLocationPins({
        'places': [
          {
            'name': 'Shop',
            'lat': 47,
            'lon': 8,
            if (includeSupports) 'supports': supports,
          },
        ],
      }).map((pin) => pin.name).toList();
    }

    expect(namesOf(null, includeSupports: false), ['Shop']);
    expect(namesOf(null), ['Shop']);
    expect(namesOf(<Object?>[]), ['Shop']);
    expect(
      namesOf([
        {'blockchain': 'Ethereum', 'asset': 'ZCHF'},
      ]),
      ['Shop'],
    );
    expect(
      namesOf([
        {'blockchain': 'Bitcoin', 'asset': 'BTC'},
      ]),
      isEmpty,
    );
    expect(namesOf('x'), isEmpty);
  });

  test('keeps the published dev place list', () {
    final pins = keepPayLocationPins(
      jsonDecode(
        File(
          'test/goldens/screens/pay/fixtures/dev_places_ethereum_zchf.json',
        ).readAsStringSync(),
      ),
    );

    expect(pins, hasLength(170));
    expect(
      pins.every((pin) => pin.lat >= 46 && pin.lat <= 48 && pin.lon >= 7 && pin.lon <= 10),
      isTrue,
    );
  });

  testWidgets('shows the empty card when no place is published', (tester) async {
    await tester.pumpWidget(
      wrapForGolden(
        PayLocationsPage(
          httpClient: MockClient(
            (request) async => http.Response.bytes(
              utf8.encode('{"places":[]}'),
              200,
              headers: const {'content-type': 'application/json; charset=utf-8'},
            ),
          ),
          mapBuilder: (_) => const SizedBox.shrink(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Noch keine Standorte veröffentlicht.'), findsOneWidget);
  });

  testWidgets('list row uses parsed place for old names and addressLine for new pins', (
    tester,
  ) async {
    const oldName = 'SPAR Bahnhofstrasse 1, 8001 Zürich';
    final oldLabel = payLocationLabel(oldName);
    const newPin = PayLocationPin(
      name: 'SPAR Zürich',
      category: null,
      lat: 47.38,
      lon: 8.55,
      street: 'Bahnhofstrasse',
      houseNumber: '1',
      postalCode: '8001',
      city: 'Zürich',
    );

    await tester.pumpWidget(
      wrapForGolden(
        PayLocationsPage(
          httpClient: MockClient(
            (request) async => http.Response.bytes(
              utf8.encode(
                jsonEncode({
                  'places': [
                    {'name': oldName, 'lat': 47.37, 'lon': 8.54},
                    {
                      'name': newPin.name,
                      'lat': newPin.lat,
                      'lon': newPin.lon,
                      'street': newPin.street,
                      'houseNumber': newPin.houseNumber,
                      'postalCode': newPin.postalCode,
                      'city': newPin.city,
                    },
                  ],
                }),
              ),
              200,
              headers: const {'content-type': 'application/json; charset=utf-8'},
            ),
          ),
          mapBuilder: (_) => const SizedBox.shrink(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text(oldLabel.place), findsOneWidget);
    expect(find.text(oldLabel.street!), findsOneWidget);
    expect(find.text(oldName), findsNothing);
    expect(find.text(newPin.name), findsOneWidget);
    expect(find.text(newPin.addressLine), findsOneWidget);
  });

  test('keeps a decoded place that accepts ZCHF on Ethereum', () {
    final pins = keepPayLocationPins(
      jsonDecode(
        '{"places":[{"name":"Shop","category":"store","lat":47.1,"lon":8.2,'
        '"supports":[{"blockchain":"Ethereum","asset":"ZCHF"}]}]}',
      ),
    );

    expect(pins, hasLength(1));
    expect(pins.single.name, 'Shop');
    expect(pins.single.category, 'store');
  });

  test('groups nearby shops and keeps distant shops apart', () {
    const near = PayLocationPin(name: 'A', category: null, lat: 47.37, lon: 8.54);
    const close = PayLocationPin(name: 'B', category: null, lat: 47.4, lon: 8.56);
    const far = PayLocationPin(name: 'C', category: null, lat: 46.2, lon: 6.14);
    final clusters = clusterPayLocationPins(
      const [near, close, far],
      cellDegrees: 0.5,
    );

    expect(clusters, hasLength(2));
    expect(clusters.map((cluster) => cluster.pins.length).toSet(), {2, 1});
    expect(
      payLocationClusterCellDegrees(8),
      lessThan(payLocationClusterCellDegrees(6)),
    );
  });

  test('filters and sorts shop names', () {
    const zurich = PayLocationPin(name: 'SPAR Zürich', category: null, lat: 47, lon: 8);
    const bern = PayLocationPin(name: 'SPAR Bern', category: null, lat: 46.9, lon: 7.4);
    final filtered = filterPayLocationPins(const [zurich, bern], 'bern');

    expect(filtered, [bern]);
    expect(sortPayLocationPins(const [zurich, bern]).map((pin) => pin.name), [
      'SPAR Bern',
      'SPAR Zürich',
    ]);
    expect(samePayLocationPin(bern, bern), isTrue);
    expect(samePayLocationPin(bern, zurich), isFalse);
  });

  test('joins a structured address into one line', () {
    const pin = PayLocationPin(
      name: 'SPAR Triesen',
      category: null,
      lat: 47.116,
      lon: 9.524,
      street: 'Maschlinastrasse',
      houseNumber: '4',
      postalCode: '9495',
      city: 'Triesen',
    );
    expect(pin.addressLine, 'Maschlinastrasse 4, 9495 Triesen');

    const withoutHouse = PayLocationPin(
      name: 'SPAR',
      category: null,
      lat: 47,
      lon: 8,
      street: 'Bahnhofstrasse',
      postalCode: '8001',
      city: 'Zürich',
    );
    expect(withoutHouse.addressLine, 'Bahnhofstrasse, 8001 Zürich');
  });

  test('falls back to splitting the name when city is missing', () {
    final label = payLocationLabel('SPAR Bahnhofstrasse 1, 9403 Goldach');

    expect(label.place, '9403 Goldach');
    expect(label.street, 'SPAR Bahnhofstrasse 1');
    expect(label.town, 'Goldach');

    final plain = payLocationLabel('SPAR Zürich');
    expect(plain.place, 'SPAR Zürich');
    expect(plain.street, isNull);
    expect(plain.town, 'SPAR Zürich');

    final dashed = payLocationLabel('SPAR Seestrasse 1–3, 8640 Rapperswil');
    expect(dashed.street, 'SPAR Seestrasse 1–3');
    expect(dashed.town, 'Rapperswil');

    final fromCity = payLocationLabel(
      'SPAR Triesen',
      city: 'Triesen',
      street: 'Maschlinastrasse',
      houseNumber: '4',
    );
    expect(fromCity.place, 'Triesen');
    expect(fromCity.street, 'Maschlinastrasse 4');
    expect(fromCity.town, 'Triesen');
  });

  test('sorts shops by city', () {
    const zurich = PayLocationPin(
      name: 'SPAR',
      category: null,
      lat: 47.37,
      lon: 8.54,
      city: 'Zürich',
      street: 'Bahnhofstrasse',
    );
    const bern = PayLocationPin(
      name: 'SPAR',
      category: null,
      lat: 46.95,
      lon: 7.45,
      city: 'Bern',
      street: 'Marktgasse',
    );

    expect(sortPayLocationPins(const [zurich, bern]).map((pin) => pin.city), [
      'Bern',
      'Zürich',
    ]);
  });

  test('sorts legacy names by town then street', () {
    const zurich = PayLocationPin(
      name: 'SPAR Bahnhofstrasse 1, 8001 Zürich',
      category: null,
      lat: 47.37,
      lon: 8.54,
    );
    const bern = PayLocationPin(
      name: 'SPAR Marktgasse 1, 3011 Bern',
      category: null,
      lat: 46.95,
      lon: 7.45,
    );
    const zurichAlbis = PayLocationPin(
      name: 'SPAR Albisriederstrasse 5, 8004 Zürich',
      category: null,
      lat: 47.37,
      lon: 8.51,
    );

    expect(
      sortPayLocationPins(const [zurich, bern, zurichAlbis]).map((pin) => pin.name),
      [bern.name, zurichAlbis.name, zurich.name],
    );
  });

  test('sorts shops on the same street by house number', () {
    const bahnhof10 = PayLocationPin(
      name: 'SPAR Zürich',
      category: null,
      lat: 47.37,
      lon: 8.54,
      city: 'Zürich',
      street: 'Bahnhofstrasse',
      houseNumber: '10',
    );
    const bahnhof2 = PayLocationPin(
      name: 'SPAR Zürich',
      category: null,
      lat: 47.37,
      lon: 8.53,
      city: 'Zürich',
      street: 'Bahnhofstrasse',
      houseNumber: '2',
    );
    const albis = PayLocationPin(
      name: 'SPAR Zürich',
      category: null,
      lat: 47.37,
      lon: 8.51,
      city: 'Zürich',
      street: 'Albisriederstrasse',
      houseNumber: '5',
    );

    expect(
      sortPayLocationPins(const [bahnhof10, bahnhof2, albis]).map(
        (pin) => '${pin.street} ${pin.houseNumber}',
      ),
      ['Albisriederstrasse 5', 'Bahnhofstrasse 2', 'Bahnhofstrasse 10'],
    );
  });

  test('sorts equal shops by latitude regardless of input order', () {
    const south = PayLocationPin(
      name: 'SPAR Zürich',
      category: null,
      lat: 47.1,
      lon: 8.54,
      city: 'Zürich',
      street: 'Bahnhofstrasse',
      houseNumber: '1',
      postalCode: '8001',
    );
    const north = PayLocationPin(
      name: 'SPAR Zürich',
      category: null,
      lat: 47.2,
      lon: 8.54,
      city: 'Zürich',
      street: 'Bahnhofstrasse',
      houseNumber: '1',
      postalCode: '8001',
    );

    expect(sortPayLocationPins(const [south, north]).map((pin) => pin.lat), [47.1, 47.2]);
    expect(sortPayLocationPins(const [north, south]).map((pin) => pin.lat), [47.1, 47.2]);
  });

  test('trims structured address fields and drops empty ones', () {
    final pins = keepPayLocationPins({
      'places': [
        {
          'name': 'Trimmed',
          'lat': 47,
          'lon': 8,
          'street': '  Foo ',
          'houseNumber': '  Foo ',
          'postalCode': '  Foo ',
          'city': '  Foo ',
        },
        {
          'name': 'Empty',
          'lat': 47.1,
          'lon': 8.1,
          'street': '',
          'houseNumber': '  ',
          'postalCode': 1,
          'city': '',
        },
      ],
    });

    expect(pins, hasLength(2));
    expect(pins[0].street, 'Foo');
    expect(pins[0].houseNumber, 'Foo');
    expect(pins[0].postalCode, 'Foo');
    expect(pins[0].city, 'Foo');
    expect(pins[1].street, isNull);
    expect(pins[1].houseNumber, isNull);
    expect(pins[1].postalCode, isNull);
    expect(pins[1].city, isNull);
  });

  test('filters shops by city', () {
    const zurich = PayLocationPin(
      name: 'SPAR',
      category: null,
      lat: 47,
      lon: 8,
      city: 'Zürich',
      street: 'Bahnhofstrasse',
      postalCode: '8001',
    );
    const bern = PayLocationPin(
      name: 'SPAR',
      category: null,
      lat: 46.9,
      lon: 7.4,
      city: 'Bern',
      street: 'Marktgasse',
      postalCode: '3011',
    );

    expect(filterPayLocationPins(const [zurich, bern], 'bern'), [bern]);
    expect(filterPayLocationPins(const [zurich, bern], 'marktgasse'), [bern]);
    expect(filterPayLocationPins(const [zurich, bern], '8001'), [zurich]);
  });

  test('filters shops by house number and postal city line', () {
    const pin = PayLocationPin(
      name: 'SPAR Zürich',
      category: null,
      lat: 47.39,
      lon: 8.52,
      street: 'Hardturmstrasse',
      houseNumber: '126',
      postalCode: '8005',
      city: 'Zürich',
    );

    expect(filterPayLocationPins(const [pin], 'hardturmstrasse 126'), [pin]);
    expect(filterPayLocationPins(const [pin], '8005 zürich'), [pin]);
  });

  test('spreads the published shops across the country view', () {
    final pins = keepPayLocationPins(
      jsonDecode(
        File(
          'test/goldens/screens/pay/fixtures/dev_places_ethereum_zchf.json',
        ).readAsStringSync(),
      ),
    );
    final overview = clusterPayLocationPins(
      pins,
      cellDegrees: payLocationClusterCellDegrees(6.6),
    );
    final close = clusterPayLocationPins(
      pins,
      cellDegrees: payLocationClusterCellDegrees(14),
    );

    expect(overview.length, greaterThan(4));
    expect(overview.length, lessThan(15));
    expect(overview.every((cluster) => cluster.pins.length < pins.length), isTrue);
    expect(close.every((cluster) => cluster.isSingle), isTrue);
  });

  test('hides a city label that sits on a shop group', () {
    final pins = keepPayLocationPins(
      jsonDecode(
        File(
          'test/goldens/screens/pay/fixtures/dev_places_ethereum_zchf.json',
        ).readAsStringSync(),
      ),
    );
    final clusters = clusterPayLocationPins(
      pins,
      cellDegrees: payLocationClusterCellDegrees(6.6),
    );

    expect(
      payLocationCityCovered(
        cityName: 'Zürich',
        cityLat: 47.3769,
        cityLon: 8.5417,
        zoom: 6.6,
        clusters: clusters,
      ),
      isTrue,
    );
    expect(
      payLocationCityCovered(
        cityName: 'Genf',
        cityLat: 46.2044,
        cityLon: 6.1432,
        zoom: 6.6,
        clusters: clusters,
      ),
      isFalse,
    );
  });

  test('keeps the country and lake outlines on the map', () {
    expect(payLocationCountryRings, hasLength(2));
    expect(payLocationLakeRings.length, greaterThan(8));
    for (final ring in [...payLocationCountryRings, ...payLocationLakeRings]) {
      expect(ring.length, greaterThan(3));
      for (final point in ring) {
        expect(point.latitude, inInclusiveRange(45.5, 48.2));
        expect(point.longitude, inInclusiveRange(5.5, 10.8));
      }
    }
  });
}
