import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:realunit_wallet/screens/pay/pay_locations.dart';

void main() {
  test('builds filtered places URLs', () {
    expect(
      payLocationsPlacesUrl('Ethereum', 'ZCHF'),
      'https://api.opencryptopay.io/map/places?blockchain=Ethereum&asset=ZCHF',
    );
    expect(
      payLocationsPlacesUrl('Polygon', 'ZCHF'),
      'https://api.opencryptopay.io/map/places?blockchain=Polygon&asset=ZCHF',
    );
    expect(
      payLocationsPlacesUrl('Ethereum', 'dEURO'),
      'https://api.opencryptopay.io/map/places?blockchain=Ethereum&asset=dEURO',
    );
  });

  test('does not build a places URL after a filters failure', () {
    expect(
      placesUrlAfterFilters(
        filtersOk: false,
        blockchain: 'Ethereum',
        asset: 'ZCHF',
      ),
      isNull,
    );
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

  test('drops a place without a matching support pair', () {
    final pins = keepPayLocationPins(
      {
        'places': [
          {
            'name': 'Shop',
            'lat': 47,
            'lon': 8,
            'supports': [
              {'blockchain': 'Ethereum', 'asset': 'USDT'},
              {'blockchain': 'Polygon', 'asset': 'ZCHF'},
            ],
          },
        ],
      },
      'Ethereum',
      'ZCHF',
    );

    expect(pins, isEmpty);
  });

  test('drops a place with a non-finite coordinate', () {
    final pins = keepPayLocationPins(
      {
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
      },
      'Ethereum',
      'ZCHF',
    );

    expect(pins, isEmpty);
  });

  test('keeps dEURO unchanged', () {
    final pins = keepPayLocationPins(
      {
        'places': [
          {
            'name': 'Shop',
            'lat': 47,
            'lon': 8,
            'supports': [
              {'blockchain': 'Ethereum', 'asset': 'dEURO'},
            ],
          },
        ],
      },
      'Ethereum',
      'dEURO',
    );

    expect(pins, hasLength(1));
  });

  test('parses string filters and adds only missing defaults', () {
    final choices = parsePayLocationFilters({
      'blockchains': ['Polygon', 7],
      'assets': ['dEURO', false],
      'ignored': ['value'],
    });

    expect(choices.blockchains, ['Ethereum', 'Polygon']);
    expect(choices.assets, ['ZCHF', 'dEURO']);
    expect(
      parsePayLocationFilters(null).blockchains,
      ['Ethereum'],
    );
    expect(parsePayLocationFilters(null).assets, ['ZCHF']);
  });

  test('keeps a decoded place whose support pair matches', () {
    final pins = keepPayLocationPins(
      jsonDecode(
        '{"places":[{"name":"Shop","category":"store","lat":47.1,"lon":8.2,'
        '"supports":[{"blockchain":"Ethereum","asset":"dEURO"}]}]}',
      ),
      'Ethereum',
      'dEURO',
    );

    expect(pins, hasLength(1));
    expect(pins.single.name, 'Shop');
    expect(pins.single.category, 'store');
  });

  test('reads decoded filter lists', () {
    final choices = parsePayLocationFilters(
      jsonDecode('{"blockchains":["Polygon"],"assets":["dEURO"]}'),
    );

    expect(choices.blockchains, ['Ethereum', 'Polygon']);
    expect(choices.assets, ['ZCHF', 'dEURO']);
  });
}
