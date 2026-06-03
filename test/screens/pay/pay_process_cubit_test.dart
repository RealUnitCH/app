import 'dart:typed_data';

import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:realunit_wallet/packages/config/api_config.dart';
import 'package:realunit_wallet/packages/config/network_mode.dart';
import 'package:realunit_wallet/packages/service/app_store.dart';
import 'package:realunit_wallet/packages/service/dfx/dfx_blockchain_api_service.dart';
import 'package:realunit_wallet/packages/service/dfx/dfx_faucet_service.dart';
import 'package:realunit_wallet/packages/service/dfx/exceptions/bitbox_exception.dart';
import 'package:realunit_wallet/packages/service/dfx/models/faucet/faucet_response_dto.dart';
import 'package:realunit_wallet/packages/service/dfx/models/payment/pay/dto/lnurlp_payment_dto.dart';
import 'package:realunit_wallet/packages/service/dfx/models/payment/pay/dto/real_unit_ocp_pay_dto.dart';
import 'package:realunit_wallet/packages/service/dfx/models/payment/pay/dto/real_unit_ocp_pay_status_dto.dart';
import 'package:realunit_wallet/packages/service/dfx/models/payment/pay/dto/real_unit_ocp_pay_submit_dto.dart';
import 'package:realunit_wallet/packages/service/dfx/models/payment/pay/dto/real_unit_ocp_pay_unsigned_transaction_dto.dart';
import 'package:realunit_wallet/packages/service/dfx/models/payment/pay/dto/real_unit_swap_dto.dart';
import 'package:realunit_wallet/packages/service/dfx/models/payment/pay/dto/real_unit_swap_payment_info_dto.dart';
import 'package:realunit_wallet/packages/service/dfx/models/payment/pay/dto/real_unit_swap_unsigned_transaction_dto.dart';
import 'package:realunit_wallet/packages/service/dfx/models/payment/pay/swap_payment_info.dart';
import 'package:realunit_wallet/packages/service/dfx/models/payment/sell/dto/broadcast_transaction_request_dto.dart';
import 'package:realunit_wallet/packages/service/dfx/real_unit_pay_service.dart';
import 'package:realunit_wallet/packages/service/wallet_service.dart';
import 'package:realunit_wallet/packages/wallet/wallet.dart';
import 'package:realunit_wallet/packages/wallet/wallet_account.dart';
import 'package:realunit_wallet/screens/pay/cubits/pay_process/pay_process_cubit.dart';
import 'package:web3dart/crypto.dart';
import 'package:web3dart/web3dart.dart';

import '../../helper/fake_bitbox_credentials.dart';

class _MockPayService extends Mock implements RealUnitPayService {}

class _MockFaucet extends Mock implements DfxFaucetService {}

class _MockBlockchain extends Mock implements DfxBlockchainApiService {}

class _MockWalletService extends Mock implements WalletService {}

class _MockAppStore extends Mock implements AppStore {}

class _MockWallet extends Mock implements AWallet {}

class _MockAccount extends Mock implements AWalletAccount {}

/// Credentials whose `signToSignature` throws [UnsupportedError] — the debug
/// wallet's behaviour, used to exercise the in-sign defensive guard.
class _UnsupportedCreds extends Fake implements CredentialsWithKnownAddress {
  @override
  Future<MsgSignature> signToSignature(Uint8List payload, {int? chainId, bool isEIP1559 = false}) =>
      throw UnsupportedError('Debug wallet cannot sign');
}

SwapPaymentInfo _swap({
  double ethBalance = 1.0,
  double requiredGasEth = 0.001,
  bool isValid = true,
}) {
  return SwapPaymentInfo.fromDto(
    RealUnitSwapPaymentInfoDto(
      id: 99,
      uid: 'u',
      routeId: 7,
      timestamp: DateTime.parse('2026-06-03T00:00:00.000Z'),
      amount: 10,
      estimatedAmount: 960,
      targetAsset: 'ZCHF',
      minVolume: 1,
      maxVolume: 1000,
      minVolumeTarget: 95,
      maxVolumeTarget: 95000,
      ethBalance: ethBalance,
      requiredGasEth: requiredGasEth,
      isValid: isValid,
    ),
  );
}

