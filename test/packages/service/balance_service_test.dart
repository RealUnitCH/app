import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mocktail/mocktail.dart';
import 'package:realunit_wallet/models/balance.dart';
import 'package:realunit_wallet/packages/config/api_config.dart';
import 'package:realunit_wallet/packages/config/network_mode.dart';
import 'package:realunit_wallet/packages/repository/balance_repository.dart';
import 'package:realunit_wallet/packages/repository/cache_repository.dart';
import 'package:realunit_wallet/packages/service/app_store.dart';
import 'package:realunit_wallet/packages/service/balance_service.dart';
import 'package:realunit_wallet/packages/service/session_cache.dart';
import 'package:realunit_wallet/packages/utils/default_assets.dart';

class MockApiConfig extends Mock implements ApiConfig {}

class MockBalanceRepository extends Mock implements BalanceRepository {}

class MockCacheRepository extends Mock implements CacheRepository {}

class TestAppStore extends AppStore {
  final http.Client client;

  TestAppStore(this.client, ApiConfig Function() apiConfig, CacheRepository cacheRepository)
    : super(apiConfig, SessionCache(cacheRepository));

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
    when(() => apiConfig.asset).thenReturn(realUnitAsset);

    when(() => balanceRepository.saveBalance(any())).thenAnswer((_) async {});
  });

  setUpAll(() {
    registerFallbackValue(
      Balance(
        chainId: 1,
        contractAddress: '0x0',
        walletAddress: '0x0',
        balance: BigInt.zero,
        asset: realUnitAsset,
      ),
    );
    registerFallbackValue(realUnitAsset);
  });

  AppStore buildAppStore(Future<http.Response> Function(http.Request) handler) {
    final client = MockClient(handler);
    return TestAppStore(client, () => apiConfig, MockCacheRepository())
      ..sessionCache.setAuthToken('test-auth-token');
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
            200,
          );
        });

        balanceService = BalanceService(balanceRepository, appStore);
        await balanceService.updateBalance(address);

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
          service.updateBalance('0xTestAddress'),
          completes,
        );

        verifyNever(() => balanceRepository.saveBalance(any()));
      });

      test('skips saving when the JSON has no balance field', () async {
        final appStore = buildAppStore(
          (_) async => http.Response(jsonEncode({'addressType': 0}), 200),
        );

        final service = BalanceService(balanceRepository, appStore);
        await service.updateBalance('0xAnyAddress');

        verifyNever(() => balanceRepository.saveBalance(any()));
      });

      test('catches a non-numeric balance string and skips saving', () async {
        // Production code does BigInt.parse on the value; non-numeric raises
        // FormatException which the catch-block swallows.
        final appStore = buildAppStore(
          (_) async => http.Response(jsonEncode({'balance': 'NaN'}), 200),
        );

        final service = BalanceService(balanceRepository, appStore);
        await service.updateBalance('0xAnyAddress');

        verifyNever(() => balanceRepository.saveBalance(any()));
      });
    });

    test('getBalance delegates to BalanceRepository.getBalance', () async {
      final expected = Balance(
        chainId: realUnitAsset.chainId,
        contractAddress: realUnitAsset.address,
        walletAddress: '0xAnyAddress',
        balance: BigInt.from(42),
        asset: realUnitAsset,
      );
      when(() => balanceRepository.getBalance(any(), any()))
          .thenAnswer((_) async => expected);

      final appStore = buildAppStore((_) async => http.Response('{}', 200));
      final service = BalanceService(balanceRepository, appStore);

      final result = await service.getBalance(realUnitAsset, '0xAnyAddress');

      expect(result, same(expected));
      verify(() => balanceRepository.getBalance(realUnitAsset, '0xAnyAddress'))
          .called(1);
    });

    test('cancelSync is a safe no-op before startSync has run', () {
      final appStore = buildAppStore((_) async => http.Response('{}', 200));
      final service = BalanceService(balanceRepository, appStore);

      // Should not throw.
      service.cancelSync();
    });
  });
}
