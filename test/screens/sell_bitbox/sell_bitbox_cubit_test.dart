import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:realunit_wallet/packages/config/api_config.dart';
import 'package:realunit_wallet/packages/config/network_mode.dart';
import 'package:realunit_wallet/packages/hardware_wallet/fake_bitbox_credentials.dart';
import 'package:realunit_wallet/packages/service/app_store.dart';
import 'package:realunit_wallet/packages/service/dfx/dfx_blockchain_api_service.dart';
import 'package:realunit_wallet/packages/service/dfx/dfx_faucet_service.dart';
import 'package:realunit_wallet/packages/service/dfx/models/payment/sell/dto/broadcast_transaction_request_dto.dart';
import 'package:realunit_wallet/packages/service/dfx/models/payment/sell/dto/eip7702/eip7702_data_dto.dart';
import 'package:realunit_wallet/packages/service/dfx/models/faucet/faucet_response_dto.dart';
import 'package:realunit_wallet/packages/service/dfx/models/payment/sell/dto/real_unit_sell_payment_info_dto.dart';
import 'package:realunit_wallet/packages/service/dfx/models/payment/sell/dto/real_unit_unsigned_transactions_request_dto.dart';
import 'package:realunit_wallet/packages/service/dfx/models/payment/sell/sell_payment_info.dart';
import 'package:realunit_wallet/packages/service/dfx/real_unit_sell_payment_info_service.dart';
import 'package:realunit_wallet/packages/wallet/wallet.dart';
import 'package:realunit_wallet/packages/wallet/wallet_account.dart';
import 'package:realunit_wallet/screens/sell_bitbox/cubit/sell_bitbox_cubit.dart';
import 'package:realunit_wallet/styles/currency.dart';
import 'package:web3dart/web3dart.dart';

class _MockFaucet extends Mock implements DfxFaucetService {}

class _MockBlockchain extends Mock implements DfxBlockchainApiService {}

class _MockSellService extends Mock implements RealUnitSellPaymentInfoService {}

class _MockAppStore extends Mock implements AppStore {}

class _MockWallet extends Mock implements AWallet {}

class _MockWalletAccount extends Mock implements AWalletAccount {}

class _StubSoftwareCreds extends Fake implements CredentialsWithKnownAddress {
  @override
  EthereumAddress get address =>
      EthereumAddress.fromHex('0x9F5713dEAcb8e9CaB6c2D3FaE1aFc2715F8D2D71');
}

SellPaymentInfo _info({
  double ethBalance = 1.0,
  double requiredGasEth = 0.001,
}) =>
    SellPaymentInfo(
      id: 42,
      eip7702: Eip7702Data.fromJson(_eip7702Json()),
      amount: 100,
      exchangeRate: 1.0,
      rate: 1.0,
      beneficiary: const BeneficiaryDto(iban: 'CH...'),
      estimatedAmount: 100.0,
      currency: Currency.chf,
      depositAddress: '0xdeposit',
      tokenAddress: '0xtoken',
      chainId: 1,
      ethBalance: ethBalance,
      requiredGasEth: requiredGasEth,
    );

Map<String, dynamic> _eip7702Json() => {
      'relayerAddress': '0xrelay',
      'delegationManagerAddress': '0xmgr',
      'delegatorAddress': '0xdr',
      'userNonce': 7,
      'domain': {
        'name': 'RealUnit',
        'version': '1',
        'chainId': 1,
        'verifyingContract': '0xverify',
      },
      'types': {
        'Delegation': <Map<String, dynamic>>[],
        'Caveat': <Map<String, dynamic>>[],
      },
      'message': {
        'delegate': '0xd',
        'delegator': '0xdr',
        'authority': '0xauth',
        'caveats': <Map<String, dynamic>>[],
        'salt': 0,
      },
      'tokenAddress': '0xtoken',
      'amountWei': '12345',
      'depositAddress': '0xdeposit',
    };

