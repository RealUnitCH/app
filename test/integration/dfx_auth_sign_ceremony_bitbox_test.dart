// Cross-layer integration test for the DFX auth-sign ceremony driven by a
// BitBox wallet. Stitches together every layer the cold-cache JWT round-trip
// touches:
//
//   DFXAuthService.getAuthToken
//     → getSignMessage (HTTP via MockClient)
//     → BitboxWalletAccount.signMessage
//       → BitboxCredentials.signPersonalMessage (FakeBitboxCredentials)
//     → getAuthResponse (HTTP via MockClient)
//     → JWT stored in SessionCache
//
// These tests live in `test/integration/` rather than the per-layer suites
// because the BitBox cancel / disconnect / timeout / 403 paths only show
// their real shape when the auth service, the wallet account, the hardware
// credentials, and the wire surface are exercised together. The single-layer
// suites are still the canonical place for fine-grained branch pinning; this
// file guards the seams.
//
// HTTP boundary: `MockClient` from `package:http/testing`. Hardware boundary:
// `FakeBitboxCredentials` (the existing test helper that already implements
// `signPersonalMessage` with selectable behaviour). The DFXAuthService and
// SessionCache instances are the real production code.

import 'dart:async';
import 'dart:convert';

import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mocktail/mocktail.dart';
import 'package:realunit_wallet/packages/config/api_config.dart';
import 'package:realunit_wallet/packages/config/network_mode.dart';
import 'package:realunit_wallet/packages/repository/cache_repository.dart';
import 'package:realunit_wallet/packages/service/app_store.dart';
import 'package:realunit_wallet/packages/service/dfx/dfx_auth_service.dart';
import 'package:realunit_wallet/packages/service/session_cache.dart';
import 'package:realunit_wallet/packages/service/wallet_service.dart';
import 'package:realunit_wallet/packages/wallet/exceptions/signing_cancelled_exception.dart';
import 'package:realunit_wallet/packages/wallet/wallet_account.dart';

import '../helper/fake_bitbox_credentials.dart';

class _MockAppStore extends Mock implements AppStore {}

class _MockWalletService extends Mock implements WalletService {}

class _MockCacheRepository extends Mock implements CacheRepository {}

/// Concrete DFXAuthService that exposes the BitBox-backed wallet account as
/// the current wallet — same shim other DFXAuthService suites use to avoid
/// dragging the AppStore's full wallet graph into the test.
class _BitboxAuthService extends DFXAuthService {
  _BitboxAuthService(super.appStore, super.walletService, this._account);

  final AWalletAccount _account;

  @override
  AWalletAccount get wallet => _account;

  @override
  String get walletAddress => _account.primaryAddress.address.hexEip55;
}

