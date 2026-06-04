import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:realunit_wallet/packages/service/app_store.dart';
import 'package:realunit_wallet/packages/service/dfx/exceptions/api_exception.dart';
import 'package:realunit_wallet/packages/service/dfx/exceptions/bitbox_exception.dart';
import 'package:realunit_wallet/packages/service/dfx/exceptions/payment/transfer_exceptions.dart';
import 'package:realunit_wallet/packages/service/dfx/models/payment/transfer/dto/real_unit_transfer_dto.dart';
import 'package:realunit_wallet/packages/service/dfx/models/payment/transfer/dto/real_unit_transfer_payment_info_dto.dart';
import 'package:realunit_wallet/packages/service/dfx/real_unit_transfer_service.dart';
import 'package:realunit_wallet/packages/wallet/exceptions/signing_cancelled_exception.dart';
import 'package:realunit_wallet/packages/wallet/wallet.dart';
import 'package:realunit_wallet/screens/send/cubits/send_process/send_process_cubit.dart';

class _MockTransferService extends Mock implements RealUnitTransferService {}

class _MockAppStore extends Mock implements AppStore {}

class _MockWallet extends Mock implements AWallet {}

RealUnitTransferPaymentInfoDto _info() => RealUnitTransferPaymentInfoDto.fromJson({
  'id': 42,
  'uid': 'RTabc',
  'toAddress': '0xRecipient',
  'amount': 5,
  'tokenAddress': '0xRealu',
  'chainId': 1,
  'eip7702': {
    'relayerAddress': '0xrelay',
    'delegationManagerAddress': '0xmanager',
    'delegatorAddress': '0xdelegator',
    'userNonce': 0,
    'domain': {'name': 'd', 'version': '1', 'chainId': 1, 'verifyingContract': '0xmanager'},
    'types': {
      'Delegation': <Map<String, dynamic>>[],
      'Caveat': <Map<String, dynamic>>[],
    },
    'message': {
      'delegate': '0xrelay',
      'delegator': '0xsender',
      'authority': '0xroot',
      'caveats': <Map<String, dynamic>>[],
      'salt': 0,
    },
    'tokenAddress': '0xRealu',
    'amountWei': '5',
    'recipient': '0xRecipient',
  },
});