void main() {
  late _MockFaucet faucet;
  late _MockBlockchain blockchain;
  late _MockSellService sellService;
  late _MockAppStore appStore;
  late _MockWallet wallet;
  late _MockWalletAccount account;

  setUpAll(() {
    registerFallbackValue(
      const BroadcastTransactionRequestDto(unsignedTx: '', r: '', s: '', v: 0),
    );
  });

  setUp(() {
    faucet = _MockFaucet();
    blockchain = _MockBlockchain();
    sellService = _MockSellService();
    appStore = _MockAppStore();
    wallet = _MockWallet();
    account = _MockWalletAccount();

    when(() => appStore.wallet).thenReturn(wallet);
    when(() => appStore.apiConfig)
        .thenReturn(const ApiConfig(networkMode: NetworkMode.mainnet));
    when(() => appStore.primaryAddress).thenReturn('0xwallet');
    when(() => wallet.currentAccount).thenReturn(account);
  });

  SellBitboxCubit build({SellPaymentInfo? info}) => SellBitboxCubit(
        paymentInfo: info ?? _info(),
        faucetService: faucet,
        blockchainService: blockchain,
        sellService: sellService,
        appStore: appStore,
      );

  // Helper: wait until the cubit settles into a non-Checking state. The
  // constructor schedules _checkEthBalance via scheduleMicrotask, so the
  // first emit lands after a microtask.
  Future<SellBitboxState> settle(SellBitboxCubit cubit) async {
    if (cubit.state is! SellBitboxCheckingEth) return cubit.state;
    return cubit.stream.firstWhere((s) => s is! SellBitboxCheckingEth);
  }

  group('constructor / _checkEthBalance', () {
    test('disconnected BitBox → SellBitboxBitboxRequired', () async {
      when(() => account.primaryAddress).thenReturn(
        FakeBitboxCredentials(behavior: FakeBitboxBehavior.disconnect)
          ..bitboxManager = null,
      );

      final cubit = build();
      final state = await settle(cubit);

      expect(state, isA<SellBitboxBitboxRequired>());
      await cubit.close();
    });

    test('ethBalance >= requiredGasEth → SellBitboxEthReady', () async {
      // Use a non-Bitbox credentials so the disconnected check is skipped
      // and the ethBalance branch is exercised directly.
      when(() => account.primaryAddress).thenReturn(_StubSoftwareCreds());

      final cubit = build();
      final state = await settle(cubit);

      expect(state, isA<SellBitboxEthReady>());
      await cubit.close();
    });

    test('ethBalance < required + faucet success → WaitingForEth', () async {
      when(() => account.primaryAddress).thenReturn(_StubSoftwareCreds());
      when(() => faucet.requestFaucet()).thenAnswer(
        (_) async => const FaucetResponseDto(txId: '0xfaucet', amount: 0.01),
      );

      final cubit = build(info: _info(ethBalance: 0, requiredGasEth: 0.001));
      // First non-checking state should be WaitingForEth (RequestingFaucet
      // is fleeting between the two awaits).
      final state = await cubit.stream.firstWhere((s) => s is SellBitboxWaitingForEth);

      expect(state, isA<SellBitboxWaitingForEth>());
      verify(() => faucet.requestFaucet()).called(1);
      await cubit.close();
    });

    test('faucet throws → SellBitboxError', () async {
      when(() => account.primaryAddress).thenReturn(_StubSoftwareCreds());
      when(() => faucet.requestFaucet())
          .thenAnswer((_) async => throw Exception('faucet down'));

      final cubit = build(info: _info(ethBalance: 0, requiredGasEth: 0.001));
      final state = await cubit.stream.firstWhere((s) => s is SellBitboxError);

      expect(state, isA<SellBitboxError>());
      await cubit.close();
    });
  });

  group('proceedToSwap', () {
    test('success: emits Preparing → AwaitingSwapConfirm with both raw txs', () async {
      when(() => account.primaryAddress).thenReturn(_StubSoftwareCreds());
      when(() => sellService.createUnsignedTransactions(any())).thenAnswer(
        (_) async => const RealUnitUnsignedTransactionsRequestDto(
          swap: '0xswap',
          deposit: '0xdeposit',
        ),
      );

      final cubit = build();
      await settle(cubit);
      await cubit.proceedToSwap();

      final state = cubit.state as SellBitboxAwaitingSwapConfirm;
      expect(state.rawSwapTransaction, '0xswap');
      expect(state.rawDepositTransaction, '0xdeposit');
      await cubit.close();
    });

    test('failure: emits Error', () async {
      when(() => account.primaryAddress).thenReturn(_StubSoftwareCreds());
      when(() => sellService.createUnsignedTransactions(any()))
          .thenAnswer((_) async => throw Exception('api 500'));

      final cubit = build();
      await settle(cubit);
      await cubit.proceedToSwap();

      expect(cubit.state, isA<SellBitboxError>());
      await cubit.close();
    });
  });

  group('confirmSwap', () {
    test('no-op outside SellBitboxAwaitingSwapConfirm', () async {
      when(() => account.primaryAddress).thenReturn(_StubSoftwareCreds());

      final cubit = build();
      await settle(cubit);
      final before = cubit.state;
      await cubit.confirmSwap();

      expect(cubit.state, same(before));
      await cubit.close();
    });

    test('non-Bitbox credentials in AwaitingSwapConfirm → Error', () async {
      when(() => account.primaryAddress).thenReturn(_StubSoftwareCreds());
      when(() => sellService.createUnsignedTransactions(any())).thenAnswer(
        (_) async => const RealUnitUnsignedTransactionsRequestDto(
          swap: '0xswap',
          deposit: '0xdeposit',
        ),
      );

      final cubit = build();
      await settle(cubit);
      await cubit.proceedToSwap();
      await cubit.confirmSwap();

      final state = cubit.state as SellBitboxError;
      expect(state.message, contains('BitBox wallet not connected'));
      await cubit.close();
    });
  });

  group('confirmDeposit', () {
    test('no-op outside SellBitboxAwaitingDepositConfirm', () async {
      when(() => account.primaryAddress).thenReturn(_StubSoftwareCreds());

      final cubit = build();
      await settle(cubit);
      final before = cubit.state;
      await cubit.confirmDeposit();

      expect(cubit.state, same(before));
      await cubit.close();
    });
  });

  group('retryDeposit', () {
    test('no-op outside SellBitboxDepositRetry', () async {
      when(() => account.primaryAddress).thenReturn(_StubSoftwareCreds());

      final cubit = build();
      await settle(cubit);
      final before = cubit.state;
      await cubit.retryDeposit();

      expect(cubit.state, same(before));
      await cubit.close();
    });
  });
}
