import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:realunit_wallet/screens/pay/pay_locations.dart';

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
