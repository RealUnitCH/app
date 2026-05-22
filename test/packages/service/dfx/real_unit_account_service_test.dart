import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mocktail/mocktail.dart';
import 'package:realunit_wallet/packages/config/api_config.dart';
import 'package:realunit_wallet/packages/config/network_mode.dart';
import 'package:realunit_wallet/packages/service/app_store.dart';
import 'package:realunit_wallet/packages/service/dfx/real_unit_account_service.dart';
import 'package:realunit_wallet/packages/wallet/wallet.dart';
import 'package:realunit_wallet/styles/currency.dart';

class _MockAppStore extends Mock implements AppStore {}

const _testMnemonic =
    'test test test test test test test test test test test junk';

Map<String, dynamic> _summary({
  double? chf,
  double? eur,
  String balance = '0',
  String timestamp = '2026-01-01T00:00:00Z',
}) =>
    {
      'address': '0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266',
      'addressType': 0,
      'balance': '0',
      'lastUpdated': '2026-01-01T00:00:00Z',
      'historicalBalances': [
        {
          'balance': balance,
          'timestamp': timestamp,
          'valueChf': chf,
          'valueEur': eur,
        },
      ],
    };

void main() {
  late _MockAppStore appStore;
  late SoftwareWallet wallet;

  setUp(() {
    appStore = _MockAppStore();
    wallet = SoftwareWallet(1, 'Main', _testMnemonic);
    when(() => appStore.wallet).thenReturn(wallet);
    when(() => appStore.apiConfig)
        .thenReturn(const ApiConfig(networkMode: NetworkMode.mainnet));
  });

  RealUnitAccountService build(http.Client client) {
    when(() => appStore.httpClient).thenReturn(client);
    return RealUnitAccountService(appStore);
  }

  group('$RealUnitAccountService', () {
    test('getPortfolioHistory GETs /v1/realunit/account/<eip55> and parses CHF values', () async {
      String? path;
      final client = MockClient((request) async {
        path = request.url.path;
        return http.Response(
          jsonEncode(_summary(chf: 12.34, balance: '1000000')),
          200,
        );
      });

      final points = await build(client).getPortfolioHistory(Currency.chf);

      expect(points, hasLength(1));
      // 12.34 CHF → 1234 rappen (×100).
      expect(points.single.value, BigInt.from(1234));
      expect(points.single.balance, BigInt.from(1000000));
      expect(points.single.time, DateTime.utc(2026, 1, 1));
      // Path uses EIP-55 hex of the Hardhat #0 address.
      expect(path, '/v1/realunit/account/0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266');
    });

    test('getPortfolioHistory uses EUR values when Currency.eur is requested', () async {
      final client = MockClient((_) async => http.Response(
            jsonEncode(_summary(chf: 12.34, eur: 11.50)),
            200,
          ));

      final points = await build(client).getPortfolioHistory(Currency.eur);

      expect(points.single.value, BigInt.from(1150));
    });

    test('getPortfolioHistory treats a null value as 0', () async {
      final client = MockClient((_) async => http.Response(
            jsonEncode(_summary(chf: null)),
            200,
          ));

      final points = await build(client).getPortfolioHistory(Currency.chf);

      expect(points.single.value, BigInt.zero);
    });

    test('getPortfolioHistory returns [] on non-200 (does not throw)', () async {
      final client = MockClient((_) async => http.Response('boom', 500));

      final points = await build(client).getPortfolioHistory(Currency.chf);

      expect(points, isEmpty);
    });
  });

  group('malformed JSON responses', () {
    test('getPortfolioHistory with non-JSON 200 throws FormatException', () {
      final client = MockClient((_) async => http.Response('not json', 200));
      expect(
        () => build(client).getPortfolioHistory(Currency.chf),
        throwsA(isA<FormatException>()),
      );
    });
  });
}