void main() {
  setUpAll(() {
    // Required by mocktail for the `appStore.httpClient` stub when the test
    // overrides it with a fresh MockClient mid-flow.
    registerFallbackValue(MockClient((_) async => http.Response('', 200)));
  });

  group('DFXAuthService.getAuthToken × BitboxCredentials sign ceremony', () {
    late _MockAppStore appStore;
    late _MockWalletService walletService;
    late SessionCache sessionCache;
    late _MockCacheRepository cacheRepo;
    late FakeBitboxCredentials credentials;
    late BitboxWalletAccount account;

    const jwt = 'jwt-fresh-token';

    setUp(() {
      appStore = _MockAppStore();
      walletService = _MockWalletService();
      cacheRepo = _MockCacheRepository();
      // Production SessionCache wired to a stubbed CacheRepository so the
      // signature/JWT writes resolve without hitting disk.
      when(() => cacheRepo.read(any())).thenAnswer((_) async => null);
      when(() => cacheRepo.write(any(), any())).thenAnswer((_) async => 1);
      when(() => cacheRepo.delete(any())).thenAnswer((_) async {});
      sessionCache = SessionCache(cacheRepo);

      credentials = FakeBitboxCredentials(signDelay: Duration.zero);
      account = BitboxWalletAccount(0, credentials);

      when(() => appStore.sessionCache).thenReturn(sessionCache);
      when(
        () => appStore.apiConfig,
      ).thenReturn(const ApiConfig(networkMode: NetworkMode.mainnet));
      // Software-wallet unlock/lock are no-ops on a BitBox path — every sign
      // crosses BLE/USB, never the local AES-GCM mnemonic store. Stubbing
      // them lets the production `getSignature` finally-block run unchanged.
      when(() => walletService.ensureCurrentWalletUnlocked()).thenAnswer((_) async {});
      when(() => walletService.lockCurrentWallet()).thenAnswer((_) async {});
    });

    _BitboxAuthService buildService(http.Client client) {
      when(() => appStore.httpClient).thenReturn(client);
      return _BitboxAuthService(appStore, walletService, account);
    }

    test(
      'happy path: cold cache → local sign message → BitBox sign → auth POST 201 → JWT cached',
      () async {
        final calls = <String>[];
        Map<String, dynamic>? authBody;
        final client = MockClient((request) async {
          calls.add('${request.method} ${request.url.path}');
          if (request.method == 'POST' && request.url.path == '/v1/auth') {
            authBody = jsonDecode(request.body) as Map<String, dynamic>;
            return http.Response(jsonEncode({'accessToken': jwt}), 201);
          }
          return http.Response('unexpected ${request.method} ${request.url}', 500);
        });

        final service = buildService(client);

        final token = await service.getAuthToken();

        expect(token, jwt);
        // The sign message is built locally now, so the only HTTP call is the
        // auth POST — no /v1/auth/signMessage round-trip.
        expect(calls, ['POST /v1/auth']);
        // BitBox signed exactly once — the cancel/disconnect guards never
        // forced a retry on the happy path.
        expect(credentials.signCallCount, 1);
        // The wire body carries the BitBox-derived signature alongside the
        // wallet name and the address.
        expect(authBody!['wallet'], 'RealUnit');
        expect(authBody!['address'], credentials.address.hexEip55);
        final wireSig = authBody!['signature'] as String;
        expect(wireSig, startsWith('0x'));
        // 65-byte secp256k1 signature → 0x + 130 hex chars.
        expect(wireSig.length, 132);

        // SessionCache holds both the JWT and the signature — a second
        // `ensureSignatureFor` call must short-circuit without re-signing.
        expect(sessionCache.authToken, jwt);
        expect(sessionCache.signature, wireSig);
        expect(sessionCache.signatureAddress, credentials.address.hexEip55);

        await service.ensureSignatureFor(account);
        expect(
          credentials.signCallCount,
          1,
          reason: 'ensureSignatureFor must not re-trigger the device when the cache is warm',
        );
      },
    );

    test(
      'cancel mid-sign: FakeBitbox returns empty bytes → SigningCancelledException, no POST, no JWT',
      () async {
        credentials.behavior = FakeBitboxBehavior.cancel;
        final calls = <String>[];
        final client = MockClient((request) async {
          calls.add('${request.method} ${request.url.path}');
          // If the POST ever fires the cancel guard didn't fire — fail loudly.
          return http.Response('cancel did not short-circuit', 500);
        });

        final service = buildService(client);

        await expectLater(
          service.getAuthToken(),
          throwsA(isA<SigningCancelledException>()),
        );

        // No HTTP at all: the message is built locally and the cancel happens
        // during signing, before any auth POST.
        expect(calls, isEmpty);
        expect(credentials.signCallCount, 1);
        expect(sessionCache.authToken, isNull);
        expect(sessionCache.signature, isNull);
        // The cancel path still walks the unlock/lock finally — verify the
        // lock fires exactly once so a future refactor can't leak an unlocked
        // software-wallet state on the BitBox path.
        verify(() => walletService.lockCurrentWallet()).called(1);
      },
    );

    test(
      'sign-message timeout: hung FakeBitbox + fake_async crosses the 3-min cap → TimeoutException + lock fires',
      () {
        credentials.behavior = FakeBitboxBehavior.timeout;
        // Disable any default signDelay so the only thing keeping the sign
        // pending is the FakeBitboxBehavior.timeout `Completer<void>().future`.
        credentials.signDelay = Duration.zero;

        fakeAsync((async) {
          final client = MockClient(
            (_) async => http.Response('should never POST on a timed-out sign', 500),
          );
          final service = buildService(client);

          Object? caught;
          unawaited(
            service.getAuthToken().catchError((Object e) {
              caught = e;
              return null;
            }),
          );

          // Just under the 3-min `_signMessageTimeout`: still pending.
          async.elapse(const Duration(minutes: 2, seconds: 59));
          expect(caught, isNull);

          // Crossing the cap surfaces a TimeoutException. The BitBox sign
          // hangs forever otherwise — this guard is what stops the UI from
          // wedging on a frozen device.
          async.elapse(const Duration(seconds: 2));
          expect(caught, isA<TimeoutException>());

          // The unlock/lock finally MUST run even on timeout — otherwise a
          // hung BitBox would leak the decrypted-mnemonic state on the
          // software-wallet side of the same code path.
          verify(() => walletService.lockCurrentWallet()).called(1);
        });
      },
    );

    test(
      '403 country-blocked: sign succeeds, auth POST returns 403 with message → Exception propagated to caller',
      () async {
        final client = MockClient(
          (_) async => http.Response(
            jsonEncode({'statusCode': 403, 'message': 'country-blocked: CH'}),
            403,
          ),
        );
        final service = buildService(client);

        await expectLater(
          service.getAuthToken(),
          throwsA(
            isA<Exception>().having(
              (e) => e.toString(),
              'toString()',
              contains('country-blocked: CH'),
            ),
          ),
        );

        // The sign DID happen — the 403 is a server-side decision after the
        // BitBox produced a real signature. Critical guard against a future
        // refactor that tries to short-circuit the sign on a country check.
        expect(credentials.signCallCount, 1);
        // …but no JWT was cached: the 403 must abort the cache write.
        expect(sessionCache.authToken, isNull);
        // The signature however IS persisted (it's a property of the wallet,
        // not the auth response). A retry against a different region must
        // not re-trigger the device.
        expect(sessionCache.signature, isNotNull);
      },
    );
  });
}
