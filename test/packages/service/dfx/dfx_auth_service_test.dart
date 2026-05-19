import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mocktail/mocktail.dart';
import 'package:realunit_wallet/packages/config/api_config.dart';
import 'package:realunit_wallet/packages/repository/cache_repository.dart';
import 'package:realunit_wallet/packages/service/app_store.dart';
import 'package:realunit_wallet/packages/service/dfx/dfx_auth_service.dart';
import 'package:realunit_wallet/packages/service/session_cache.dart';
import 'package:realunit_wallet/packages/wallet/exceptions/signing_cancelled_exception.dart';
import 'package:realunit_wallet/packages/wallet/wallet_account.dart';
import 'package:web3dart/web3dart.dart';

// ---------------------------------------------------------------------------
// Helpers — signature / cache surface (see `getSignature`, `getAuthToken`).
// ---------------------------------------------------------------------------

class _MockAppStore extends Mock implements AppStore {}

class _MockSessionCache extends Mock implements SessionCache {}

class _StubWalletAccount extends AWalletAccount {
  _StubWalletAccount(this._signature)
    : super(
        0,
        EthPrivateKey.fromHex(
          'fb1ace12f9801e85f3db1b3935dd47d9f064f98152466f47c701b5e12680e612',
        ),
      );

  final String _signature;
  int signCallCount = 0;

  @override
  Future<String> signMessage(String message, {int addressIndex = 0}) async {
    signCallCount++;
    return _signature;
  }
}

class _SignatureTestAuthService extends DFXAuthService {
  _SignatureTestAuthService(super.appStore, this._wallet, this._address);

  final AWalletAccount _wallet;
  final String _address;

  @override
  AWalletAccount get wallet => _wallet;

  @override
  String get walletAddress => _address;
}

// ---------------------------------------------------------------------------
// Helpers — authenticated request retry-on-401 surface.
// ---------------------------------------------------------------------------

class _MockApiConfig extends Mock implements ApiConfig {}

class _MockCacheRepository extends Mock implements CacheRepository {}

class _RetryTestAppStore extends AppStore {
  _RetryTestAppStore(this._client)
    : super(_MockApiConfig.new, SessionCache(_MockCacheRepository()));

  final http.Client _client;

  @override
  http.Client get httpClient => _client;
}

class _RetryTestAuthService extends DFXAuthService {
  _RetryTestAuthService(super.appStore);

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
  // -------------------------------------------------------------------------
  // getSignature / getAuthToken — signature cache + empty-sig guards.
  // -------------------------------------------------------------------------

  group('$DFXAuthService getSignature / getAuthToken', () {
    late AppStore appStore;
    late SessionCache sessionCache;
    late _StubWalletAccount walletAccount;

    const address = '0x1111111111111111111111111111111111111111';
    const validSig = '0xdeadbeef';

    setUp(() {
      appStore = _MockAppStore();
      sessionCache = _MockSessionCache();
      walletAccount = _StubWalletAccount(validSig);

      when(() => appStore.sessionCache).thenReturn(sessionCache);
      when(() => sessionCache.signature).thenReturn(null);
      when(() => sessionCache.signatureAddress).thenReturn(null);
      when(() => sessionCache.authToken).thenReturn(null);
      when(() => sessionCache.saveSignature(any(), any())).thenAnswer((_) async {});
    });

    _SignatureTestAuthService buildService() =>
        _SignatureTestAuthService(appStore, walletAccount, address);

    group('getSignature', () {
      test('returns the cached signature when address matches (no re-sign)', () async {
        when(() => sessionCache.signature).thenReturn(validSig);
        when(() => sessionCache.signatureAddress).thenReturn(address);

        final result = await buildService().getSignature('msg');

        expect(result, validSig);
        expect(walletAccount.signCallCount, 0);
        verifyNever(() => sessionCache.saveSignature(any(), any()));
      });

      test('signs and caches when no cached signature exists', () async {
        final result = await buildService().getSignature('msg');

        expect(result, validSig);
        expect(walletAccount.signCallCount, 1);
        verify(() => sessionCache.saveSignature(address, validSig)).called(1);
      });

      test('signs again when the cached signature belongs to a different address', () async {
        when(() => sessionCache.signature).thenReturn(validSig);
        when(() => sessionCache.signatureAddress).thenReturn(
          '0x2222222222222222222222222222222222222222',
        );

        final result = await buildService().getSignature('msg');

        expect(result, validSig);
        expect(walletAccount.signCallCount, 1);
      });

      for (final emptySignature in const ['', '0x']) {
        test(
          'throws SigningCancelledException when the wallet returns "$emptySignature"',
          () async {
            walletAccount = _StubWalletAccount(emptySignature);

            expect(
              () => buildService().getSignature('msg'),
              throwsA(isA<SigningCancelledException>()),
            );
          },
        );
      }
    });

    group('getAuthToken', () {
      test('returns the cached auth token without re-signing', () async {
        when(() => sessionCache.authToken).thenReturn('cached.jwt.token');

        final token = await buildService().getAuthToken();

        expect(token, 'cached.jwt.token');
        expect(walletAccount.signCallCount, 0);
      });
    });

    // TODO(#314 Phase 0): cover the 3 min `_signMessageTimeout` via the
    // `fake_async` package. Not yet a dev_dependency in this repo — adding it
    // would require a follow-up. Captured here as an explicit gap.
  });

