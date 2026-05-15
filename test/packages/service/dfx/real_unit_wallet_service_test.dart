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
      final client = MockClient((_) async => http.Response(
            jsonEncode({'isRegistered': true, 'userData': null}),
            200,
          ));

      final status = await build(client).getWalletStatus();

      expect(status.isRegistered, isTrue);
      expect(status.realUnitUserDataDto, isNull);
    });

    test('getWalletStatus throws ApiException on non-200', () async {
      final client = MockClient((_) async => http.Response(
            jsonEncode({'statusCode': 401, 'message': 'Unauthorized'}),
            401,
          ));

      expect(
        () => build(client).getWalletStatus(),
        throwsA(isA<ApiException>()),
      );
    });
  });
}
