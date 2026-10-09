import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:web3dart/crypto.dart';
import 'package:realunit_wallet/packages/config/api_config.dart';
import 'package:realunit_wallet/packages/config/network_mode.dart';
import 'package:realunit_wallet/packages/service/app_store.dart';
import 'package:realunit_wallet/packages/service/balance_service.dart';
import 'package:realunit_wallet/packages/service/dfx/dfx_faucet_service.dart';
import 'package:realunit_wallet/packages/service/dfx/exceptions/api_exception.dart';
import 'package:realunit_wallet/packages/service/dfx/exceptions/bitbox_address_unavailable_exception.dart';
import 'package:realunit_wallet/packages/service/dfx/exceptions/bitbox_exception.dart';
import 'package:realunit_wallet/packages/service/dfx/exceptions/payment/buy_exceptions.dart';
import 'package:realunit_wallet/packages/service/dfx/exceptions/payment/transfer_exceptions.dart';
import 'package:realunit_wallet/packages/service/dfx/models/faucet/faucet_response_dto.dart';
import 'package:realunit_wallet/packages/service/dfx/models/payment/sell/dto/broadcast_transaction_request_dto.dart';
import 'package:realunit_wallet/packages/service/dfx/models/payment/transfer/dto/real_unit_hardware_transfer_dto.dart';
import 'package:realunit_wallet/packages/service/dfx/models/payment/transfer/dto/real_unit_transfer_dto.dart';
import 'package:realunit_wallet/packages/service/dfx/models/payment/transfer/dto/real_unit_transfer_payment_info_dto.dart';
import 'package:realunit_wallet/packages/service/dfx/real_unit_hardware_transfer_service.dart';
import 'package:realunit_wallet/packages/service/dfx/real_unit_transfer_service.dart';
import 'package:realunit_wallet/packages/service/wallet_service.dart';
import 'package:realunit_wallet/packages/wallet/wallet.dart';
import 'package:realunit_wallet/packages/wallet/wallet_account.dart';
import 'package:realunit_wallet/screens/hardware_wallet/cubit/move_balance_cubit.dart';
import 'package:realunit_wallet/screens/home/bloc/home_bloc.dart';

import '../../../helper/fake_bitbox_credentials.dart';

class _MockWalletService extends Mock implements WalletService {}

class _MockTransferService extends Mock implements RealUnitTransferService {}

class _MockHardwareTransferService extends Mock implements RealUnitHardwareTransferService {}

class _MockFaucet extends Mock implements DfxFaucetService {}

class _MockAppStore extends Mock implements AppStore {}

class _MockHomeBloc extends Mock implements HomeBloc {}

class _MockBalanceService extends Mock implements BalanceService {}

class _MockBitboxWallet extends Mock implements BitboxWallet {}

class _MockPlainWallet extends Mock implements AWallet {}

class _MockAccount extends Mock implements BitboxWalletAccount {}

class _FakeWallet extends Fake implements AWallet {}

/// Connected at the pre-sign check, then the ceremony itself drops the link.
class _DropsOnSign extends FakeBitboxCredentials {
  _DropsOnSign() : super(address: _bitboxAddr, signDelay: Duration.zero);

  @override
  bool get isConnected => true;

  @override
  Future<MsgSignature> signToSignature(
    Uint8List payload, {
    int? chainId,
    bool isEIP1559 = false,
  }) async {
    if (payload.isEmpty && chainId == null && !isEIP1559) {
      throw const BitboxNotConnectedException();
    }
    throw const BitboxNotConnectedException();
  }
}

const _softwareAddr = '0x0000000000000000000000000000000000000001';
const _bitboxAddr = '0x0000000000000000000000000000000000000002';

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
  'amountWei': '9',
  'recipient': _bitboxAddr,
};

RealUnitTransferPaymentInfoDto _softwareQuote({
  int amount = 9,
  int fee = 1,
}) => RealUnitTransferPaymentInfoDto.fromJson({
  'id': 42,
  'uid': 'RTabc',
  'toAddress': _bitboxAddr,
  'amount': amount,
  'networkFeeRealu': fee,
  'tokenAddress': '0xtoken',
  'chainId': 1,
  'eip7702': _eip7702Json(),
});