LnurlpPaymentDto _details({
  required DateTime expiration,
  String quoteId = 'quote_fresh',
  double zchf = 42.7,
}) {
  return LnurlpPaymentDto(
    requestedAmount: const LnurlpRequestedAmountDto(asset: 'CHF', amount: 42.5),
    quote: LnurlpQuoteDto(id: quoteId, expiration: expiration),
    transferAmounts: [
      LnurlpTransferAmountDto(
        method: 'Ethereum',
        assets: [LnurlpTransferAssetDto(asset: 'ZCHF', amount: zchf)],
      ),
    ],
  );
}

const _unsignedPay = RealUnitOcpPayUnsignedTransactionDto(
  // A short EIP-1559-style payload; signToSignature only keccak-hashes it.
  unsignedTx: '0x02f8',
  tokenAddress: '0xzchf',
  recipient: '0xrecipient',
  amountWei: '5000000000000000000',
  chainId: 11155111,
);

void main() {
  late _MockPayService payService;
  late _MockFaucet faucet;
  late _MockBlockchain blockchain;
  late _MockWalletService walletService;
  late _MockAppStore appStore;
  late _MockWallet wallet;
  late _MockAccount account;

  setUpAll(() {
    registerFallbackValue(const RealUnitSwapDto.fromTargetAmount(1));
    registerFallbackValue(const RealUnitOcpPayDto(paymentLinkId: 'pl_abc', quoteId: 'q'));
    registerFallbackValue(
      const BroadcastTransactionRequestDto(unsignedTx: '', r: '', s: '', v: 0),
    );
    registerFallbackValue(
      const RealUnitOcpPaySubmitDto(
        unsignedTx: '',
        r: '',
        s: '',
        v: 0,
        paymentLinkId: 'pl_abc',
        quoteId: 'q',
      ),
    );
  });

  setUp(() {
    payService = _MockPayService();
    faucet = _MockFaucet();
    blockchain = _MockBlockchain();
    walletService = _MockWalletService();
    appStore = _MockAppStore();
    wallet = _MockWallet();
    account = _MockAccount();

    when(() => appStore.apiConfig).thenReturn(const ApiConfig(networkMode: NetworkMode.mainnet));
    when(() => appStore.primaryAddress).thenReturn('0xwallet');
    // Default: the environment can settle OCP (mainnet). The up-front gate in
    // start() reads this before any on-chain action.
    when(() => payService.isPaySupportedEnvironment).thenReturn(true);
    when(() => appStore.wallet).thenReturn(wallet);
    when(() => wallet.walletType).thenReturn(WalletType.software);
    when(() => wallet.currentAccount).thenReturn(account);
    when(() => account.primaryAddress).thenReturn(FakeBitboxCredentials(signDelay: Duration.zero));
    when(() => walletService.ensureCurrentWalletUnlocked()).thenAnswer((_) async {});
    when(() => walletService.lockCurrentWallet()).thenAnswer((_) async {});
  });

  PayProcessCubit build({double zchfNeeded = 42.7}) => PayProcessCubit(
    payService: payService,
    faucetService: faucet,
    blockchainService: blockchain,
    walletService: walletService,
    appStore: appStore,
    paymentLinkId: 'pl_abc',
    zchfNeeded: zchfNeeded,
  );

  void wireHappyPath() {
    when(() => payService.getSwapPaymentInfo(any())).thenAnswer((_) async => _swap());
    when(() => payService.createSwapUnsignedTransaction(any())).thenAnswer(
      (_) async => const RealUnitSwapUnsignedTransactionDto(swap: '0x02f8aa'),
    );
    when(
      () => payService.broadcastSwapTransaction(any(), any()),
    ).thenAnswer((_) async => '0xswaptx');
    when(() => payService.getPaymentDetails('pl_abc')).thenAnswer(
      (_) async => _details(expiration: DateTime.now().add(const Duration(minutes: 5))),
    );
    when(
      () => payService.createPayUnsignedTransaction(any()),
    ).thenAnswer((_) async => _unsignedPay);
    when(() => payService.submitPay(any())).thenAnswer((_) async => '0xpaytx');
  }

  // The sign step uses `Future.delayed(Duration.zero)` (FakeBitboxCredentials),
  // which is a zero-duration *timer* under fakeAsync — `flushMicrotasks` alone
  // does not fire it. Elapsing zero repeatedly drains the whole await chain
  // (each mock `thenAnswer` future + every zero-delay sign timer) until the
  // cubit settles.
  void drain(FakeAsync async) {
    for (var i = 0; i < 40; i++) {
      async.flushMicrotasks();
      async.elapse(Duration.zero);
    }
  }

  test('debug wallet → signatureUnsupported before any network call', () async {
    when(() => wallet.walletType).thenReturn(WalletType.debug);

    final cubit = build();
    await cubit.start();

    final state = cubit.state as PayProcessFailure;
    expect(state.reason, PayProcessFailureReason.signatureUnsupported);
    verifyNever(() => payService.getSwapPaymentInfo(any()));
    await cubit.close();
  });

  test('invalid swap quote → insufficientZchf', () async {
    when(() => payService.getSwapPaymentInfo(any())).thenAnswer((_) async => _swap(isValid: false));

    final cubit = build();
    await cubit.start();

    final state = cubit.state as PayProcessFailure;
    expect(state.reason, PayProcessFailureReason.insufficientZchf);
    await cubit.close();
  });

  test('swap sizes the target with a slippage buffer over the ZCHF needed', () async {
    wireHappyPath();
    when(() => payService.getPayStatus('pl_abc')).thenAnswer(
      (_) async => const RealUnitOcpPayStatusDto(status: OcpPaymentStatus.completed),
    );
    RealUnitSwapDto? sentDto;
    when(() => payService.getSwapPaymentInfo(any())).thenAnswer((invocation) async {
      sentDto = invocation.positionalArguments.first as RealUnitSwapDto;
      return _swap();
    });

    final cubit = build(zchfNeeded: 100);
    await cubit.start();

    // After start() resolves the chain the pay tx has been submitted.
    expect(cubit.state, isA<PayProcessAwaitingSettlement>());
    // 100 * 1.03 swap headroom buffer (covers ordinary CHF→ZCHF / swap-rate
    // drift between scan and settle).
    expect(sentDto!.targetAmount, closeTo(103, 0.0001));
    expect(sentDto!.amount, isNull);
    await cubit.close();
  });

  test('happy path: swap → refresh quote → pay → polled Completed → success', () async {
    fakeAsync((async) {
      wireHappyPath();
      when(() => payService.getPayStatus('pl_abc')).thenAnswer(
        (_) async => const RealUnitOcpPayStatusDto(status: OcpPaymentStatus.completed),
      );

      final cubit = build();
      cubit.start();
      drain(async);

      // Pay submitted → polling status.
      expect(cubit.state, isA<PayProcessAwaitingSettlement>());

      // First status poll @ 3s returns Completed → success.
      async.elapse(const Duration(seconds: 3));
      drain(async);
      expect(cubit.state, isA<PayProcessSuccess>());

      cubit.close();
      async.flushTimers();
    });
  });

  test('re-fetched quote sends a fresh quoteId into the pay step', () async {
    wireHappyPath();
    when(() => payService.getPaymentDetails('pl_abc')).thenAnswer(
      (_) async =>
          _details(expiration: DateTime.now().add(const Duration(minutes: 5)), quoteId: 'q_fresh2'),
    );
    RealUnitOcpPayDto? payDto;
    when(() => payService.createPayUnsignedTransaction(any())).thenAnswer((invocation) async {
      payDto = invocation.positionalArguments.first as RealUnitOcpPayDto;
      return _unsignedPay;
    });

    final cubit = build();
    final settled = cubit.stream.firstWhere((s) => s is PayProcessAwaitingSettlement);
    await cubit.start();
    await settled;

    expect(payDto!.quoteId, 'q_fresh2');
    await cubit.close();
  });

  test('quote expired between swap and pay → pay-only retry (no re-scan)', () async {
    wireHappyPath();
    when(() => payService.getPaymentDetails('pl_abc')).thenAnswer(
      (_) async => _details(expiration: DateTime.now().subtract(const Duration(minutes: 1))),
    );

    final cubit = build();
    final retry = cubit.stream.firstWhere((s) => s is PayProcessPayRetry);
    await cubit.start();
    final state = await retry as PayProcessPayRetry;

    // Genuine expiry surfaces as a retryable state — NOT a terminal failure —
    // because the swap already ran. The pay leg is never submitted here.
    expect(state.reason, PayRetryReason.quoteExpired);
    verifyNever(() => payService.createPayUnsignedTransaction(any()));
    await cubit.close();
  });

  test('pay submit failure after swap → retry (transient), not terminal', () async {
    wireHappyPath();
    when(() => payService.submitPay(any())).thenThrow(Exception('settlement rejected'));

    final cubit = build();
    final retry = cubit.stream.firstWhere((s) => s is PayProcessPayRetry);
    await cubit.start();
    final state = await retry as PayProcessPayRetry;

    // The swap is done; a failed pay must NOT force a re-swap.
    expect(state.reason, PayRetryReason.transient);
    expect(cubit.state, isNot(isA<PayProcessFailure>()));
    await cubit.close();
  });

  test('terminal non-completed status (Cancelled) → pay-only retry', () async {
    fakeAsync((async) {
      wireHappyPath();
      when(() => payService.getPayStatus('pl_abc')).thenAnswer(
        (_) async => const RealUnitOcpPayStatusDto(status: OcpPaymentStatus.cancelled),
      );

      final cubit = build();
      cubit.start();
      drain(async);
      expect(cubit.state, isA<PayProcessAwaitingSettlement>());

      async.elapse(const Duration(seconds: 3));
      drain(async);
      // A cancelled settlement after the swap leaves the user holding ZCHF — it
      // is recoverable by retrying the pay leg, not a terminal failure.
      final state = cubit.state as PayProcessPayRetry;
      expect(state.reason, PayRetryReason.transient);

      cubit.close();
      async.flushTimers();
    });
  });

  test('status polling ignores a transient error then settles', () async {
    fakeAsync((async) {
      wireHappyPath();
      var call = 0;
      when(() => payService.getPayStatus('pl_abc')).thenAnswer((_) async {
        call++;
        if (call == 1) throw Exception('rpc 503');
        return const RealUnitOcpPayStatusDto(status: OcpPaymentStatus.completed);
      });

      final cubit = build();
      cubit.start();
      drain(async);

      // 1st poll throws → still awaiting.
      async.elapse(const Duration(seconds: 3));
      drain(async);
      expect(cubit.state, isA<PayProcessAwaitingSettlement>());

      // 2nd poll completes → success.
      async.elapse(const Duration(seconds: 3));
      drain(async);
      expect(cubit.state, isA<PayProcessSuccess>());

      cubit.close();
      async.flushTimers();
    });
  });

  test('low ETH balance → faucet → eth polling crosses threshold → swap proceeds', () async {
    fakeAsync((async) {
      wireHappyPath();
      when(
        () => payService.getSwapPaymentInfo(any()),
      ).thenAnswer((_) async => _swap(ethBalance: 0, requiredGasEth: 0.001));
      when(
        () => faucet.requestFaucet(),
      ).thenAnswer((_) async => const FaucetResponseDto(txId: '0xf', amount: 0.01));
      var balanceCall = 0;
      when(() => blockchain.getEthBalance(any())).thenAnswer((_) async {
        balanceCall++;
        return balanceCall == 1 ? 0.0 : 0.01;
      });
      when(() => payService.getPayStatus('pl_abc')).thenAnswer(
        (_) async => const RealUnitOcpPayStatusDto(status: OcpPaymentStatus.completed),
      );

      final cubit = build();
      cubit.start();
      drain(async);
      expect(cubit.state, isA<PayProcessWaitingForEth>());

      // 1st eth poll @ 5s — still 0.
      async.elapse(const Duration(seconds: 5));
      drain(async);
      expect(cubit.state, isA<PayProcessWaitingForEth>());

      // 2nd eth poll @ 10s — funded → swap runs through to settlement polling.
      async.elapse(const Duration(seconds: 5));
      drain(async);
      expect(cubit.state, isA<PayProcessAwaitingSettlement>());

      // status poll completes the flow.
      async.elapse(const Duration(seconds: 3));
      drain(async);
      expect(cubit.state, isA<PayProcessSuccess>());

      cubit.close();
      async.flushTimers();
    });
  });

  test('faucet request failure → insufficientEth', () async {
    when(
      () => payService.getSwapPaymentInfo(any()),
    ).thenAnswer((_) async => _swap(ethBalance: 0, requiredGasEth: 0.001));
    when(() => faucet.requestFaucet()).thenThrow(Exception('faucet down'));

    final cubit = build();
    final failed = cubit.stream.firstWhere((s) => s is PayProcessFailure);
    await cubit.start();
    final state = await failed as PayProcessFailure;

    expect(state.reason, PayProcessFailureReason.insufficientEth);
    await cubit.close();
  });

  test('UnsupportedError while signing → signatureUnsupported', () async {
    wireHappyPath();
    // Wallet reports software type (passes the start() gate) but the credentials
    // throw UnsupportedError on sign — exercises the in-sign defensive guard.
    when(() => account.primaryAddress).thenReturn(_UnsupportedCreds());

    final cubit = build();
    final failed = cubit.stream.firstWhere((s) => s is PayProcessFailure);
    await cubit.start();
    final state = await failed as PayProcessFailure;

    expect(state.reason, PayProcessFailureReason.signatureUnsupported);
    await cubit.close();
  });

  test('swap quote fetch failure → generic', () async {
    when(() => payService.getSwapPaymentInfo(any())).thenThrow(Exception('api 500'));

    final cubit = build();
    final failed = cubit.stream.firstWhere((s) => s is PayProcessFailure);
    await cubit.start();
    final state = await failed as PayProcessFailure;

    expect(state.reason, PayProcessFailureReason.generic);
    await cubit.close();
  });

  test('BitBox disconnect during the swap sign → bitboxRequired', () async {
    wireHappyPath();
    when(() => account.primaryAddress).thenReturn(
      FakeBitboxCredentials(behavior: FakeBitboxBehavior.disconnect, signDelay: Duration.zero),
    );

    final cubit = build();
    final failed = cubit.stream.firstWhere((s) => s is PayProcessFailure);
    await cubit.start();
    final state = await failed as PayProcessFailure;

    expect(state.reason, PayProcessFailureReason.bitboxRequired);
    await cubit.close();
  });

  test('generic sign failure during the swap → generic', () async {
    wireHappyPath();
    when(() => account.primaryAddress).thenReturn(
      FakeBitboxCredentials(behavior: FakeBitboxBehavior.malformed, signDelay: Duration.zero),
    );

    final cubit = build();
    final failed = cubit.stream.firstWhere((s) => s is PayProcessFailure);
    await cubit.start();
    final state = await failed as PayProcessFailure;

    expect(state.reason, PayProcessFailureReason.generic);
    await cubit.close();
  });

  test('transient quote re-fetch failure after swap → retry (not re-scan)', () async {
    wireHappyPath();
    when(() => payService.getPaymentDetails('pl_abc')).thenThrow(Exception('lnurlp 500'));

    final cubit = build();
    final retry = cubit.stream.firstWhere((s) => s is PayProcessPayRetry);
    await cubit.start();
    final state = await retry as PayProcessPayRetry;

    // A transient fetch error is NOT a genuine expiry — it routes to the
    // pay-only retry, never to a re-scan → re-swap.
    expect(state.reason, PayRetryReason.transient);
    await cubit.close();
  });

  test('unsupported environment → fails BEFORE any swap (no on-chain action)', () async {
    wireHappyPath();
    when(() => payService.isPaySupportedEnvironment).thenReturn(false);

    final cubit = build();
    await cubit.start();

    final state = cubit.state as PayProcessFailure;
    expect(state.reason, PayProcessFailureReason.payUnsupportedEnvironment);
    // The irreversible swap must never run on an unsupported environment.
    verifyNever(() => payService.getSwapPaymentInfo(any()));
    verifyNever(() => payService.createSwapUnsignedTransaction(any()));
    verifyNever(() => payService.broadcastSwapTransaction(any(), any()));
    await cubit.close();
  });

  test('BitBox disconnect during the pay sign (after swap) → pay-only retry', () async {
    wireHappyPath();
    // First sign (swap) succeeds; the second sign (pay) reports a dropped BLE
    // link. Because the swap already happened, this is a retryable pay-leg
    // failure rather than a terminal one.
    final creds = _CountingSignCreds(
      throwOnCall: 2,
      error: const BitboxNotConnectedException(),
    );
    when(() => account.primaryAddress).thenReturn(creds);

    final cubit = build();
    final retry = cubit.stream.firstWhere((s) => s is PayProcessPayRetry);
    await cubit.start();
    final state = await retry as PayProcessPayRetry;

    expect(creds.calls, 2);
    expect(state.reason, PayRetryReason.transient);
    await cubit.close();
  });

  test('insufficient ZCHF after swap (fresh amount > acquired) → typed retry', () async {
    wireHappyPath();
    // Swap acquires estimatedAmount=960 ZCHF, but the fresh quote now demands
    // 1000 ZCHF — more than was swapped. Surface the typed, retryable state.
    when(() => payService.getPaymentDetails('pl_abc')).thenAnswer(
      (_) async => _details(
        expiration: DateTime.now().add(const Duration(minutes: 5)),
        zchf: 1000,
      ),
    );

    final cubit = build();
    final retry = cubit.stream.firstWhere((s) => s is PayProcessPayRetry);
    await cubit.start();
    final state = await retry as PayProcessPayRetry;

    expect(state.reason, PayRetryReason.insufficientZchf);
    // The pay leg is never attempted — the swapped ZCHF stays in the wallet.
    verifyNever(() => payService.createPayUnsignedTransaction(any()));
    await cubit.close();
  });

  test('retryPay re-runs the pay leg only — never re-swaps', () async {
    wireHappyPath();
    // First pass: quote re-fetch throws → PayProcessPayRetry.
    var detailsCall = 0;
    when(() => payService.getPaymentDetails('pl_abc')).thenAnswer((_) async {
      detailsCall++;
      if (detailsCall == 1) throw Exception('lnurlp 500');
      return _details(expiration: DateTime.now().add(const Duration(minutes: 5)));
    });
    when(() => payService.getPayStatus('pl_abc')).thenAnswer(
      (_) async => const RealUnitOcpPayStatusDto(status: OcpPaymentStatus.completed),
    );

    final cubit = build();
    final retry = cubit.stream.firstWhere((s) => s is PayProcessPayRetry);
    await cubit.start();
    await retry;
    expect(cubit.state, isA<PayProcessPayRetry>());

    // Retry the pay leg: it must re-fetch the quote + submit WITHOUT re-swapping.
    final settled = cubit.stream.firstWhere((s) => s is PayProcessAwaitingSettlement);
    await cubit.retryPay();
    await settled;

    expect(cubit.state, isA<PayProcessAwaitingSettlement>());
    // The swap legs ran EXACTLY ONCE over the whole flow — the retry reused the
    // already-acquired ZCHF and never re-swapped (the key fund-safety guarantee).
    verify(() => payService.createSwapUnsignedTransaction(any())).called(1);
    verify(() => payService.broadcastSwapTransaction(any(), any())).called(1);
    // The pay leg's submit ran once (only on the successful retry).
    verify(() => payService.submitPay(any())).called(1);
    await cubit.close();
  });

  test('retryPay is a no-op before a swap has completed', () async {
    wireHappyPath();

    final cubit = build();
    // Never started → swap not completed → retry must not touch the network.
    await cubit.retryPay();

    verifyNever(() => payService.getPaymentDetails(any()));
    await cubit.close();
  });

  test('non-signing wallet detected only at the pay sign (after swap) → retry', () async {
    wireHappyPath();
    // Swap sign succeeds; the pay sign hits a non-signing credential
    // (UnsupportedError). Post-swap, this is a retryable pay-leg failure.
    final creds = _CountingSignCreds(
      throwOnCall: 2,
      error: UnsupportedError('cannot sign'),
    );
    when(() => account.primaryAddress).thenReturn(creds);

    final cubit = build();
    final retry = cubit.stream.firstWhere((s) => s is PayProcessPayRetry);
    await cubit.start();
    final state = await retry as PayProcessPayRetry;

    expect(creds.calls, 2);
    expect(state.reason, PayRetryReason.transient);
    await cubit.close();
  });
}

/// Credentials that produce a real signature for every sign except the
/// [throwOnCall]-th, which throws [error]. Lets a test target the swap (call 1)
/// vs. the pay (call 2) sign deterministically.
class _CountingSignCreds extends Fake implements CredentialsWithKnownAddress {
  _CountingSignCreds({required this.throwOnCall, required this.error});

  final int throwOnCall;
  final Object error;
  int calls = 0;

  @override
  EthereumAddress get address =>
      EthereumAddress.fromHex('0x9F5713dEAcb8e9CaB6c2D3FaE1aFc2715F8D2D71');

  @override
  Future<MsgSignature> signToSignature(
    Uint8List payload, {
    int? chainId,
    bool isEIP1559 = false,
  }) async {
    calls++;
    if (calls == throwOnCall) throw error;
    return EthPrivateKey.fromHex(
      'fb1ace12f9801e85f3db1b3935dd47d9f064f98152466f47c701b5e12680e612',
    ).signToSignature(payload, chainId: chainId, isEIP1559: isEIP1559);
  }
}
