import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mocktail/mocktail.dart';
import 'package:realunit_wallet/packages/config/api_config.dart';
import 'package:realunit_wallet/packages/config/network_mode.dart';
import 'package:realunit_wallet/packages/repository/cache_repository.dart';
import 'package:realunit_wallet/packages/service/app_store.dart';
import 'package:realunit_wallet/packages/service/dfx/dfx_faucet_service.dart';
import 'package:realunit_wallet/packages/service/dfx/exceptions/api_exception.dart';
import 'package:realunit_wallet/packages/service/session_cache.dart';

class _MockAppStore extends Mock implements AppStore {}

class _MockCacheRepository extends Mock implements CacheRepository {}

void main() {
  late _MockAppStore appStore;
  late SessionCache sessionCache;

  setUp(() {
    appStore = _MockAppStore();
    sessionCache = SessionCache(_MockCacheRepository());
    when(() => appStore.sessionCache).thenReturn(sessionCache);
    when(() => appStore.apiConfig)
        .thenReturn(const ApiConfig(networkMode: NetworkMode.testnet));
  });

  DfxFaucetService build(http.Client client) {
    when(() => appStore.httpClient).thenReturn(client);
    return DfxFaucetService(appStore);
  }

  group('$DfxFaucetService', () {
    test('requestFaucet posts to /v1/faucet with the JWT and parses the response', () async {
      sessionCache.setAuthToken('jwt-zzz');
      Map<String, String>? capturedHeaders;
      String? capturedPath;
      final client = MockClient((request) async {
        capturedHeaders = request.headers;
        capturedPath = request.url.path;
        expect(request.method, 'POST');
        return http.Response(
          jsonEncode({'txId': '0xdeadbeef', 'amount': 0.05}),
          200,
        );
      });

      final response = await build(client).requestFaucet();

      expect(response.txId, '0xdeadbeef');
      expect(response.amount, 0.05);
      expect(capturedPath, '/v1/faucet');
      expect(capturedHeaders!['Authorization'], 'Bearer jwt-zzz');
      expect(capturedHeaders!['Content-Type'], 'application/json');
    });

    test('accepts a 201 response in addition to 200', () async {
      sessionCache.setAuthToken('jwt-zzz');
      final client = MockClient((_) async => http.Response(
            jsonEncode({'txId': 'tx-1', 'amount': 1.0}),
            201,
          ));

      final response = await build(client).requestFaucet();

      expect(response.txId, 'tx-1');
    });

    test('throws ApiException on a non-2xx response', () async {
      sessionCache.setAuthToken('jwt-zzz');
      final client = MockClient((_) async => http.Response(
            jsonEncode({'statusCode': 429, 'message': 'Too Many Requests'}),
            429,
          ));

      expect(
        () => build(client).requestFaucet(),
        throwsA(isA<ApiException>()),
      );
    });
  });
}
