// Cross-layer integration tests for the OpenCryptoPay pay flow.
//
// These tests stitch together the layers that a 1 EUR / 0.95 ZCHF merchant
// bill touches end-to-end. That bill is the original screenshot bug (quote
// showed 0 REALU sold vs ~0.95 ZCHF needed, Pay disabled) and the leftover
// sweep (the pay unsigned-tx `amountWei` is the full ZCHF balance, not the
// 0.95 quote):
//
//   PayQuoteCubit / PayProcessCubit
//     → FakeBitboxCredentials.signToSignature (BitBox boundary, no real
//       BLE/USB stack)
//     → RealUnitPayService (real production class)
//     → MockClient (last-mile HTTP boundary stand-in)
//
// We deliberately wire up the real RealUnitPayService instead of stubbing
// it — the goal is to pin the contract between the cubits and the service
// AND the wire-format the service produces. The MockClient plays the fixed
// API: PUT /v1/realunit/swap with targetAmount 0.95 returns amount: 1,
// isValid: true. The app does not ceil shares locally; Ready displays the
// JSON `amount`. PayProcessCubit signs that confirmed quote (id 99) and
// does not request a second swap.
//
// They run headless (no device, no simulator, no live merchant QR), so they
// live under `test/integration/` and run as part of `flutter test`.

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
import 'package:realunit_wallet/packages/service/dfx/api_client.dart';
import 'package:realunit_wallet/packages/service/dfx/dfx_blockchain_api_service.dart';
import 'package:realunit_wallet/packages/service/dfx/dfx_faucet_service.dart';
import 'package:realunit_wallet/packages/service/dfx/models/payment/pay/swap_payment_info.dart';
import 'package:realunit_wallet/packages/service/dfx/real_unit_pay_service.dart';
import 'package:realunit_wallet/packages/service/session_cache.dart';
import 'package:realunit_wallet/packages/service/wallet_service.dart';
import 'package:realunit_wallet/packages/wallet/wallet.dart';
import 'package:realunit_wallet/packages/wallet/wallet_account.dart';
import 'package:realunit_wallet/screens/pay/cubits/pay_process/pay_process_cubit.dart';
import 'package:realunit_wallet/screens/pay/cubits/pay_quote/pay_quote_cubit.dart';

import '../helper/fake_bitbox_credentials.dart';

class _MockFaucet extends Mock implements DfxFaucetService {}

class _MockBlockchain extends Mock implements DfxBlockchainApiService {}

class _MockAppStore extends Mock implements AppStore {}

class _MockWallet extends Mock implements AWallet {}

class _MockWalletAccount extends Mock implements AWalletAccount {}

class _MockWalletService extends Mock implements WalletService {}

class _MockCacheRepository extends Mock implements CacheRepository {}

const _paymentLinkId = 'pl_realunit_ocp_1eur';
const _lnurlpPath = '/v1/lnurlp/pl_realunit_ocp_1eur';
const _swapPath = '/v1/realunit/swap';
const _swapUnsignedPath = '/v1/realunit/swap/99/unsigned-transaction';
const _swapBroadcastPath = '/v1/realunit/swap/99/broadcast';
const _payUnsignedPath = '/v1/realunit/pay/unsigned-transaction';
const _paySubmitPath = '/v1/realunit/pay/submit';
const _payStatusPath = '/v1/realunit/pay/pl_realunit_ocp_1eur/status';

// Verified EIP-1559 unsigned pay tx from pay_process_cubit_test.dart
// (`amountWei: 5 ZCHF` vs a 0.95 quote — the leftover overpay). The app must
// forward this hex unchanged; it must not shrink amountWei to the quote.
const _unsignedPayHex =
    '0x02f87183aa36a7018459682f008504a817c800830186a094111111111111111111111111111111111111ac0180b844a9059cbb000000000000000000000000222222222222222222222222222222222222bc020000000000000000000000000000000000000000000000004563918244f40000c0';

Map<String, dynamic> _lnurlpJson() => {
  'requestedAmount': {'asset': 'EUR', 'amount': 1},
  'quote': {
    'id': 'plq_1eur',
    'expiration': DateTime.now().add(const Duration(minutes: 5)).toIso8601String(),
  },
  'transferAmounts': [
    {
      'method': 'Ethereum',
      'assets': [
        {'asset': 'ZCHF', 'amount': 0.95},
      ],
    },
  ],
};

