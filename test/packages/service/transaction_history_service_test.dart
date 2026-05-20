import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mocktail/mocktail.dart';
import 'package:realunit_wallet/packages/config/api_config.dart';
import 'package:realunit_wallet/packages/config/network_mode.dart';
import 'package:realunit_wallet/packages/repository/cache_repository.dart';
import 'package:realunit_wallet/packages/repository/transaction_repository.dart';
import 'package:realunit_wallet/packages/service/app_store.dart';
import 'package:realunit_wallet/packages/service/session_cache.dart';
import 'package:realunit_wallet/packages/service/transaction_history_service.dart';
import 'package:realunit_wallet/packages/service/wallet_service.dart';

class _MockAppStore extends Mock implements AppStore {}

class _MockCacheRepository extends Mock implements CacheRepository {}

class _MockTransactionRepository extends Mock implements TransactionRepository {}

class _MockWalletService extends Mock implements WalletService {}

const _wallet = '0x000000000000000000000000000000000000beef';
const _other = '0x0000000000000000000000000000000000001234';

Map<String, dynamic> _txJson({
  int id = 1,
  String state = 'Processing',
  String? source = _wallet,
  String? target,
}) =>
    {
      'id': id,
      'type': 'Buy',
      'state': state,
      'rate': 1.0,
      'inputAmount': 100.0,
      'inputAsset': 'CHF',
      'inputTxId': null,
      'outputAmount': 1.0,
      'outputAsset': 'REALU',
      'outputTxId': null,
      'sourceAccount': source,
      'targetAccount': target,
    };

void main() {
  late _MockAppStore appStore;
  late _MockWalletService walletService;
  late SessionCache sessionCache;
  late _MockTransactionRepository txRepo;

  setUp(() {
    appStore = _MockAppStore();
    walletService = _MockWalletService();
    sessionCache = SessionCache(_MockCacheRepository());
    txRepo = _MockTransactionRepository();
    when(() => appStore.sessionCache).thenReturn(sessionCache);
    when(() => appStore.apiConfig)
        .thenReturn(const ApiConfig(networkMode: NetworkMode.mainnet));
    when(() => appStore.primaryAddress).thenReturn(_wallet);
    when(() => walletService.ensureCurrentWalletUnlocked()).thenAnswer((_) async {});
    when(() => walletService.lockCurrentWallet()).thenAnswer((_) async {});
  });

  TransactionHistoryService build(http.Client client) {
    when(() => appStore.httpClient).thenReturn(client);
    return TransactionHistoryService(appStore, walletService, txRepo);
  }

  group('$TransactionHistoryService', () {
    group('fetchPendingTransactions', () {
      // The pre-migration "no auth token -> silent empty list" branch is
      // gone: the request now routes through `authenticatedGet`, which
      // triggers the sign + token-exchange bootstrap on a missing token and
      // refreshes on 401. The 401-retry plumbing is exercised exhaustively
      // in `dfx_auth_service_test.dart`.

      test('GETs /v1/transaction/detail with the Bearer JWT', () async {
        sessionCache.setAuthToken('jwt-1');
        String? auth;
        String? path;
        final client = MockClient((request) async {
          auth = request.headers['Authorization'];
          path = request.url.path;
          return http.Response(jsonEncode([_txJson()]), 200);
        });

        await build(client).fetchPendingTransactions();

        expect(auth, 'Bearer jwt-1');
        expect(path, '/v1/transaction/detail');
      });

      test('returns [] on non-200 (does not throw)', () async {
        sessionCache.setAuthToken('jwt-1');
        final client = MockClient((_) async => http.Response('boom', 500));

        final list = await build(client).fetchPendingTransactions();

        expect(list, isEmpty);
      });

      test('filters out completed transactions (isPending=false)', () async {
        sessionCache.setAuthToken('jwt-1');
        final client = MockClient((_) async => http.Response(
              jsonEncode([
                _txJson(id: 1, state: 'Processing'),
                _txJson(id: 2, state: 'Completed'),
                _txJson(id: 3, state: 'Failed'),
                _txJson(id: 4, state: 'Returned'),
                _txJson(id: 5, state: 'CheckPending'),
              ]),
              200,
            ));

        final list = await build(client).fetchPendingTransactions();

        expect(list.map((t) => t.id), [1, 5]);
      });

      test('filters out transactions that do not belong to the current wallet', () async {
        sessionCache.setAuthToken('jwt-1');
        final client = MockClient((_) async => http.Response(
              jsonEncode([
                _txJson(id: 1, source: _wallet),
                _txJson(id: 2, source: _other, target: _other),
                _txJson(id: 3, source: null, target: _wallet),
              ]),
              200,
            ));

        final list = await build(client).fetchPendingTransactions();

        // 1 (source = wallet) and 3 (target = wallet) belong, 2 doesn't.
        expect(list.map((t) => t.id), [1, 3]);
      });

      test('wallet match is case-insensitive', () async {
        sessionCache.setAuthToken('jwt-1');
        when(() => appStore.primaryAddress).thenReturn(_wallet.toUpperCase());
        final client = MockClient((_) async => http.Response(
              jsonEncode([_txJson(id: 1, source: _wallet)]),
              200,
            ));

        final list = await build(client).fetchPendingTransactions();

        expect(list, hasLength(1));
      });
    });
  });
}
