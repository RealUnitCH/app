import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mocktail/mocktail.dart';
import 'package:realunit_wallet/packages/config/api_config.dart';
import 'package:realunit_wallet/packages/config/network_mode.dart';
import 'package:realunit_wallet/packages/service/app_store.dart';
import 'package:realunit_wallet/packages/service/dfx/dfx_price_service.dart';
import 'package:realunit_wallet/packages/utils/default_assets.dart';
import 'package:realunit_wallet/styles/currency.dart';

class _MockAppStore extends Mock implements AppStore {}

void main() {
  late _MockAppStore appStore;

  setUp(() {
    appStore = _MockAppStore();
    when(() => appStore.apiConfig)
        .thenReturn(const ApiConfig(networkMode: NetworkMode.mainnet));
  });

  DFXPriceService build(http.Client client) {
    when(() => appStore.httpClient).thenReturn(client);
    return DFXPriceService(appStore);
  }

  group('$DFXPriceService', () {
    group('getPriceOfAsset', () {
      test('parses CHF price scaled by 100 (rappen)', () async {
        final client = MockClient((_) async => http.Response(
              jsonEncode({'chf': 12.34, 'eur': 11.5}),
              200,
            ));

        final price = await build(client).getPriceOfAsset(realUnitAsset, Currency.chf);

        // 12.34 CHF → 1234 rappen.
        expect(price, BigInt.from(1234));
      });

      test('parses EUR price scaled by 100 (cent)', () async {
        final client = MockClient((_) async => http.Response(
              jsonEncode({'chf': 12.34, 'eur': 11.5}),
              200,
            ));

        final price = await build(client).getPriceOfAsset(realUnitAsset, Currency.eur);

        expect(price, BigInt.from(1150));
      });

      test('throws on non-200', () async {
        final client = MockClient((_) async => http.Response('boom', 500));

        expect(
          () => build(client).getPriceOfAsset(realUnitAsset, Currency.chf),
          throwsException,
        );
      });
    });

    group('getPriceChart', () {
      test('maps history entries to PricePoints with the asset, scaled price, and time', () async {
        final client = MockClient((request) async {
          // Service requests `timeFrame=ALL` for the chart endpoint.
          expect(request.url.queryParameters['timeFrame'], 'ALL');
          expect(request.url.path, '/v1/realunit/price/history');
          return http.Response(
            jsonEncode([
              {'chf': 1.0, 'eur': 0.95, 'timestamp': '2026-01-01T00:00:00Z'},
              {'chf': 2.5, 'eur': 2.30, 'timestamp': '2026-02-01T00:00:00Z'},
            ]),
            200,
          );
        });

        final points = await build(client).getPriceChart(realUnitAsset, Currency.chf);

        expect(points, hasLength(2));
        expect(points[0].asset, realUnitAsset);
        expect(points[0].price, BigInt.from(100));
        expect(points[0].time, DateTime.utc(2026, 1, 1));
        expect(points[1].price, BigInt.from(250));
      });

      test('parses EUR chart correctly', () async {
        final client = MockClient((_) async => http.Response(
              jsonEncode([
                {'chf': 1.0, 'eur': 0.50, 'timestamp': '2026-01-01T00:00:00Z'},
              ]),
              200,
            ));

        final points = await build(client).getPriceChart(realUnitAsset, Currency.eur);

        expect(points.single.price, BigInt.from(50));
      });

      test('throws on non-200', () async {
        final client = MockClient((_) async => http.Response('nope', 404));

        expect(
          () => build(client).getPriceChart(realUnitAsset, Currency.eur),
          throwsException,
        );
      });
    });

    group('getChfToEurRate', () {
      test('returns eur/chf for a positive CHF value', () async {
        final client = MockClient((_) async => http.Response(
              jsonEncode({'chf': 2.0, 'eur': 1.0}),
              200,
            ));

        final rate = await build(client).getChfToEurRate();

        expect(rate, 0.5);
      });

      test('returns 0.0 when CHF is zero (avoids division by zero)', () async {
        final client = MockClient((_) async => http.Response(
              jsonEncode({'chf': 0.0, 'eur': 1.0}),
              200,
            ));

        final rate = await build(client).getChfToEurRate();

        expect(rate, 0.0);
      });
    });
  });
}