void main() {
  late _MockWalletService walletService;
  late _MockTransferService transfer;
  late _MockHardwareTransferService hardware;
  late _MockFaucet faucet;
  late _MockAppStore appStore;
  late _MockHomeBloc homeBloc;
  late _MockBalanceService balanceService;
  late SoftwareViewWallet software;
  late _MockBitboxWallet bitbox;
  late _MockAccount bitboxAccount;
  late FakeBitboxCredentials creds;

  setUpAll(() {
    registerFallbackValue(_FakeWallet());
    registerFallbackValue(const RealUnitTransferDto(toAddress: '0x', amount: 1));
    registerFallbackValue(
      const RealUnitHardwareTransferRequestDto(toAddress: '0x', amount: 1),
    );
    registerFallbackValue(
      const BroadcastTransactionRequestDto(unsignedTx: '', r: '', s: '', v: 0),
    );
    registerFallbackValue(_softwareQuote());
    registerFallbackValue(LoadWalletEvent(SoftwareViewWallet(0, '_', _softwareAddr)));
  });

  setUp(() {
    walletService = _MockWalletService();
    transfer = _MockTransferService();
    hardware = _MockHardwareTransferService();
    faucet = _MockFaucet();
    appStore = _MockAppStore();
    homeBloc = _MockHomeBloc();
    balanceService = _MockBalanceService();
    software = SoftwareViewWallet(1, 'Software', _softwareAddr);
    bitbox = _MockBitboxWallet();
    bitboxAccount = _MockAccount();
    creds = FakeBitboxCredentials(address: _bitboxAddr);

    when(() => bitbox.walletType).thenReturn(WalletType.bitbox);
    when(() => bitbox.id).thenReturn(2);
    when(() => bitbox.currentAccount).thenReturn(bitboxAccount);
    when(() => bitboxAccount.primaryAddress).thenReturn(creds);

    when(() => walletService.listWallets()).thenAnswer((_) async => [software, bitbox]);
    when(() => walletService.switchCurrentWallet(1)).thenAnswer((_) async => software);
    when(() => walletService.switchCurrentWallet(2)).thenAnswer((_) async => bitbox);
    when(() => balanceService.freshShareBalance(_softwareAddr)).thenAnswer((_) async => 10);
    when(() => balanceService.freshShareBalance(_bitboxAddr)).thenAnswer((_) async => 5);
    when(() => appStore.apiConfig).thenReturn(
      const ApiConfig(networkMode: NetworkMode.mainnet),
    );
    when(() => appStore.primaryAddress).thenReturn(_softwareAddr);
    when(() => appStore.wallet).thenReturn(bitbox);
    when(() => homeBloc.add(any())).thenReturn(null);
    when(() => balanceService.updateBalance(any())).thenAnswer((_) async {});
    when(() => balanceService.startSync(any())).thenReturn(null);
  });

  MoveBalanceCubit build() => MoveBalanceCubit(
    walletService: walletService,
    transferService: transfer,
    hardwareTransferService: hardware,
    faucetService: faucet,
    appStore: appStore,
    homeBloc: homeBloc,
    balanceService: balanceService,
  );

  group('load', () {
    test('emits both whole-share balances; missing balance counts as zero', () async {
      when(() => balanceService.freshShareBalance(_bitboxAddr)).thenAnswer((_) async => 0);
      final cubit = build();
      await cubit.load();
      expect(
        cubit.state,
        const MoveBalanceInitial(softwareBalance: 10, bitboxBalance: 0),
      );
      verify(() => balanceService.freshShareBalance(_softwareAddr)).called(1);
      verify(() => balanceService.freshShareBalance(_bitboxAddr)).called(1);
      verifyNever(() => balanceService.updateBalance(any()));
      await cubit.close();
    });

    test('load error becomes a failure', () async {
      when(() => walletService.listWallets()).thenThrow(Exception('db'));
      final cubit = build();
      await cubit.load();
      expect(cubit.state, isA<MoveBalanceFailure>());
      await cubit.close();
    });

    test('fails when a wallet is missing', () async {
      when(() => walletService.listWallets()).thenAnswer((_) async => [software]);
      final cubit = build();
      await cubit.load();
      expect(
        cubit.state,
        const MoveBalanceFailure('', reason: MoveBalanceFailureReason.walletsMissing),
      );
      await cubit.prepareSoftwareToBitbox();
      expect(
        cubit.state,
        const MoveBalanceFailure('', reason: MoveBalanceFailureReason.walletsMissing),
      );
      await cubit.prepareBitboxToSoftware();
      expect(
        cubit.state,
        const MoveBalanceFailure('', reason: MoveBalanceFailureReason.walletsMissing),
      );
      await cubit.close();
    });

    test('confirm without a quote does not send', () async {
      final cubit = build();
      await cubit.load();
      await cubit.confirm();
      expect(cubit.state, isA<MoveBalanceInitial>());
      verifyNever(
        () => transfer.confirmTransfer(
          any(),
          confirmedRecipient: any(named: 'confirmedRecipient'),
          confirmedAmount: any(named: 'confirmedAmount'),
        ),
      );
      await cubit.close();
    });
  });

  group('software to BitBox', () {
    test('zero software balance does not prepare', () async {
      when(() => balanceService.freshShareBalance(_softwareAddr)).thenAnswer((_) async => 0);
      final cubit = build();
      await cubit.load();
      await cubit.prepareSoftwareToBitbox();
      expect(
        cubit.state,
        const MoveBalanceFailure('', reason: MoveBalanceFailureReason.softwareEmpty),
      );
      verifyNever(() => transfer.prepareTransfer(any()));
      await cubit.close();
    });

    test('a thrown freshShareBalance does not call prepareTransfer', () async {
      final cubit = build();
      await cubit.load();
      when(() => balanceService.freshShareBalance(_softwareAddr)).thenThrow(
        Exception('account'),
      );
      await cubit.prepareSoftwareToBitbox();
      verifyNever(() => transfer.prepareTransfer(any()));
      await cubit.close();
    });

    test('prepares the largest amount that still covers networkFeeRealu', () async {
      when(() => transfer.prepareTransfer(any())).thenAnswer((inv) async {
        final dto = inv.positionalArguments.single as RealUnitTransferDto;
        return _softwareQuote(amount: dto.amount, fee: 1);
      });
      final cubit = build();
      await cubit.load();
      await cubit.prepareSoftwareToBitbox();
      final state = cubit.state as MoveBalanceQuoteReady;
      expect(state.direction, MoveBalanceDirection.softwareToBitbox);
      expect(state.amount, 9);
      expect(state.networkFeeRealu, 1);
      expect(state.ethPaysGas, isFalse);
      verify(() => walletService.switchCurrentWallet(1)).called(1);
      final captured = verify(() => transfer.prepareTransfer(captureAny())).captured;
      expect(captured, hasLength(2));
      expect((captured[0] as RealUnitTransferDto).amount, 1);
      expect((captured[1] as RealUnitTransferDto).amount, 9);
      await cubit.close();
    });

    test('one prepare when the software balance is one share', () async {
      when(() => balanceService.freshShareBalance(_softwareAddr)).thenAnswer((_) async => 1);
      when(() => transfer.prepareTransfer(any())).thenAnswer((inv) async {
        final dto = inv.positionalArguments.single as RealUnitTransferDto;
        return _softwareQuote(amount: dto.amount, fee: 0);
      });
      final cubit = build();
      await cubit.load();
      await cubit.prepareSoftwareToBitbox();
      expect((cubit.state as MoveBalanceQuoteReady).amount, 1);
      final captured = verify(() => transfer.prepareTransfer(captureAny())).captured;
      expect(captured, hasLength(1));
      expect((captured.single as RealUnitTransferDto).amount, 1);
      await cubit.close();
    });

    test('fails when the fee consumes the whole balance', () async {
      when(() => balanceService.freshShareBalance(_softwareAddr)).thenAnswer((_) async => 1);
      when(() => transfer.prepareTransfer(any())).thenAnswer(
        (_) async => _softwareQuote(amount: 1, fee: 1),
      );
      final cubit = build();
      await cubit.load();
      await cubit.prepareSoftwareToBitbox();
      expect(
        cubit.state,
        const MoveBalanceFailure('', reason: MoveBalanceFailureReason.feeExceedsBalance),
      );
      verify(() => transfer.prepareTransfer(any())).called(1);
      await cubit.close();
    });

    test('fails when the reduced quote still exceeds the balance', () async {
      when(() => transfer.prepareTransfer(any())).thenAnswer((inv) async {
        final dto = inv.positionalArguments.single as RealUnitTransferDto;
        if (dto.amount == 1) {
          return _softwareQuote(amount: 1, fee: 1);
        }
        return _softwareQuote(amount: dto.amount, fee: 5);
      });
      final cubit = build();
      await cubit.load();
      await cubit.prepareSoftwareToBitbox();
      expect(
        cubit.state,
        const MoveBalanceFailure('', reason: MoveBalanceFailureReason.feeExceedsBalance),
      );
      verify(() => transfer.prepareTransfer(any())).called(2);
      await cubit.close();
    });

    test('probe quote amount other than 1 is quoteMismatch', () async {
      when(() => transfer.prepareTransfer(any())).thenAnswer(
        (_) async => _softwareQuote(amount: 2, fee: 1),
      );
      final cubit = build();
      await cubit.load();
      await cubit.prepareSoftwareToBitbox();
      expect(
        cubit.state,
        const MoveBalanceFailure('', reason: MoveBalanceFailureReason.quoteMismatch),
      );
      verify(() => transfer.prepareTransfer(any())).called(1);
      await cubit.close();
    });

    test('second quote amount other than target is quoteMismatch', () async {
      when(() => transfer.prepareTransfer(any())).thenAnswer((inv) async {
        final dto = inv.positionalArguments.single as RealUnitTransferDto;
        if (dto.amount == 1) {
          return _softwareQuote(amount: 1, fee: 1);
        }
        return _softwareQuote(amount: 8, fee: 1);
      });
      final cubit = build();
      await cubit.load();
      await cubit.prepareSoftwareToBitbox();
      expect(
        cubit.state,
        const MoveBalanceFailure('', reason: MoveBalanceFailureReason.quoteMismatch),
      );
      verify(() => transfer.prepareTransfer(any())).called(2);
      await cubit.close();
    });

    test('RegistrationRequiredException → registration state', () async {
      when(() => transfer.prepareTransfer(any())).thenThrow(
        const RegistrationRequiredException(code: 'R', message: 'register'),
      );
      final cubit = build();
      await cubit.load();
      await cubit.prepareSoftwareToBitbox();
      expect(
        cubit.state,
        const MoveBalanceRegistrationRequired('register'),
      );
      await cubit.close();
    });

    test('API error → failure with the API message', () async {
      when(() => transfer.prepareTransfer(any())).thenThrow(
        const ApiException(code: 'X', message: 'nope'),
      );
      final cubit = build();
      await cubit.load();
      await cubit.prepareSoftwareToBitbox();
      expect(cubit.state, const MoveBalanceFailure('nope'));
      await cubit.close();
    });

    test('confirmTransfer success restarts balance sync', () async {
      when(() => transfer.prepareTransfer(any())).thenAnswer((inv) async {
        final dto = inv.positionalArguments.single as RealUnitTransferDto;
        return _softwareQuote(amount: dto.amount, fee: 0);
      });
      when(
        () => transfer.confirmTransfer(
          any(),
          confirmedRecipient: any(named: 'confirmedRecipient'),
          confirmedAmount: any(named: 'confirmedAmount'),
        ),
      ).thenAnswer((_) async => '0xhash');
      final cubit = build();
      await cubit.load();
      await cubit.prepareSoftwareToBitbox();
      await cubit.confirm();
      expect(cubit.state, const MoveBalanceSuccess(MoveBalanceDirection.softwareToBitbox));
      verify(() => balanceService.freshShareBalance(_softwareAddr)).called(2);
      verify(() => balanceService.freshShareBalance(_bitboxAddr)).called(1);
      verify(() => balanceService.updateBalance(_softwareAddr)).called(1);
      verify(() => balanceService.updateBalance(_bitboxAddr)).called(1);
      verify(() => balanceService.startSync(_softwareAddr)).called(1);
      await cubit.close();
    });

    test('already-confirmed and receipt-timeout are success', () async {
      when(() => transfer.prepareTransfer(any())).thenAnswer((inv) async {
        final dto = inv.positionalArguments.single as RealUnitTransferDto;
        return _softwareQuote(amount: dto.amount, fee: 0);
      });
      when(
        () => transfer.confirmTransfer(
          any(),
          confirmedRecipient: any(named: 'confirmedRecipient'),
          confirmedAmount: any(named: 'confirmedAmount'),
        ),
      ).thenThrow(
        const TransferAlreadyConfirmedException(code: 'C', message: 'already confirmed'),
      );
      final cubit = build();
      await cubit.load();
      await cubit.prepareSoftwareToBitbox();
      await cubit.confirm();
      expect(cubit.state, isA<MoveBalanceSuccess>());
      await cubit.close();
    });

    test('a confirm that was sent is not prepared again with a new amount', () async {
      when(() => transfer.prepareTransfer(any())).thenAnswer((inv) async {
        final dto = inv.positionalArguments.single as RealUnitTransferDto;
        return _softwareQuote(amount: dto.amount, fee: 0);
      });
      when(
        () => transfer.confirmTransfer(
          any(),
          confirmedRecipient: any(named: 'confirmedRecipient'),
          confirmedAmount: any(named: 'confirmedAmount'),
        ),
      ).thenAnswer((_) async => '0xhash');
      final cubit = build();
      await cubit.load();
      await cubit.prepareSoftwareToBitbox();
      await cubit.confirm();
      await cubit.prepareSoftwareToBitbox();
      verify(() => transfer.prepareTransfer(any())).called(2);
      await cubit.close();
    });

    test('confirm API error is retryable and does not prepare a new amount', () async {
      when(() => transfer.prepareTransfer(any())).thenAnswer((inv) async {
        final dto = inv.positionalArguments.single as RealUnitTransferDto;
        return _softwareQuote(amount: dto.amount, fee: 0);
      });
      when(
        () => transfer.confirmTransfer(
          any(),
          confirmedRecipient: any(named: 'confirmedRecipient'),
          confirmedAmount: any(named: 'confirmedAmount'),
        ),
      ).thenThrow(const ApiException(code: 'X', message: 'relay failed'));
      final cubit = build();
      await cubit.load();
      await cubit.prepareSoftwareToBitbox();
      await cubit.confirm();
      expect(
        cubit.state,
        const MoveBalanceFailure(
          'relay failed',
          canRetry: true,
          direction: MoveBalanceDirection.softwareToBitbox,
        ),
      );
      verify(() => walletService.switchCurrentWallet(1)).called(2);
      await cubit.prepareSoftwareToBitbox();
      verify(() => transfer.prepareTransfer(any())).called(2);
      await cubit.confirm();
      verify(
        () => transfer.confirmTransfer(
          any(),
          confirmedRecipient: any(named: 'confirmedRecipient'),
          confirmedAmount: any(named: 'confirmedAmount'),
        ),
      ).called(2);
      await cubit.close();
    });

    test('in-flight confirm is not started twice', () async {
      final gate = Completer<String>();
      when(() => transfer.prepareTransfer(any())).thenAnswer((inv) async {
        final dto = inv.positionalArguments.single as RealUnitTransferDto;
        return _softwareQuote(amount: dto.amount, fee: 0);
      });
      when(
        () => transfer.confirmTransfer(
          any(),
          confirmedRecipient: any(named: 'confirmedRecipient'),
          confirmedAmount: any(named: 'confirmedAmount'),
        ),
      ).thenAnswer((_) => gate.future);
      final cubit = build();
      await cubit.load();
      await cubit.prepareSoftwareToBitbox();
      final first = cubit.confirm();
      final second = cubit.confirm();
      gate.complete('0xhash');
      await Future.wait([first, second]);
      verify(
        () => transfer.confirmTransfer(
          any(),
          confirmedRecipient: any(named: 'confirmedRecipient'),
          confirmedAmount: any(named: 'confirmedAmount'),
        ),
      ).called(1);
      await cubit.close();
    });

    test('a transport error on prepare is the thrown text', () async {
      when(() => transfer.prepareTransfer(any())).thenThrow(Exception('transport'));
      final cubit = build();
      await cubit.load();
      await cubit.prepareSoftwareToBitbox();
      expect(cubit.state, const MoveBalanceFailure('Exception: transport'));
      await cubit.close();
    });

    test('RegistrationRequired on confirm opens registration, not a retry', () async {
      when(() => transfer.prepareTransfer(any())).thenAnswer((inv) async {
        final dto = inv.positionalArguments.single as RealUnitTransferDto;
        return _softwareQuote(amount: dto.amount, fee: 0);
      });
      when(
        () => transfer.confirmTransfer(
          any(),
          confirmedRecipient: any(named: 'confirmedRecipient'),
          confirmedAmount: any(named: 'confirmedAmount'),
        ),
      ).thenThrow(
        const RegistrationRequiredException(code: 'R', message: 'register'),
      );
      final cubit = build();
      await cubit.load();
      await cubit.prepareSoftwareToBitbox();
      await cubit.confirm();
      expect(cubit.state, const MoveBalanceRegistrationRequired('register'));
      await cubit.close();
    });

    test('a transport error on confirm stays retryable on the software wallet', () async {
      when(() => transfer.prepareTransfer(any())).thenAnswer((inv) async {
        final dto = inv.positionalArguments.single as RealUnitTransferDto;
        return _softwareQuote(amount: dto.amount, fee: 0);
      });
      when(
        () => transfer.confirmTransfer(
          any(),
          confirmedRecipient: any(named: 'confirmedRecipient'),
          confirmedAmount: any(named: 'confirmedAmount'),
        ),
      ).thenThrow(Exception('socket'));
      final cubit = build();
      await cubit.load();
      await cubit.prepareSoftwareToBitbox();
      await cubit.confirm();
      expect(
        cubit.state,
        const MoveBalanceFailure(
          'Exception: socket',
          canRetry: true,
          direction: MoveBalanceDirection.softwareToBitbox,
        ),
      );
      await cubit.close();
    });
  });

  group('BitBox to software', () {
    test('prepares the full whole-share balance', () async {
      when(() => hardware.prepareTransfer(any())).thenAnswer(
        (_) async => const RealUnitHardwareTransferPaymentInfoDto(
          unsignedTx: '02aabb',
          toAddress: _softwareAddr,
          amount: 5,
        ),
      );
      final cubit = build();
      await cubit.load();
      await cubit.prepareBitboxToSoftware();
      final state = cubit.state as MoveBalanceQuoteReady;
      expect(state.direction, MoveBalanceDirection.bitboxToSoftware);
      expect(state.amount, 5);
      expect(state.ethPaysGas, isTrue);
      expect(state.networkFeeRealu, 0);
      await cubit.close();
    });

    test('a quote for a different amount is quoteMismatch and is not kept', () async {
      when(() => hardware.prepareTransfer(any())).thenAnswer(
        (_) async => const RealUnitHardwareTransferPaymentInfoDto(
          unsignedTx: '02aabb',
          toAddress: _softwareAddr,
          amount: 4,
        ),
      );
      final cubit = build();
      await cubit.load();
      await cubit.prepareBitboxToSoftware();
      expect(
        cubit.state,
        const MoveBalanceFailure('', reason: MoveBalanceFailureReason.quoteMismatch),
      );
      await cubit.confirm();
      verifyNever(() => hardware.broadcastTransfer(any()));
      await cubit.close();
    });

    test('a quote for a different recipient is quoteMismatch', () async {
      when(() => hardware.prepareTransfer(any())).thenAnswer(
        (_) async => const RealUnitHardwareTransferPaymentInfoDto(
          unsignedTx: '02aabb',
          toAddress: _bitboxAddr,
          amount: 5,
        ),
      );
      final cubit = build();
      await cubit.load();
      await cubit.prepareBitboxToSoftware();
      expect(
        cubit.state,
        const MoveBalanceFailure('', reason: MoveBalanceFailureReason.quoteMismatch),
      );
      await cubit.close();
    });

    test('a checksummed recipient still accepts the quote', () async {
      when(() => hardware.prepareTransfer(any())).thenAnswer(
        (_) async => RealUnitHardwareTransferPaymentInfoDto(
          unsignedTx: '02aabb',
          toAddress: _softwareAddr.toUpperCase(),
          amount: 5,
        ),
      );
      final cubit = build();
      await cubit.load();
      await cubit.prepareBitboxToSoftware();
      expect(cubit.state, isA<MoveBalanceQuoteReady>());
      await cubit.close();
    });

    test('disconnected device → disconnected state', () async {
      creds.behavior = FakeBitboxBehavior.disconnect;
      final cubit = build();
      await cubit.load();
      await cubit.prepareBitboxToSoftware();
      expect(cubit.state, const MoveBalanceDisconnected());
      creds.behavior = FakeBitboxBehavior.success;
      when(() => hardware.prepareTransfer(any())).thenAnswer(
        (_) async => const RealUnitHardwareTransferPaymentInfoDto(
          unsignedTx: '0x02aabb',
          toAddress: _softwareAddr,
          amount: 5,
        ),
      );
      await cubit.retryAfterConnection();
      expect(cubit.state, isA<MoveBalanceQuoteReady>());
      await cubit.close();
    });

    test('faucet failure is a failure state', () async {
      when(() => hardware.prepareTransfer(any())).thenThrow(
        const InsufficientEthForGasException(message: 'Insufficient ETH for gas: 0.01'),
      );
      when(() => faucet.requestFaucet()).thenThrow(
        const ApiException(code: 'F', message: 'faucet down'),
      );
      final cubit = build();
      await cubit.load();
      await cubit.prepareBitboxToSoftware();
      expect(cubit.state, const MoveBalanceFailure('faucet down'));
      await cubit.close();
    });

    test('Insufficient ETH for gas: requests the faucet once', () async {
      when(() => hardware.prepareTransfer(any())).thenThrow(
        const InsufficientEthForGasException(message: 'Insufficient ETH for gas: 0.01'),
      );
      when(() => faucet.requestFaucet()).thenAnswer(
        (_) async => const FaucetResponseDto(txId: '0xfaucet', amount: 0.05),
      );
      final cubit = build();
      await cubit.load();
      await cubit.prepareBitboxToSoftware();
      expect(cubit.state, isA<MoveBalanceNeedEth>());
      await cubit.prepareBitboxToSoftware();
      verify(() => faucet.requestFaucet()).called(1);
      expect(
        cubit.state,
        const MoveBalanceFailure('Insufficient ETH for gas: 0.01'),
      );
      await cubit.confirm();
      verifyNever(
        () => transfer.confirmTransfer(
          any(),
          confirmedRecipient: any(named: 'confirmedRecipient'),
          confirmedAmount: any(named: 'confirmedAmount'),
        ),
      );
      await cubit.close();
    });

    test('a second Insufficient ETH failure does not confirm a software quote', () async {
      when(() => transfer.prepareTransfer(any())).thenAnswer((inv) async {
        final dto = inv.positionalArguments.single as RealUnitTransferDto;
        return _softwareQuote(amount: dto.amount, fee: 0);
      });
      when(() => hardware.prepareTransfer(any())).thenThrow(
        const InsufficientEthForGasException(message: 'Insufficient ETH for gas: 0.01'),
      );
      when(() => faucet.requestFaucet()).thenAnswer(
        (_) async => const FaucetResponseDto(txId: '0xfaucet', amount: 0.05),
      );
      final cubit = build();
      await cubit.load();
      await cubit.prepareSoftwareToBitbox();
      expect(cubit.state, isA<MoveBalanceQuoteReady>());
      await cubit.prepareBitboxToSoftware();
      expect(cubit.state, isA<MoveBalanceNeedEth>());
      await cubit.prepareBitboxToSoftware();
      expect(
        cubit.state,
        const MoveBalanceFailure('Insufficient ETH for gas: 0.01'),
      );
      await cubit.confirm();
      verifyNever(
        () => transfer.confirmTransfer(
          any(),
          confirmedRecipient: any(named: 'confirmedRecipient'),
          confirmedAmount: any(named: 'confirmedAmount'),
        ),
      );
      await cubit.close();
    });

    test('signs with isEIP1559 and broadcasts the API transaction', () async {
      when(() => hardware.prepareTransfer(any())).thenAnswer(
        (_) async => const RealUnitHardwareTransferPaymentInfoDto(
          unsignedTx: '0x02aabb',
          toAddress: _softwareAddr,
          amount: 5,
        ),
      );
      when(() => hardware.broadcastTransfer(any())).thenAnswer((_) async => '0xbb');
      final cubit = build();
      await cubit.load();
      await cubit.prepareBitboxToSoftware();
      await cubit.confirm();
      expect(cubit.state, const MoveBalanceSuccess(MoveBalanceDirection.bitboxToSoftware));
      await cubit.confirm();
      final signed =
          verify(() => hardware.broadcastTransfer(captureAny())).captured.single
              as BroadcastTransactionRequestDto;
      expect(signed.unsignedTx, '0x02aabb');
      expect(creds.signCallCount, 1);
      await cubit.close();
    });

    test('disconnected during confirm emits disconnected; retryAfterConnection confirms', () async {
      when(() => hardware.prepareTransfer(any())).thenAnswer(
        (_) async => const RealUnitHardwareTransferPaymentInfoDto(
          unsignedTx: '0x02aabb',
          toAddress: _softwareAddr,
          amount: 5,
        ),
      );
      when(() => hardware.broadcastTransfer(any())).thenAnswer((_) async => '0xbb');
      final cubit = build();
      await cubit.load();
      await cubit.prepareBitboxToSoftware();
      creds.behavior = FakeBitboxBehavior.disconnect;
      await cubit.confirm();
      expect(cubit.state, const MoveBalanceDisconnected());
      creds.behavior = FakeBitboxBehavior.success;
      await cubit.retryAfterConnection();
      expect(cubit.state, isA<MoveBalanceSuccess>());
      await cubit.close();
    });

    test('BitboxNotConnectedException on prepare → disconnected', () async {
      when(() => hardware.prepareTransfer(any())).thenThrow(
        const BitboxNotConnectedException(),
      );
      final cubit = build();
      await cubit.load();
      await cubit.prepareBitboxToSoftware();
      expect(cubit.state, const MoveBalanceDisconnected());
      await cubit.close();
    });

    test('RegistrationRequiredException on prepare', () async {
      when(() => hardware.prepareTransfer(any())).thenThrow(
        const RegistrationRequiredException(code: 'R', message: 'kyc'),
      );
      final cubit = build();
      await cubit.load();
      await cubit.prepareBitboxToSoftware();
      expect(cubit.state, const MoveBalanceRegistrationRequired('kyc'));
      await cubit.close();
    });

    test('other API error is one failure whose message is the API message', () async {
      when(() => hardware.prepareTransfer(any())).thenThrow(
        const ApiException(code: 'X', message: 'blocked'),
      );
      final cubit = build();
      await cubit.load();
      await cubit.prepareBitboxToSoftware();
      expect(cubit.state, const MoveBalanceFailure('blocked'));
      await cubit.close();
    });

    test('broadcast API error is retryable against the same signed tx', () async {
      when(() => hardware.prepareTransfer(any())).thenAnswer(
        (_) async => const RealUnitHardwareTransferPaymentInfoDto(
          unsignedTx: '0x02aabb',
          toAddress: _softwareAddr,
          amount: 5,
        ),
      );
      when(() => hardware.broadcastTransfer(any())).thenThrow(
        const ApiException(code: 'X', message: 'broadcast failed'),
      );
      final cubit = build();
      await cubit.load();
      await cubit.prepareBitboxToSoftware();
      await cubit.confirm();
      expect(cubit.state, const MoveBalanceFailure('broadcast failed', canRetry: true));
      await cubit.confirm();
      verify(() => hardware.broadcastTransfer(any())).called(2);
      expect(creds.signCallCount, 1);
      await cubit.close();
    });

    test('zero BitBox balance does not prepare', () async {
      when(() => balanceService.freshShareBalance(_bitboxAddr)).thenAnswer((_) async => 0);
      final cubit = build();
      await cubit.load();
      await cubit.prepareBitboxToSoftware();
      expect(
        cubit.state,
        const MoveBalanceFailure('', reason: MoveBalanceFailureReason.bitboxEmpty),
      );
      verifyNever(() => hardware.prepareTransfer(any()));
      await cubit.close();
    });

    test('a thrown freshShareBalance does not call prepareTransfer', () async {
      final cubit = build();
      await cubit.load();
      when(() => balanceService.freshShareBalance(_bitboxAddr)).thenThrow(
        Exception('account'),
      );
      await cubit.prepareBitboxToSoftware();
      verifyNever(() => hardware.prepareTransfer(any()));
      await cubit.close();
    });

    test('zero BitBox balance keeps a prepared software quote confirmable', () async {
      when(() => balanceService.freshShareBalance(_bitboxAddr)).thenAnswer((_) async => 0);
      when(() => transfer.prepareTransfer(any())).thenAnswer((inv) async {
        final dto = inv.positionalArguments.single as RealUnitTransferDto;
        return _softwareQuote(amount: dto.amount, fee: 0);
      });
      when(
        () => transfer.confirmTransfer(
          any(),
          confirmedRecipient: any(named: 'confirmedRecipient'),
          confirmedAmount: any(named: 'confirmedAmount'),
        ),
      ).thenAnswer((_) async => '0xhash');
      final cubit = build();
      await cubit.load();
      await cubit.prepareSoftwareToBitbox();
      expect(cubit.state, isA<MoveBalanceQuoteReady>());
      await cubit.prepareBitboxToSoftware();
      expect(cubit.state, isA<MoveBalanceQuoteReady>());
      verifyNever(() => hardware.prepareTransfer(any()));
      verifyNever(() => walletService.switchCurrentWallet(2));
      await cubit.confirm();
      verify(
        () => transfer.confirmTransfer(
          any(),
          confirmedRecipient: any(named: 'confirmedRecipient'),
          confirmedAmount: any(named: 'confirmedAmount'),
        ),
      ).called(1);
      await cubit.close();
    });

    test('a BitBox that gains a balance after load is prepared once', () async {
      var reads = 0;
      when(() => balanceService.freshShareBalance(_bitboxAddr)).thenAnswer((_) async {
        reads += 1;
        return reads == 1 ? 0 : 4;
      });
      when(() => hardware.prepareTransfer(any())).thenAnswer((invocation) async {
        final dto = invocation.positionalArguments.single as RealUnitHardwareTransferRequestDto;
        return RealUnitHardwareTransferPaymentInfoDto(
          unsignedTx: '0x02aabb',
          toAddress: _softwareAddr,
          amount: dto.amount,
        );
      });
      final cubit = build();
      await cubit.load();
      expect(
        cubit.state,
        const MoveBalanceInitial(softwareBalance: 10, bitboxBalance: 0),
      );
      await cubit.prepareBitboxToSoftware();
      final ready = cubit.state as MoveBalanceQuoteReady;
      expect(ready.direction, MoveBalanceDirection.bitboxToSoftware);
      expect(ready.amount, 4);
      verify(() => hardware.prepareTransfer(any())).called(1);
      await cubit.close();
    });

    test('a later BitBox balance replaces a software quote', () async {
      var reads = 0;
      when(() => balanceService.freshShareBalance(_bitboxAddr)).thenAnswer((_) async {
        reads += 1;
        return reads == 1 ? 0 : 4;
      });
      when(() => transfer.prepareTransfer(any())).thenAnswer((invocation) async {
        final dto = invocation.positionalArguments.single as RealUnitTransferDto;
        return _softwareQuote(amount: dto.amount, fee: 0);
      });
      when(() => hardware.prepareTransfer(any())).thenAnswer((invocation) async {
        final dto = invocation.positionalArguments.single as RealUnitHardwareTransferRequestDto;
        return RealUnitHardwareTransferPaymentInfoDto(
          unsignedTx: '0x02aabb',
          toAddress: _softwareAddr,
          amount: dto.amount,
        );
      });
      final cubit = build();
      await cubit.load();
      await cubit.prepareSoftwareToBitbox();
      expect(
        (cubit.state as MoveBalanceQuoteReady).direction,
        MoveBalanceDirection.softwareToBitbox,
      );
      await cubit.prepareBitboxToSoftware();
      final ready = cubit.state as MoveBalanceQuoteReady;
      expect(ready.direction, MoveBalanceDirection.bitboxToSoftware);
      expect(ready.amount, 4);
      verify(() => hardware.prepareTransfer(any())).called(1);
      verifyNever(
        () => transfer.confirmTransfer(
          any(),
          confirmedRecipient: any(named: 'confirmedRecipient'),
          confirmedAmount: any(named: 'confirmedAmount'),
        ),
      );
      await cubit.close();
    });

    test('a BitBox prepare during a software confirm does not switch wallets', () async {
      final gate = Completer<String>();
      when(() => transfer.prepareTransfer(any())).thenAnswer((inv) async {
        final dto = inv.positionalArguments.single as RealUnitTransferDto;
        return _softwareQuote(amount: dto.amount, fee: 0);
      });
      when(
        () => transfer.confirmTransfer(
          any(),
          confirmedRecipient: any(named: 'confirmedRecipient'),
          confirmedAmount: any(named: 'confirmedAmount'),
        ),
      ).thenAnswer((_) => gate.future);
      final cubit = build();
      await cubit.load();
      await cubit.prepareSoftwareToBitbox();
      final confirming = cubit.confirm();
      await cubit.prepareBitboxToSoftware();
      verifyNever(() => hardware.prepareTransfer(any()));
      verifyNever(() => walletService.switchCurrentWallet(2));
      expect(cubit.state, isA<MoveBalanceConfirming>());
      gate.complete('0xhash');
      await confirming;
      expect(cubit.state, isA<MoveBalanceSuccess>());
      await cubit.close();
    });

    test('a software prepare during a BitBox confirm does not switch wallets', () async {
      final gate = Completer<String>();
      when(() => hardware.prepareTransfer(any())).thenAnswer(
        (_) async => const RealUnitHardwareTransferPaymentInfoDto(
          unsignedTx: '0x02aabb',
          toAddress: _softwareAddr,
          amount: 5,
        ),
      );
      when(() => hardware.broadcastTransfer(any())).thenAnswer((_) => gate.future);
      final cubit = build();
      await cubit.load();
      await cubit.prepareBitboxToSoftware();
      final confirming = cubit.confirm();
      await cubit.prepareSoftwareToBitbox();
      verifyNever(() => transfer.prepareTransfer(any()));
      verifyNever(() => walletService.switchCurrentWallet(1));
      expect(cubit.state, isA<MoveBalanceConfirming>());
      gate.complete('0xbb');
      await confirming;
      expect(cubit.state, isA<MoveBalanceSuccess>());
      await cubit.close();
    });

    test('a BitBox prepare after a failed software confirm keeps that quote', () async {
      when(() => transfer.prepareTransfer(any())).thenAnswer((inv) async {
        final dto = inv.positionalArguments.single as RealUnitTransferDto;
        return _softwareQuote(amount: dto.amount, fee: 0);
      });
      when(
        () => transfer.confirmTransfer(
          any(),
          confirmedRecipient: any(named: 'confirmedRecipient'),
          confirmedAmount: any(named: 'confirmedAmount'),
        ),
      ).thenThrow(const ApiException(code: 'X', message: 'relay failed'));
      final cubit = build();
      await cubit.load();
      await cubit.prepareSoftwareToBitbox();
      await cubit.confirm();
      expect(
        cubit.state,
        const MoveBalanceFailure(
          'relay failed',
          canRetry: true,
          direction: MoveBalanceDirection.softwareToBitbox,
        ),
      );
      await cubit.prepareBitboxToSoftware();
      expect(
        cubit.state,
        const MoveBalanceFailure(
          'relay failed',
          canRetry: true,
          direction: MoveBalanceDirection.softwareToBitbox,
        ),
      );
      verifyNever(() => hardware.prepareTransfer(any()));
      verifyNever(() => walletService.switchCurrentWallet(2));
      await cubit.confirm();
      verify(
        () => transfer.confirmTransfer(
          any(),
          confirmedRecipient: any(named: 'confirmedRecipient'),
          confirmedAmount: any(named: 'confirmedAmount'),
        ),
      ).called(2);
      await cubit.close();
    });

    test('retryPrepareBitboxToSoftware prepares the BitBox quote', () async {
      when(() => hardware.prepareTransfer(any())).thenAnswer(
        (_) async => const RealUnitHardwareTransferPaymentInfoDto(
          unsignedTx: '02aabb',
          toAddress: _softwareAddr,
          amount: 5,
        ),
      );
      final cubit = build();
      await cubit.load();
      await cubit.retryPrepareBitboxToSoftware();
      expect(
        (cubit.state as MoveBalanceQuoteReady).direction,
        MoveBalanceDirection.bitboxToSoftware,
      );
      await cubit.close();
    });

    test('a refresh that finds an empty BitBox does not prepare', () async {
      var reads = 0;
      when(() => balanceService.freshShareBalance(_bitboxAddr)).thenAnswer((_) async {
        reads += 1;
        return reads == 1 ? 5 : 0;
      });
      final cubit = build();
      await cubit.load();
      await cubit.prepareBitboxToSoftware();
      expect(
        cubit.state,
        const MoveBalanceFailure('', reason: MoveBalanceFailureReason.bitboxEmpty),
      );
      verifyNever(() => hardware.prepareTransfer(any()));
      await cubit.close();
    });

    test('a transport error on prepare is the thrown text', () async {
      when(() => hardware.prepareTransfer(any())).thenThrow(Exception('transport'));
      final cubit = build();
      await cubit.load();
      await cubit.prepareBitboxToSoftware();
      expect(cubit.state, const MoveBalanceFailure('Exception: transport'));
      await cubit.close();
    });

    test('a drop during the sign ceremony emits disconnected', () async {
      when(() => hardware.prepareTransfer(any())).thenAnswer(
        (_) async => const RealUnitHardwareTransferPaymentInfoDto(
          unsignedTx: '0x02aabb',
          toAddress: _softwareAddr,
          amount: 5,
        ),
      );
      final cubit = build();
      await cubit.load();
      await cubit.prepareBitboxToSoftware();
      when(() => bitboxAccount.primaryAddress).thenReturn(_DropsOnSign());
      await cubit.confirm();
      expect(cubit.state, const MoveBalanceDisconnected());
      verifyNever(() => hardware.broadcastTransfer(any()));
      await cubit.close();
    });

    test('RegistrationRequired on broadcast opens registration', () async {
      when(() => hardware.prepareTransfer(any())).thenAnswer(
        (_) async => const RealUnitHardwareTransferPaymentInfoDto(
          unsignedTx: '0x02aabb',
          toAddress: _softwareAddr,
          amount: 5,
        ),
      );
      when(() => hardware.broadcastTransfer(any())).thenThrow(
        const RegistrationRequiredException(code: 'R', message: 'kyc'),
      );
      final cubit = build();
      await cubit.load();
      await cubit.prepareBitboxToSoftware();
      await cubit.confirm();
      expect(cubit.state, const MoveBalanceRegistrationRequired('kyc'));
      await cubit.close();
    });

    test('a transport error on broadcast stays retryable', () async {
      when(() => hardware.prepareTransfer(any())).thenAnswer(
        (_) async => const RealUnitHardwareTransferPaymentInfoDto(
          unsignedTx: '0x02aabb',
          toAddress: _softwareAddr,
          amount: 5,
        ),
      );
      when(() => hardware.broadcastTransfer(any())).thenThrow(Exception('socket'));
      final cubit = build();
      await cubit.load();
      await cubit.prepareBitboxToSoftware();
      await cubit.confirm();
      expect(
        cubit.state,
        const MoveBalanceFailure('Exception: socket', canRetry: true),
      );
      await cubit.close();
    });
  });

  group('receipt timeout', () {
    test('software confirm receipt timeout is success', () async {
      when(() => transfer.prepareTransfer(any())).thenAnswer((inv) async {
        final dto = inv.positionalArguments.single as RealUnitTransferDto;
        return _softwareQuote(amount: dto.amount, fee: 0);
      });
      when(
        () => transfer.confirmTransfer(
          any(),
          confirmedRecipient: any(named: 'confirmedRecipient'),
          confirmedAmount: any(named: 'confirmedAmount'),
        ),
      ).thenThrow(
        const TransferReceiptTimeoutException(
          code: 'T',
          message: 'timed out',
          txHash: '0xabc',
        ),
      );
      final cubit = build();
      await cubit.load();
      await cubit.prepareSoftwareToBitbox();
      await cubit.confirm();
      expect(cubit.state, isA<MoveBalanceSuccess>());
      await cubit.close();
    });
  });

  group('reattachBitbox', () {
    test('returns the wallet from existingBitboxWallet when the id matches', () async {
      final paired = _MockBitboxWallet();
      when(() => paired.id).thenReturn(2);
      when(() => walletService.existingBitboxWallet()).thenAnswer((_) async => paired);
      final cubit = build();
      await cubit.load();
      expect(await cubit.reattachBitbox(), same(paired));
      await cubit.close();
    });

    test(
      'throws StateError when existingBitboxWallet throws BitboxAddressMismatchException',
      () async {
        when(() => walletService.existingBitboxWallet()).thenThrow(
          const BitboxAddressMismatchException(),
        );
        final cubit = build();
        await cubit.load();
        await expectLater(cubit.reattachBitbox(), throwsA(isA<StateError>()));
        await cubit.close();
      },
    );

    test('throws StateError when the loaded wallet is not a BitboxWallet', () async {
      final plain = _MockPlainWallet();
      when(() => plain.walletType).thenReturn(WalletType.bitbox);
      when(() => plain.currentAccount).thenReturn(bitboxAccount);
      when(() => walletService.listWallets()).thenAnswer((_) async => [software, plain]);
      final cubit = build();
      await cubit.load();
      expect(cubit.state, const MoveBalanceInitial(softwareBalance: 10, bitboxBalance: 5));
      await expectLater(cubit.reattachBitbox(), throwsA(isA<StateError>()));
      verifyNever(() => walletService.existingBitboxWallet());
      await cubit.close();
    });

    test('throws StateError when existingBitboxWallet returns a different id', () async {
      final other = _MockBitboxWallet();
      when(() => other.id).thenReturn(9);
      when(() => walletService.existingBitboxWallet()).thenAnswer((_) async => other);
      final cubit = build();
      await cubit.load();
      await expectLater(cubit.reattachBitbox(), throwsA(isA<StateError>()));
      await cubit.close();
    });
  });

  group('state equality', () {
    test('empty, quote, success and need-eth compare by value', () {
      expect(const MoveBalanceLoading().props, isEmpty);
      expect(
        const MoveBalanceQuoteReady(
          direction: MoveBalanceDirection.softwareToBitbox,
          amount: 1,
          networkFeeRealu: 1,
          ethPaysGas: false,
          softwareBalance: 2,
          bitboxBalance: 3,
        ).props,
        [
          MoveBalanceDirection.softwareToBitbox,
          1,
          1,
          false,
          2,
          3,
        ],
      );
      expect(
        const MoveBalanceSuccess(MoveBalanceDirection.bitboxToSoftware).props,
        [MoveBalanceDirection.bitboxToSoftware],
      );
      expect(const MoveBalanceNeedEth('need').props, ['need']);
    });
  });
}