Map<String, dynamic> _swapInfoJson({
  required num amount,
  required bool isValid,
  String? error,
}) => {
  'id': 99,
  'uid': 'MOCK-UID',
  'routeId': 7,
  'timestamp': '2026-06-03T00:00:00.000Z',
  'amount': amount,
  'estimatedAmount': 1.05,
  'targetAsset': 'ZCHF',
  'minVolume': 1,
  'maxVolume': 1000,
  'minVolumeTarget': 95,
  'maxVolumeTarget': 95000,
  'ethBalance': 1.0,
  'requiredGasEth': 0.001,
  'isValid': isValid,
  if (error != null) 'error': error,
  if (isValid) 'ethereumTransactionFeeChf': 0.05,
  if (isValid) 'ethereumTransactionFeeRealu': 0.01234567,
};

Map<String, dynamic> _unsignedPayJson() => {
  'unsignedTx': _unsignedPayHex,
  'tokenAddress': '0x111111111111111111111111111111111111ac01',
  'recipient': '0x222222222222222222222222222222222222bc02',
  'amountWei': '5000000000000000000',
  'chainId': 11155111,
};

void main() {
  late _MockFaucet faucet;
  late _MockBlockchain blockchain;
  late _MockAppStore appStore;
  late _MockWallet wallet;
  late _MockWalletAccount account;
  late _MockWalletService walletService;
  late SessionCache session;
  late FakeBitboxCredentials creds;

  setUp(() {
    faucet = _MockFaucet();
    blockchain = _MockBlockchain();
    appStore = _MockAppStore();
    wallet = _MockWallet();
    account = _MockWalletAccount();
    walletService = _MockWalletService();
    session = SessionCache(_MockCacheRepository());
    // Pre-seed an auth token so the service skips its sign-message round-trip.
    session.setAuthToken('jwt-test');

    creds = FakeBitboxCredentials(signDelay: Duration.zero);

    when(() => appStore.wallet).thenReturn(wallet);
    when(
      () => appStore.apiConfig,
    ).thenReturn(const ApiConfig(networkMode: NetworkMode.mainnet));
    when(() => appStore.sessionCache).thenReturn(session);
    when(() => appStore.primaryAddress).thenReturn(creds.address.hexEip55);
    when(() => wallet.walletType).thenReturn(WalletType.bitbox);
    when(() => wallet.currentAccount).thenReturn(account);
    when(() => account.primaryAddress).thenReturn(creds);
    when(() => walletService.ensureCurrentWalletUnlocked()).thenAnswer((_) async {});
    when(() => walletService.lockCurrentWallet()).thenAnswer((_) async {});
  });

  // Build a real [RealUnitPayService] backed by [client]. The cubits talk to
  // this service object — there is no service-level stub between the cubit
  // and the HTTP boundary.
  RealUnitPayService buildPayService(http.Client client) {
    when(() => appStore.httpClient).thenReturn(RealUnitApiClient(client));
    return RealUnitPayService(appStore, walletService);
  }

  group('pay OCP flow cross-layer: cubit → BitBox boundary → service → MockClient', () {
    test(
      '1 EUR / 0.95 ZCHF quote with a 1-share swap preview becomes PayQuoteReady',
      () async {
        // Original screenshot bug: 0 REALU sold / grey Pay. The MockClient
        // plays the fixed API (targetAmount 0.95 → amount: 1, isValid: true).
        // Ready with 1 share is the fix — the harness does not ceil locally.
        Map<String, dynamic>? swapBody;
        final client = MockClient((request) async {
          if (request.method == 'GET' && request.url.path == _lnurlpPath) {
            return http.Response(jsonEncode(_lnurlpJson()), 200);
          }
          if (request.method == 'PUT' && request.url.path == _swapPath) {
            swapBody = jsonDecode(request.body) as Map<String, dynamic>;
            return http.Response(
              jsonEncode(_swapInfoJson(amount: 1, isValid: true)),
              200,
            );
          }
          fail('unexpected ${request.method} ${request.url.path}');
        });

        final cubit = PayQuoteCubit(buildPayService(client), _paymentLinkId);
        await cubit.load();

        expect(cubit.state, isA<PayQuoteReady>());
        final state = cubit.state as PayQuoteReady;
        expect(state.fiatAsset, 'EUR');
        expect(state.fiatAmount, 1);
        expect(state.zchfAmount, 0.95);
        expect(state.swap.amount, 1);
        expect(state.swap.estimatedAmount, 1.05);
        expect(state.swap.id, 99);
        expect(state.swap.ethereumTransactionFeeChf, 0.05);
        expect(state.swap.ethereumTransactionFeeRealu, 0.01234567);

        expect(swapBody, isNotNull);
        expect(swapBody!['targetAmount'], 0.95);
        expect(swapBody!.containsKey('amount'), isFalse);

        await cubit.close();
      },
    );

    test('invalid 0-share swap preview is PayQuoteError, never Ready', () async {
      // Same lnurlp bill; the API returns amount: 0 / isValid: false. The app
      // surfaces AmountTooLow 1:1 and does not invent a 1-share Ready state.
      final client = MockClient((request) async {
        if (request.method == 'GET' && request.url.path == _lnurlpPath) {
          return http.Response(jsonEncode(_lnurlpJson()), 200);
        }
        if (request.method == 'PUT' && request.url.path == _swapPath) {
          return http.Response(
            jsonEncode(
              _swapInfoJson(amount: 0, isValid: false, error: 'AmountTooLow'),
            ),
            200,
          );
        }
        fail('unexpected ${request.method} ${request.url.path}');
      });

      final cubit = PayQuoteCubit(buildPayService(client), _paymentLinkId);
      await cubit.load();

      expect(cubit.state, isA<PayQuoteError>());
      expect(cubit.state, isNot(isA<PayQuoteReady>()));
      expect((cubit.state as PayQuoteError).message, 'AmountTooLow');

      await cubit.close();
    });

    test('process pays the unsigned amountWei (full ZCHF), not the 0.95 quote', () {
      fakeAsync((async) {
        // The sign step uses `Future.delayed(Duration.zero)` (FakeBitboxCredentials),
        // which is a zero-duration *timer* under fakeAsync — `flushMicrotasks` alone
        // does not fire it. Elapsing zero repeatedly drains the whole await chain
        // (each MockClient future + every zero-delay sign timer) until the cubit
        // settles. Then elapse 3s for the Completed status poll.
        void drain() {
          for (var i = 0; i < 40; i++) {
            async.flushMicrotasks();
            async.elapse(Duration.zero);
          }
        }

        Map<String, dynamic>? unsignedPayBody;
        Map<String, dynamic>? submitBody;

        final client = MockClient((request) async {
          final path = request.url.path;
          if (request.method == 'GET' && path == _lnurlpPath) {
            return http.Response(jsonEncode(_lnurlpJson()), 200);
          }
          if (request.method == 'PUT' && path == _swapPath) {
            fail('unexpected ${request.method} ${request.url.path}');
          }
          if (request.method == 'PUT' && path == _swapUnsignedPath) {
            return http.Response(jsonEncode({'swap': '0x02f8aa'}), 200);
          }
          if (request.method == 'PUT' && path == _swapBroadcastPath) {
            return http.Response(jsonEncode({'txHash': '0xswaptx'}), 200);
          }
          if (request.method == 'PUT' && path == _payUnsignedPath) {
            unsignedPayBody = jsonDecode(request.body) as Map<String, dynamic>;
            return http.Response(jsonEncode(_unsignedPayJson()), 200);
          }
          if (request.method == 'PUT' && path == _paySubmitPath) {
            submitBody = jsonDecode(request.body) as Map<String, dynamic>;
            return http.Response(jsonEncode({'txId': '0xpaytx'}), 200);
          }
          if (request.method == 'GET' && path == _payStatusPath) {
            return http.Response(jsonEncode({'status': 'Completed'}), 200);
          }
          fail('unexpected ${request.method} ${request.url.path}');
        });

        // _unsignedPay fixture is chainId 11155111 (Sepolia). PayProcessCubit
        // binds the RLP chainId to apiConfig.asset.chainId; mainnet would fail
        // as unsignedTxMismatch.
        when(
          () => appStore.apiConfig,
        ).thenReturn(const ApiConfig(networkMode: NetworkMode.testnet));
        final payService = buildPayService(client);

        final cubit = PayProcessCubit(
          payService: payService,
          faucetService: faucet,
          blockchainService: blockchain,
          walletService: walletService,
          appStore: appStore,
          paymentLinkId: _paymentLinkId,
          swap: const SwapPaymentInfo(
            id: 99,
            amount: 1,
            estimatedAmount: 1.05,
            targetAsset: 'ZCHF',
            ethBalance: 1,
            requiredGasEth: 0.001,
            isValid: true,
            ethereumTransactionFeeChf: 0.05,
            ethereumTransactionFeeRealu: 0.01234567,
          ),
        );
        cubit.start();
        drain();

        expect(
          cubit.state,
          anyOf(isA<PayProcessAwaitingSettlement>(), isA<PayProcessSuccess>()),
        );

        expect(unsignedPayBody, isNotNull);
        expect(unsignedPayBody!['swapRequestId'], 99);

        expect(submitBody, isNotNull);
        expect(submitBody!['swapRequestId'], 99);
        expect(submitBody!['unsignedTx'], _unsignedPayHex);
        expect(submitBody!['r'], isNotNull);
        expect(submitBody!['s'], isNotNull);
        expect(submitBody!.containsKey('v'), isTrue);

        async.elapse(const Duration(seconds: 3));
        drain();
        expect(
          cubit.state,
          anyOf(isA<PayProcessSuccess>(), isA<PayProcessAwaitingSettlement>()),
        );

        cubit.close();
        async.flushTimers();
      });
    });
  });
}
