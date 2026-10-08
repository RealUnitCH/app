import 'dart:convert';
import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:realunit_wallet/screens/pay/pay_locations.dart';
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
    expect(payLocationsPlacesBodyIsList({'places': <Object?>[{}]}), isTrue);
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

  test('keeps a published place that omits supports', () {
    final pins = keepPayLocationPins({
      'places': [
        {'name': 'SPAR', 'category': 'shopping', 'lat': 47.1, 'lon': 8.2},
        {'name': 'Null', 'lat': 47.2, 'lon': 8.3, 'supports': null},
        {
          'name': 'Empty',
          'lat': 47.3,
          'lon': 8.4,
          'supports': <Object?>[],
        },
      ],
    });

    expect(pins.map((pin) => pin.name), ['SPAR', 'Null']);
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
          httpClient: MockClient((request) async => http.Response('{"places":[]}', 200)),
          mapBuilder: (_) => const SizedBox.shrink(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Noch keine Standorte veröffentlicht.'), findsOneWidget);
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
}
