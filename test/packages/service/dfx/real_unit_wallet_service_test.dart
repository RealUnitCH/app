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
import 'package:realunit_wallet/packages/service/wallet_service.dart';

class _MockAppStore extends Mock implements AppStore {}

class _MockCacheRepository extends Mock implements CacheRepository {}

class _MockWalletService extends Mock implements WalletService {}

void main() {
  late _MockAppStore appStore;
  late _MockWalletService walletService;
  late SessionCache sessionCache;

  setUp(() {
    appStore = _MockAppStore();
    walletService = _MockWalletService();
    sessionCache = SessionCache(_MockCacheRepository());
    when(() => appStore.sessionCache).thenReturn(sessionCache);
    when(() => appStore.apiConfig)
        .thenReturn(const ApiConfig(networkMode: NetworkMode.mainnet));
    when(() => walletService.ensureCurrentWalletUnlocked()).thenAnswer((_) async {});
    when(() => walletService.lockCurrentWallet()).thenAnswer((_) async {});
  });

  RealUnitWalletService build(http.Client client) {
    when(() => appStore.httpClient).thenReturn(client);
    return RealUnitWalletService(appStore, walletService);
  }

  group('$RealUnitWalletService', () {
    // The 401 -> refresh -> retry plumbing of `authenticatedGet` is covered
    // exhaustively in `dfx_auth_service_test.dart` (GET / POST / PUT retry,
    // no-third-retry, refresh-throws propagation). Per-service wiring is
    // verified implicitly by the "Bearer JWT" assertion below — the header
    // can only land on the request if it routes through `authenticatedGet`.

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
      // the caller directly. The 401-retry behaviour is covered exhaustively
      // in dfx_auth_service_test.dart.
      final client = MockClient((_) async => http.Response(
            jsonEncode({'statusCode': 500, 'message': 'oops'}),
            500,
          ));

      expect(
        () => build(client).getWalletStatus(),
        throwsA(isA<ApiException>()),
      );
    });
  });
}
