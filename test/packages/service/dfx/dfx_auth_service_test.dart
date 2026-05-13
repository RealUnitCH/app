import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mocktail/mocktail.dart';
import 'package:realunit_wallet/packages/config/api_config.dart';
import 'package:realunit_wallet/packages/repository/cache_repository.dart';
import 'package:realunit_wallet/packages/service/app_store.dart';
import 'package:realunit_wallet/packages/service/dfx/dfx_auth_service.dart';
import 'package:realunit_wallet/packages/service/session_cache.dart';
import 'package:realunit_wallet/packages/wallet/wallet_account.dart';

class MockApiConfig extends Mock implements ApiConfig {}

class MockCacheRepository extends Mock implements CacheRepository {}

class TestAppStore extends AppStore {
  final http.Client client;

  TestAppStore(this.client) : super(MockApiConfig.new, SessionCache(MockCacheRepository()));

  @override
  http.Client get httpClient => client;
}

class TestAuthService extends DFXAuthService {
  TestAuthService(super.appStore);

  int authTokenCalls = 0;
  int refreshAuthTokenCalls = 0;

  @override
  AWalletAccount get wallet => throw UnimplementedError();

  @override
  String get walletAddress => throw UnimplementedError();

  @override
  Future<String?> getAuthToken() async {
    authTokenCalls++;
    return 'expired-token';
  }

  @override
  Future<String?> refreshAuthToken() async {
    refreshAuthTokenCalls++;
    return 'fresh-token';
  }
}

void main() {
  group('$DFXAuthService', () {
    test('retries authenticated requests once with a refreshed token on 401', () async {
      final seenAuthHeaders = <String?>[];
      final client = MockClient((request) async {
        seenAuthHeaders.add(request.headers['Authorization']);

        if (seenAuthHeaders.length == 1) {
          return http.Response('{"message":"Unauthorized"}', 401);
        }

        return http.Response('{"ok":true}', 200);
      });
      final service = TestAuthService(TestAppStore(client));

      final response = await service.authenticatedPut(
        Uri.parse('https://api.example.test/v1/resource'),
        headers: {'Content-Type': 'application/json'},
        body: '{"value":1}',
      );

      expect(response.statusCode, 200);
      expect(seenAuthHeaders, ['Bearer expired-token', 'Bearer fresh-token']);
      expect(service.authTokenCalls, 1);
      expect(service.refreshAuthTokenCalls, 1);
    });
  });
}
