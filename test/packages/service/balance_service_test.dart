import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mocktail/mocktail.dart';
import 'package:realunit_wallet/models/balance.dart';
import 'package:realunit_wallet/packages/config/api_config.dart';
import 'package:realunit_wallet/packages/config/network_mode.dart';
import 'package:realunit_wallet/packages/repository/balance_repository.dart';
import 'package:realunit_wallet/packages/service/app_store.dart';
import 'package:realunit_wallet/packages/service/balance_service.dart';
import 'package:realunit_wallet/packages/utils/default_assets.dart';

class MockApiConfig extends Mock implements ApiConfig {}

class MockBalanceRepository extends Mock implements BalanceRepository {}

class TestAppStore extends AppStore {
  final http.Client client;

  TestAppStore(this.client, ApiConfig Function() apiConfig) : super(apiConfig);

  @override
  http.Client get httpClient => client;
}

void main() {
  late ApiConfig apiConfig;
  late BalanceService balanceService;
  late MockBalanceRepository balanceRepository;

  setUp(() {
    apiConfig = MockApiConfig();
    balanceRepository = MockBalanceRepository();

    when(() => apiConfig.apiHost).thenReturn('dev.api.dfx.swiss');
    when(() => apiConfig.networkMode).thenReturn(NetworkMode.testnet);
    when(() => balanceRepository.saveBalance(any())).thenAnswer((_) async {});
  });

  setUpAll(() {
    registerFallbackValue(Balance(
      chainId: 1,
      contractAddress: '0x0',
      walletAddress: '0x0',
      balance: BigInt.zero,
      asset: realUnitAsset,
      networkMode: NetworkMode.testnet,
    ));
  });

  AppStore buildAppStore(Future<http.Response> Function(http.Request) handler) {
    final client = MockClient(handler);
    return TestAppStore(client, () => apiConfig)..dfxAuthToken = 'test-auth-token';
  }

  group('$BalanceService', () {
    group('RealUnit Balance', () {
      test('is updated successfully', () async {
        String? capturedUrl;
        String? capturedMethod;
        Balance? savedBalance;
        final address = '0xTestAddress';

        when(() => balanceRepository.saveBalance(any())).thenAnswer((inv) async {
          savedBalance = inv.positionalArguments[0] as Balance;
        });

        final appStore = buildAppStore((request) async {
          capturedUrl = request.url.toString();
          capturedMethod = request.method;

          return http.Response(
              jsonEncode({
                'balance': '12345',
                'addressType': 0,
              }),
              200);
        });

        balanceService = BalanceService(balanceRepository, appStore);
        await balanceService.updateBalances(address);

        expect(capturedMethod, equals('GET'));
        expect(capturedUrl, contains(apiConfig.apiHost));
        expect(capturedUrl, contains('/v1/realunit/account/'));
        expect(capturedUrl, contains(address));

        expect(savedBalance, isNotNull);
        expect(savedBalance!.balance, equals(BigInt.from(12345)));
        expect(savedBalance!.asset.symbol, equals(realUnitAsset.symbol));
        expect(savedBalance!.walletAddress, equals(address));
      });

      test('skips updating when error occurs', () async {
        final appStore = buildAppStore((request) async {
          return http.Response('{"error": "Server error"}', 500);
        });

        final service = BalanceService(balanceRepository, appStore);

        await expectLater(
          service.updateBalances('0xTestAddress'),
          completes,
        );

        verifyNever(() => balanceRepository.saveBalance(any()));
      });
    });
  });
}
