import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mocktail/mocktail.dart';
import 'package:realunit_wallet/packages/config/api_config.dart';
import 'package:realunit_wallet/packages/config/network_mode.dart';
import 'package:realunit_wallet/packages/repository/cache_repository.dart';
import 'package:realunit_wallet/packages/service/app_store.dart';
import 'package:realunit_wallet/packages/service/dfx/dfx_blockchain_api_service.dart';
import 'package:realunit_wallet/packages/service/dfx/exceptions/api_exception.dart';
import 'package:realunit_wallet/packages/service/session_cache.dart';

class _MockAppStore extends Mock implements AppStore {}

class _MockCacheRepository extends Mock implements CacheRepository {}

const _testAddress = '0xabcdefabcdefabcdefabcdefabcdefabcdefabcd';

void main() {
  late _MockAppStore appStore;
  late SessionCache sessionCache;

  setUp(() {
    appStore = _MockAppStore();
    sessionCache = SessionCache(_MockCacheRepository());
    when(() => appStore.sessionCache).thenReturn(sessionCache);
    when(() => appStore.apiConfig)
        .thenReturn(const ApiConfig(networkMode: NetworkMode.mainnet));
  });

  DfxBlockchainApiService build(http.Client client) {
    when(() => appStore.httpClient).thenReturn(client);
    return DfxBlockchainApiService(appStore);
  }

  group('$DfxBlockchainApiService', () {
    test('getEthBalance posts the address + chain + asset id with the JWT', () async {
      sessionCache.setAuthToken('jwt-abc');
      Map<String, dynamic>? capturedBody;
      Map<String, String>? capturedHeaders;
      final client = MockClient((request) async {
        capturedBody = jsonDecode(request.body) as Map<String, dynamic>;
        capturedHeaders = request.headers;
        return http.Response(
          jsonEncode({
            'balances': [
              {'balance': 1.25},
            ],
          }),
          200,
        );
      });

      final balance = await build(client).getEthBalance(_testAddress);

      expect(balance, 1.25);
      expect(capturedBody!['address'], _testAddress);
      // chainId 1 → 'Ethereum'.
      expect(capturedBody!['blockchain'], 'Ethereum');
      expect(capturedBody!['assetIds'], isA<List>());
      expect(capturedHeaders!['Authorization'], 'Bearer jwt-abc');
      expect(capturedHeaders!['Content-Type'], 'application/json');
    });

    test('uses "Sepolia" as the blockchain name on the testnet chain', () async {
      when(() => appStore.apiConfig)
          .thenReturn(const ApiConfig(networkMode: NetworkMode.testnet));
      sessionCache.setAuthToken('jwt-abc');
      Map<String, dynamic>? capturedBody;
      final client = MockClient((request) async {
        capturedBody = jsonDecode(request.body) as Map<String, dynamic>;
        return http.Response(jsonEncode({'balances': []}), 200);
      });

      await build(client).getEthBalance(_testAddress);

      expect(capturedBody!['blockchain'], 'Sepolia');
    });

    test('returns 0.0 when the balances list is empty', () async {
      final client = MockClient((_) async => http.Response(
            jsonEncode({'balances': []}),
            200,
          ));

      expect(await build(client).getEthBalance(_testAddress), 0.0);
    });

    test('accepts a 201 response in addition to 200', () async {
      final client = MockClient((_) async => http.Response(
            jsonEncode({
              'balances': [
                {'balance': 3.5},
              ],
            }),
            201,
          ));

      expect(await build(client).getEthBalance(_testAddress), 3.5);
    });

    test('throws ApiException on a non-2xx response', () async {
      final client = MockClient((_) async => http.Response(
            jsonEncode({'statusCode': 401, 'message': 'Unauthorized'}),
            401,
          ));

      expect(
        () => build(client).getEthBalance(_testAddress),
        throwsA(isA<ApiException>()),
      );
    });
  });
}