void main() {
  late _MockTransferService service;
  late _MockAppStore appStore;
  late _MockWallet wallet;

  setUpAll(() {
    registerFallbackValue(const RealUnitTransferDto(toAddress: '0x', amount: 1));
    registerFallbackValue(_info());
  });

  setUp(() {
    service = _MockTransferService();
    appStore = _MockAppStore();
    wallet = _MockWallet();
    when(() => appStore.wallet).thenReturn(wallet);
    when(() => wallet.walletType).thenReturn(WalletType.software);
  });

  SendProcessCubit build() => SendProcessCubit(
    transferService: service,
    appStore: appStore,
    recipient: '0xRecipient',
    amount: 5,
  );

  void wireHappyPath() {
    when(() => service.prepareTransfer(any())).thenAnswer((_) async => _info());
    when(() => service.confirmTransfer(any())).thenAnswer((_) async => '0xdeadbeef');
  }

  test('debug wallet → signatureUnsupported before any network call', () async {
    when(() => wallet.walletType).thenReturn(WalletType.debug);

    final cubit = build();
    await cubit.start();

    final state = cubit.state as SendProcessFailure;
    expect(state.reason, SendProcessFailureReason.signatureUnsupported);
    verifyNever(() => service.prepareTransfer(any()));
    await cubit.close();
  });

  test('bitbox wallet → signatureUnsupported before any network call', () async {
    when(() => wallet.walletType).thenReturn(WalletType.bitbox);

    final cubit = build();
    await cubit.start();

    final state = cubit.state as SendProcessFailure;
    expect(state.reason, SendProcessFailureReason.signatureUnsupported);
    verifyNever(() => service.prepareTransfer(any()));
    await cubit.close();
  });

  test('happy path: prepare → confirm → success with txHash', () async {
    wireHappyPath();
    RealUnitTransferDto? sentDto;
    when(() => service.prepareTransfer(any())).thenAnswer((invocation) async {
      sentDto = invocation.positionalArguments.first as RealUnitTransferDto;
      return _info();
    });

    final cubit = build();
    await cubit.start();

    expect(sentDto!.toAddress, '0xRecipient');
    expect(sentDto!.amount, 5);
    final state = cubit.state as SendProcessSuccess;
    expect(state.txHash, '0xdeadbeef');
    await cubit.close();
  });

  test('emits Preparing then Signing then Success', () async {
    wireHappyPath();

    final cubit = build();
    final emitted = <SendProcessState>[];
    final sub = cubit.stream.listen(emitted.add);
    await cubit.start();
    // Let the final Success microtask flush before cancelling the subscription.
    await Future<void>.delayed(Duration.zero);
    await sub.cancel();

    expect(emitted.map((s) => s.runtimeType).toList(), [
      SendProcessPreparing,
      SendProcessSigning,
      SendProcessSuccess,
    ]);
    await cubit.close();
  });

  test('service-reported unsupported signature → signatureUnsupported', () async {
    when(() => service.prepareTransfer(any())).thenAnswer((_) async => _info());
    when(
      () => service.confirmTransfer(any()),
    ).thenThrow(const TransferSignatureUnsupportedException());

    final cubit = build();
    await cubit.start();

    expect(
      (cubit.state as SendProcessFailure).reason,
      SendProcessFailureReason.signatureUnsupported,
    );
    await cubit.close();
  });

  test('gas funding unavailable exception → gasFundingUnavailable', () async {
    when(
      () => service.prepareTransfer(any()),
    ).thenThrow(const TransferGasFundingUnavailableException());

    final cubit = build();
    await cubit.start();

    expect(
      (cubit.state as SendProcessFailure).reason,
      SendProcessFailureReason.gasFundingUnavailable,
    );
    await cubit.close();
  });

  test('signing cancelled → signatureCancelled', () async {
    when(() => service.prepareTransfer(any())).thenAnswer((_) async => _info());
    when(() => service.confirmTransfer(any())).thenThrow(const SigningCancelledException());

    final cubit = build();
    await cubit.start();

    expect(
      (cubit.state as SendProcessFailure).reason,
      SendProcessFailureReason.signatureCancelled,
    );
    await cubit.close();
  });

  test('bitbox not connected (defensive) → signatureUnsupported', () async {
    when(() => service.prepareTransfer(any())).thenAnswer((_) async => _info());
    when(() => service.confirmTransfer(any())).thenThrow(const BitboxNotConnectedException());

    final cubit = build();
    await cubit.start();

    expect(
      (cubit.state as SendProcessFailure).reason,
      SendProcessFailureReason.signatureUnsupported,
    );
    await cubit.close();
  });

  test('API 400 (invalid recipient / insufficient REALU) → invalidRequest', () async {
    when(() => service.prepareTransfer(any())).thenThrow(
      const ApiException(statusCode: 400, code: 'X', message: 'Invalid recipient address'),
    );

    final cubit = build();
    await cubit.start();

    final state = cubit.state as SendProcessFailure;
    expect(state.reason, SendProcessFailureReason.invalidRequest);
    expect(state.message, 'Invalid recipient address');
    await cubit.close();
  });

  test('API 404 → invalidRequest', () async {
    when(
      () => service.prepareTransfer(any()),
    ).thenThrow(const ApiException(statusCode: 404, code: 'X', message: 'not found'));

    final cubit = build();
    await cubit.start();

    expect((cubit.state as SendProcessFailure).reason, SendProcessFailureReason.invalidRequest);
    await cubit.close();
  });

  test('API 503 → gasFundingUnavailable', () async {
    when(
      () => service.prepareTransfer(any()),
    ).thenThrow(const ApiException(statusCode: 503, code: 'X', message: 'unavailable'));

    final cubit = build();
    await cubit.start();

    expect(
      (cubit.state as SendProcessFailure).reason,
      SendProcessFailureReason.gasFundingUnavailable,
    );
    await cubit.close();
  });

  test('API 500 → generic', () async {
    when(
      () => service.prepareTransfer(any()),
    ).thenThrow(const ApiException(statusCode: 500, code: 'X', message: 'boom'));

    final cubit = build();
    await cubit.start();

    expect((cubit.state as SendProcessFailure).reason, SendProcessFailureReason.generic);
    await cubit.close();
  });

  test('unexpected error → generic', () async {
    when(() => service.prepareTransfer(any())).thenThrow(Exception('weird'));

    final cubit = build();
    await cubit.start();

    expect((cubit.state as SendProcessFailure).reason, SendProcessFailureReason.generic);
    await cubit.close();
  });
}
