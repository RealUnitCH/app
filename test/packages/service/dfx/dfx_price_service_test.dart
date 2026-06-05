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

      test('returns zero when CHF is absent (unpriced timestamp-only payload)', () async {
        // The live endpoint returns `{"timestamp": ...}` while no price is
        // published. The dashboard renders BigInt.zero as "--.--".
        final client = MockClient((_) async => http.Response(
              jsonEncode({'timestamp': '2026-06-05T08:20:40Z'}),
              200,
            ));

        final price = await build(client).getPriceOfAsset(realUnitAsset, Currency.chf);

        expect(price, BigInt.zero);
      });

      test('returns zero when EUR is absent (unpriced timestamp-only payload)', () async {
        final client = MockClient((_) async => http.Response(
              jsonEncode({'timestamp': '2026-06-05T08:20:40Z'}),
              200,
            ));

        final price = await build(client).getPriceOfAsset(realUnitAsset, Currency.eur);

        expect(price, BigInt.zero);
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

      test('skips entries whose requested currency price is null', () async {
        // The newest history entry of the live endpoint is unpriced
        // (`{"timestamp": ...}` only). It must be skipped, not crash.
        final client = MockClient((_) async => http.Response(
              jsonEncode([
                {'chf': 1.0, 'eur': 0.95, 'timestamp': '2026-01-01T00:00:00Z'},
                {'eur': 2.30, 'timestamp': '2026-02-01T00:00:00Z'}, // no chf
                {'timestamp': '2026-03-01T00:00:00Z'}, // unpriced
              ]),
              200,
            ));

        final points = await build(client).getPriceChart(realUnitAsset, Currency.chf);

        expect(points, hasLength(1));
        expect(points.single.price, BigInt.from(100));
        expect(points.single.time, DateTime.utc(2026, 1, 1));
      });

      test('skips entries without a parseable timestamp', () async {
        final client = MockClient((_) async => http.Response(
              jsonEncode([
                {'chf': 1.0, 'eur': 0.95}, // no timestamp
                {'chf': 2.0, 'eur': 1.90, 'timestamp': '2026-02-01T00:00:00Z'},
              ]),
              200,
            ));

        final points = await build(client).getPriceChart(realUnitAsset, Currency.chf);

        expect(points, hasLength(1));
        expect(points.single.price, BigInt.from(200));
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

      test('returns 0.0 when the payload is unpriced (chf/eur absent)', () async {
        final client = MockClient((_) async => http.Response(
              jsonEncode({'timestamp': '2026-06-05T08:20:40Z'}),
              200,
            ));

        final rate = await build(client).getChfToEurRate();

        expect(rate, 0.0);
      });
    });
  });
}
