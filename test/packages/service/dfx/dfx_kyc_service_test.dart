import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mocktail/mocktail.dart';
import 'package:realunit_wallet/packages/config/api_config.dart';
import 'package:realunit_wallet/packages/config/network_mode.dart';
import 'package:realunit_wallet/packages/repository/cache_repository.dart';
import 'package:realunit_wallet/packages/service/app_store.dart';
import 'package:realunit_wallet/packages/service/dfx/dfx_kyc_service.dart';
import 'package:realunit_wallet/packages/service/dfx/exceptions/api_exception.dart';
import 'package:realunit_wallet/packages/service/session_cache.dart';
import 'package:realunit_wallet/packages/service/wallet_service.dart';
import 'package:realunit_wallet/packages/wallet/wallet.dart';
import 'package:realunit_wallet/packages/wallet/wallet_account.dart';
import 'package:web3dart/web3dart.dart';

class _MockAppStore extends Mock implements AppStore {}

class _MockCacheRepository extends Mock implements CacheRepository {}

class _MockWalletService extends Mock implements WalletService {}

class _StubWalletAccount extends AWalletAccount {
  _StubWalletAccount() : super(0, _StubCreds());
  @override
  Future<String> signMessage(String message, {int addressIndex = 0}) async =>
      '0xstub-signature';
}

class _StubCreds extends Fake implements CredentialsWithKnownAddress {
  @override
  EthereumAddress get address =>
      EthereumAddress.fromHex('0x0000000000000000000000000000000000000001');
}

class _StubWallet extends AWallet {
  _StubWallet() : super(1, 'Stub');
  @override
  WalletType get walletType => WalletType.software;
  @override
  AWalletAccount get primaryAccount => _StubWalletAccount();
  @override
  AWalletAccount get currentAccount => _StubWalletAccount();
}

const _userJson = {
  'mail': 'a@b.com',
  'kyc': {
    'hash': 'kyc-hash-123',
    // Wire format is the numeric level (20 → KycLevel.level20).
    'level': 20,
    'dataComplete': true,
  },
};

void main() {
  late _MockAppStore appStore;
  late _MockWalletService walletService;
  late SessionCache sessionCache;

  setUp(() {
    appStore = _MockAppStore();
    walletService = _MockWalletService();
    sessionCache = SessionCache(_MockCacheRepository());
    sessionCache.setAuthToken('jwt-1');
    when(() => appStore.sessionCache).thenReturn(sessionCache);
    when(() => appStore.apiConfig)
        .thenReturn(const ApiConfig(networkMode: NetworkMode.mainnet));
    when(() => appStore.wallet).thenReturn(_StubWallet());
    when(() => walletService.ensureCurrentWalletUnlocked()).thenAnswer((_) async {});
    when(() => walletService.lockCurrentWallet()).thenAnswer((_) async {});
  });

  DfxKycService build(http.Client client) {
    when(() => appStore.httpClient).thenReturn(client);
    return DfxKycService(appStore, walletService);
  }

  group('$DfxKycService', () {
    group('getUser', () {
      test('GETs /v2/user with the Bearer JWT and parses the response', () async {
        String? path;
        String? auth;
        final client = MockClient((request) async {
          path = request.url.path;
          auth = request.headers['Authorization'];
          return http.Response(jsonEncode(_userJson), 200);
        });

        final user = await build(client).getUser();

        expect(user.mail, 'a@b.com');
        expect(user.kyc.hash, 'kyc-hash-123');
        expect(path, '/v2/user');
        expect(auth, 'Bearer jwt-1');
      });

      test('accepts a 201 in addition to 200', () async {
        final client = MockClient(
          (_) async => http.Response(jsonEncode(_userJson), 201),
        );

        final user = await build(client).getUser();
        expect(user.mail, 'a@b.com');
      });

      test('throws ApiException on a non-2xx non-401 response', () async {
        final client = MockClient((_) async => http.Response(
              jsonEncode({'statusCode': 500, 'message': 'oops'}),
              500,
            ));

        expect(() => build(client).getUser(), throwsA(isA<ApiException>()));
      });
    });

    group('updateUser', () {
      test('PUTs /v2/user with the JSON body and Bearer JWT', () async {
        Map<String, dynamic>? body;
        String? method;
        final client = MockClient((request) async {
          body = jsonDecode(request.body) as Map<String, dynamic>;
          method = request.method;
          return http.Response('{}', 200);
        });

        await build(client).updateUser({'phone': '+41790000000'});

        expect(method, 'PUT');
        expect(body!['phone'], '+41790000000');
      });

      test('accepts a 201 response', () async {
        final client = MockClient((_) async => http.Response('{}', 201));

        await build(client).updateUser({'x': 'y'});
      });

      test('throws ApiException on non-2xx', () async {
        final client = MockClient((_) async => http.Response(
              jsonEncode({'statusCode': 422, 'message': 'bad'}),
              422,
            ));

        expect(
          () => build(client).updateUser({'phone': 'x'}),
          throwsA(isA<ApiException>()),
        );
      });
    });

    group('request2FaCode', () {
      test('POSTs /v2/kyc/2fa?level=Strict with kyc-hash header', () async {
        Uri? uri;
        Map<String, String>? headers;
        String? method;
        final client = MockClient((request) async {
          uri = request.url;
          headers = request.headers;
          method = request.method;
          if (request.url.path == '/v2/user') {
            return http.Response(jsonEncode(_userJson), 200);
          }
          return http.Response('{}', 201);
        });

        await build(client).request2FaCode();

        expect(method, 'POST');
        expect(uri!.path, '/v2/kyc/2fa');
        expect(uri!.queryParameters['level'], 'Strict');
        expect(headers!['x-kyc-code'], 'kyc-hash-123');
      });

      test('throws ApiException on non-2xx', () async {
        final client = MockClient((request) async {
          if (request.url.path == '/v2/user') {
            return http.Response(jsonEncode(_userJson), 200);
          }
          return http.Response(
            jsonEncode({'statusCode': 429, 'message': 'too many'}),
            429,
          );
        });

        expect(
          () => build(client).request2FaCode(),
          throwsA(isA<ApiException>()),
        );
      });
    });

    group('verify2FaCode', () {
      test('POSTs the token to /v2/kyc/2fa/verify with kyc-hash header', () async {
        Map<String, dynamic>? body;
        Uri? uri;
        Map<String, String>? headers;
        final client = MockClient((request) async {
          if (request.url.path == '/v2/user') {
            return http.Response(jsonEncode(_userJson), 200);
          }
          uri = request.url;
          headers = request.headers;
          body = jsonDecode(request.body) as Map<String, dynamic>;
          return http.Response('{}', 201);
        });

        await build(client).verify2FaCode('123456');

        expect(uri!.path, '/v2/kyc/2fa/verify');
        expect(body!['token'], '123456');
        expect(headers!['x-kyc-code'], 'kyc-hash-123');
      });

      test('throws ApiException on non-2xx', () async {
        final client = MockClient((request) async {
          if (request.url.path == '/v2/user') {
            return http.Response(jsonEncode(_userJson), 200);
          }
          return http.Response(
            jsonEncode({'statusCode': 403, 'message': 'wrong code'}),
            403,
          );
        });

        expect(
          () => build(client).verify2FaCode('000000'),
          throwsA(isA<ApiException>()),
        );
      });
    });
  });
}
