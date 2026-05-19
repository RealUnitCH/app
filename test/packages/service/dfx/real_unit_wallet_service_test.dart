import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mocktail/mocktail.dart';
import 'package:realunit_wallet/packages/config/api_config.dart';
import 'package:realunit_wallet/packages/config/network_mode.dart';
import 'package:realunit_wallet/packages/repository/cache_repository.dart';
import 'package:realunit_wallet/packages/service/app_store.dart';
import 'package:realunit_wallet/packages/service/dfx/exceptions/api_exception.dart';
import 'package:realunit_wallet/packages/service/dfx/real_unit_wallet_service.dart';
import 'package:realunit_wallet/packages/service/session_cache.dart';

class _MockAppStore extends Mock implements AppStore {}

class _MockCacheRepository extends Mock implements CacheRepository {}

/// Forces `getAuthToken` / `refreshAuthToken` to deterministic values so the
/// 401-retry test does not have to reach into the wallet / sign-message
/// pipeline. The retry plumbing itself is covered end-to-end in
/// `dfx_auth_service_test.dart`; this stub just lets us assert that
/// `RealUnitWalletService.getWalletStatus` is wired onto it.
class _RetryRealUnitWalletService extends RealUnitWalletService {
  _RetryRealUnitWalletService(super.appStore);

  int refreshAuthTokenCalls = 0;

  @override
  Future<String?> getAuthToken() async => 'expired-token';

  @override
  Future<String?> refreshAuthToken() async {
    refreshAuthTokenCalls++;
    return 'fresh-token';
  }
}

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

  RealUnitWalletService build(http.Client client) {
    when(() => appStore.httpClient).thenReturn(client);
    return RealUnitWalletService(appStore);
  }

  _RetryRealUnitWalletService buildRetry(http.Client client) {
    when(() => appStore.httpClient).thenReturn(client);
    return _RetryRealUnitWalletService(appStore);
  }

  group('$RealUnitWalletService', () {
    test('getWalletStatus GETs /v1/realunit/wallet/status with the Bearer JWT', () async {
      sessionCache.setAuthToken('jwt-1');
      String? path;
      String? auth;
      String? method;
      final client = MockClient((request) async {
        path = request.url.path;
        auth = request.headers['Authorization'];
        method = request.method;
        return http.Response(
          jsonEncode({'isRegistered': false, 'userData': null}),
          200,
        );
      });

      final status = await build(client).getWalletStatus();

      expect(status.isRegistered, isFalse);
      expect(status.realUnitUserDataDto, isNull);
      expect(method, 'GET');
      expect(path, '/v1/realunit/wallet/status');
      expect(auth, 'Bearer jwt-1');
    });

    test('getWalletStatus parses isRegistered=true with null userData', () async {
      sessionCache.setAuthToken('jwt-1');
      final client = MockClient((_) async => http.Response(
            jsonEncode({'isRegistered': true, 'userData': null}),
            200,
          ));

      final status = await build(client).getWalletStatus();

      expect(status.isRegistered, isTrue);
      expect(status.realUnitUserDataDto, isNull);
    });

    test('getWalletStatus throws ApiException on a non-2xx non-401 response', () async {
      sessionCache.setAuthToken('jwt-1');
      // Non-401 — bypasses the refresh-on-401 retry path and is surfaced to
      // the caller directly. The 401-retry behaviour is covered below and
      // exhaustively in dfx_auth_service_test.dart.
      final client = MockClient((_) async => http.Response(
            jsonEncode({'statusCode': 500, 'message': 'oops'}),
            500,
          ));

      expect(
        () => build(client).getWalletStatus(),
        throwsA(isA<ApiException>()),
      );
    });

    test('getWalletStatus retries once with a refreshed token on 401', () async {
      final seenAuthHeaders = <String?>[];
      final client = MockClient((request) async {
        seenAuthHeaders.add(request.headers['Authorization']);

        if (seenAuthHeaders.length == 1) {
          return http.Response('{"message":"Unauthorized"}', 401);
        }
        return http.Response(
          jsonEncode({'isRegistered': true, 'userData': null}),
          200,
        );
      });

      final service = buildRetry(client);
      final status = await service.getWalletStatus();

      expect(status.isRegistered, isTrue);
      expect(seenAuthHeaders, ['Bearer expired-token', 'Bearer fresh-token']);
      expect(service.refreshAuthTokenCalls, 1);
    });
  });
}