  // -------------------------------------------------------------------------
  // authenticatedGet/Put/Post — one-time refresh-on-401 retry.
  // -------------------------------------------------------------------------

  group('$DFXAuthService authenticated requests', () {
    test('authenticatedGet retries once with a refreshed token on 401', () async {
      final seenAuthHeaders = <String?>[];
      final seenMethods = <String>[];
      final client = MockClient((request) async {
        seenAuthHeaders.add(request.headers['Authorization']);
        seenMethods.add(request.method);

        if (seenAuthHeaders.length == 1) {
          return http.Response('{"message":"Unauthorized"}', 401);
        }
        return http.Response('{"ok":true}', 200);
      });
      final service = _RetryTestAuthService(_RetryTestAppStore(client));

      final response = await service.authenticatedGet(
        Uri.parse('https://api.example.test/v1/resource'),
        headers: {'Accept': 'application/json'},
      );

      expect(response.statusCode, 200);
      expect(seenMethods, ['GET', 'GET']);
      expect(seenAuthHeaders, ['Bearer expired-token', 'Bearer fresh-token']);
      expect(service.authTokenCalls, 1);
      expect(service.refreshAuthTokenCalls, 1);
    });

    test('authenticatedPost retries once with a refreshed token on 401 and resends the body',
        () async {
      final seenAuthHeaders = <String?>[];
      final seenBodies = <String>[];
      final client = MockClient((request) async {
        seenAuthHeaders.add(request.headers['Authorization']);
        seenBodies.add(request.body);

        if (seenAuthHeaders.length == 1) {
          return http.Response('{"message":"Unauthorized"}', 401);
        }
        return http.Response('{"ok":true}', 201);
      });
      final service = _RetryTestAuthService(_RetryTestAppStore(client));

      final response = await service.authenticatedPost(
        Uri.parse('https://api.example.test/v1/resource'),
        headers: {'Content-Type': 'application/json'},
        body: '{"value":1}',
      );

      expect(response.statusCode, 201);
      expect(seenAuthHeaders, ['Bearer expired-token', 'Bearer fresh-token']);
      // Same body resent on retry — no truncation, no double-encoding.
      expect(seenBodies, ['{"value":1}', '{"value":1}']);
      expect(service.refreshAuthTokenCalls, 1);
    });

    test('authenticatedPut retries once with a refreshed token on 401 and resends the body',
        () async {
      final seenAuthHeaders = <String?>[];
      final seenBodies = <String>[];
      final client = MockClient((request) async {
        seenAuthHeaders.add(request.headers['Authorization']);
        seenBodies.add(request.body);

        if (seenAuthHeaders.length == 1) {
          return http.Response('{"message":"Unauthorized"}', 401);
        }
        return http.Response('{"ok":true}', 200);
      });
      final service = _RetryTestAuthService(_RetryTestAppStore(client));

      final response = await service.authenticatedPut(
        Uri.parse('https://api.example.test/v1/resource'),
        headers: {'Content-Type': 'application/json'},
        body: '{"value":1}',
      );

      expect(response.statusCode, 200);
      expect(seenAuthHeaders, ['Bearer expired-token', 'Bearer fresh-token']);
      expect(seenBodies, ['{"value":1}', '{"value":1}']);
      expect(service.refreshAuthTokenCalls, 1);
    });

    test('does not retry a third time when the refreshed token also yields 401', () async {
      var calls = 0;
      final client = MockClient((_) async {
        calls++;
        return http.Response('{"message":"Unauthorized"}', 401);
      });
      final service = _RetryTestAuthService(_RetryTestAppStore(client));

      final response = await service.authenticatedGet(
        Uri.parse('https://api.example.test/v1/resource'),
      );

      // Exactly two HTTP calls — initial + one retry — and the 401 is
      // surfaced to the caller.
      expect(calls, 2);
      expect(response.statusCode, 401);
      expect(service.refreshAuthTokenCalls, 1);
    });

    test('propagates exceptions thrown by refreshAuthToken without swallowing them',
        () async {
      final client = MockClient((_) async => http.Response(
            '{"message":"Unauthorized"}',
            401,
          ));
      final service = _ThrowingRefreshAuthService(_RetryTestAppStore(client));

      await expectLater(
        service.authenticatedGet(Uri.parse('https://api.example.test/v1/resource')),
        throwsA(isA<StateError>()),
      );
      expect(service.refreshAuthTokenCalls, 1);
    });
  });
}

class _ThrowingRefreshAuthService extends DFXAuthService {
  _ThrowingRefreshAuthService(super.appStore);

  int refreshAuthTokenCalls = 0;

  @override
  AWalletAccount get wallet => throw UnimplementedError();

  @override
  String get walletAddress => throw UnimplementedError();

  @override
  Future<String?> getAuthToken() async => 'expired-token';

  @override
  Future<String?> refreshAuthToken() async {
    refreshAuthTokenCalls++;
    throw StateError('refresh boom');
  }
}
