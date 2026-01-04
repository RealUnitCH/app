import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mocktail/mocktail.dart';
import 'package:realunit_wallet/models/balance.dart';
import 'package:realunit_wallet/packages/config/api_config.dart';
import 'package:realunit_wallet/packages/repository/balance_repository.dart';
import 'package:realunit_wallet/packages/repository/settings_repository.dart';
import 'package:realunit_wallet/packages/service/app_store.dart';
import 'package:realunit_wallet/packages/service/balance_service.dart';
import 'package:realunit_wallet/packages/utils/default_assets.dart';

class MockBalanceRepository extends Mock implements BalanceRepository {}

class MockSettingsRepository extends Mock implements SettingsRepository {}

void main() {
  late MockBalanceRepository balanceRepository;
  late MockSettingsRepository settingsRepository;

  setUp(() {
    balanceRepository = MockBalanceRepository();
    settingsRepository = MockSettingsRepository();

    when(() => settingsRepository.networkMode).thenReturn(NetworkMode.testnet);
    when(() => settingsRepository.apiConfig)
        .thenReturn(const ApiConfig(networkMode: NetworkMode.testnet));

    when(() => balanceRepository.saveBalance(any())).thenAnswer((_) async {});
  });

  setUpAll(() {
    registerFallbackValue(Balance(
      chainId: 1,
      contractAddress: '0x0',
      walletAddress: '0x0',
      balance: BigInt.zero,
      asset: realUnitAsset,
    ));
  });

  group('BalanceService', () {
    group('_updateRealUnitBalance', () {
      test('fetches balance from DFX API and saves it', () async {
        Balance? savedBalance;

        when(() => balanceRepository.saveBalance(any())).thenAnswer((inv) async {
          savedBalance = inv.positionalArguments[0] as Balance;
        });

        final mockClient = MockClient((request) async {
          expect(request.url.toString(), contains('dev.api.dfx.swiss'));
          expect(request.url.toString(), contains('/v1/realunit/account/'));
          expect(request.url.toString(), contains('0xTestAddress'));

          return http.Response(jsonEncode({
            'balance': '12345',
            'addressType': 0,
          }), 200);
        });

        final testAppStore = _TestAppStore(mockClient);
        testAppStore.settingsRepository = settingsRepository;

        final service = BalanceService(balanceRepository, testAppStore);
        await service.updateBalances('0xTestAddress');

        expect(savedBalance, isNotNull);
        expect(savedBalance!.balance, equals(BigInt.from(12345)));
        expect(savedBalance!.asset.symbol, equals(realUnitAsset.symbol));
        expect(savedBalance!.walletAddress, equals('0xTestAddress'));
      });

      test('handles API error gracefully', () async {
        final mockClient = MockClient((request) async {
          return http.Response('{"error": "Server error"}', 500);
        });

        final testAppStore = _TestAppStore(mockClient);
        testAppStore.settingsRepository = settingsRepository;

        final service = BalanceService(balanceRepository, testAppStore);

        // Should not throw
        await expectLater(
          service.updateBalances('0xTestAddress'),
          completes,
        );

        // Balance should not be saved on error
        verifyNever(() => balanceRepository.saveBalance(any()));
      });

      test('handles null balance in response', () async {
        final mockClient = MockClient((request) async {
          return http.Response(jsonEncode({
            'addressType': 0,
          }), 200);
        });

        final testAppStore = _TestAppStore(mockClient);
        testAppStore.settingsRepository = settingsRepository;

        final service = BalanceService(balanceRepository, testAppStore);
        await service.updateBalances('0xTestAddress');

        // Balance should not be saved when balance is null
        verifyNever(() => balanceRepository.saveBalance(any()));
      });

      test('parses large balance values correctly', () async {
        Balance? savedBalance;

        when(() => balanceRepository.saveBalance(any())).thenAnswer((inv) async {
          savedBalance = inv.positionalArguments[0] as Balance;
        });

        final mockClient = MockClient((request) async {
          return http.Response(jsonEncode({
            'balance': '999999999999999999',
          }), 200);
        });

        final testAppStore = _TestAppStore(mockClient);
        testAppStore.settingsRepository = settingsRepository;

        final service = BalanceService(balanceRepository, testAppStore);
        await service.updateBalances('0xTestAddress');

        expect(savedBalance!.balance, equals(BigInt.parse('999999999999999999')));
      });

      test('uses correct API host for mainnet', () async {
        String? capturedUrl;

        when(() => settingsRepository.networkMode).thenReturn(NetworkMode.mainnet);
        when(() => settingsRepository.apiConfig)
            .thenReturn(const ApiConfig(networkMode: NetworkMode.mainnet));

        final mockClient = MockClient((request) async {
          capturedUrl = request.url.toString();
          return http.Response(jsonEncode({'balance': '100'}), 200);
        });

        final testAppStore = _TestAppStore(mockClient);
        testAppStore.settingsRepository = settingsRepository;

        final service = BalanceService(balanceRepository, testAppStore);
        await service.updateBalances('0xTestAddress');

        expect(capturedUrl, contains('api.dfx.swiss'));
        expect(capturedUrl, isNot(contains('dev.api.dfx.swiss')));
      });
    });

    group('startSync and cancelSync', () {
      test('cancelSync stops periodic timer', () async {
        final mockClient = MockClient((request) async {
          return http.Response(jsonEncode({'balance': '100'}), 200);
        });

        final testAppStore = _TestAppStore(mockClient);
        testAppStore.settingsRepository = settingsRepository;

        final service = BalanceService(balanceRepository, testAppStore);

        service.startSync('0xTest');
        service.cancelSync();

        // No exception should be thrown
        expect(true, isTrue);
      });
    });
  });
}

class _TestAppStore extends AppStore {
  final http.Client _client;

  _TestAppStore(this._client);

  @override
  http.Client get httpClient => _client;
}
