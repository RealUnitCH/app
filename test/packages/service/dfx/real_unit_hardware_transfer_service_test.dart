import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mocktail/mocktail.dart';
import 'package:web3dart/web3dart.dart';
import 'package:realunit_wallet/packages/config/api_config.dart';
import 'package:realunit_wallet/packages/config/network_mode.dart';
import 'package:realunit_wallet/packages/repository/cache_repository.dart';
import 'package:realunit_wallet/packages/service/app_store.dart';
import 'package:realunit_wallet/packages/service/dfx/api_client.dart';
import 'package:realunit_wallet/packages/service/dfx/exceptions/api_exception.dart';
import 'package:realunit_wallet/packages/service/dfx/exceptions/payment/buy_exceptions.dart';
import 'package:realunit_wallet/packages/service/dfx/models/payment/sell/dto/broadcast_transaction_request_dto.dart';
import 'package:realunit_wallet/packages/service/dfx/models/payment/transfer/dto/real_unit_hardware_transfer_dto.dart';
import 'package:realunit_wallet/packages/service/dfx/real_unit_hardware_transfer_service.dart';
import 'package:realunit_wallet/packages/service/session_cache.dart';
import 'package:realunit_wallet/packages/service/wallet_service.dart';
import 'package:realunit_wallet/packages/wallet/wallet.dart';
import 'package:realunit_wallet/packages/wallet/wallet_account.dart';

class _MockAppStore extends Mock implements AppStore {}

class _MockWallet extends Mock implements AWallet {}

class _MockAccount extends Mock implements AWalletAccount {}

class _MockCacheRepository extends Mock implements CacheRepository {}

class _MockWalletService extends Mock implements WalletService {}

const _testPrivateKeyHex = 'fb1ace12f9801e85f3db1b3935dd47d9f064f98152466f47c701b5e12680e612';

final _privKey = EthPrivateKey.fromHex(_testPrivateKeyHex);

void main() {
  late _MockAppStore appStore;
  late _MockWallet wallet;
  late _MockAccount account;
  late _MockWalletService walletService;
  late SessionCache session;

  setUp(() {
    appStore = _MockAppStore();
    wallet = _MockWallet();
    account = _MockAccount();
    walletService = _MockWalletService();
    session = SessionCache(_MockCacheRepository());
    session.setAuthToken('jwt-1');

    when(
      () => appStore.apiConfig,
    ).thenReturn(const ApiConfig(networkMode: NetworkMode.mainnet));
    when(() => appStore.sessionCache).thenReturn(session);
    when(() => appStore.wallet).thenReturn(wallet);
    when(() => wallet.currentAccount).thenReturn(account);
    when(() => account.primaryAddress).thenReturn(_privKey);
  });

  RealUnitHardwareTransferService build(http.Client client) {
    when(() => appStore.httpClient).thenReturn(RealUnitApiClient(client));
    return RealUnitHardwareTransferService(appStore, walletService);
  }

  group('prepareTransfer', () {
    test('200 parses unsignedTx and PUTs toAddress + amount', () async {
      Uri? sentUri;
      Map<String, dynamic>? body;
      final client = MockClient((request) async {
        sentUri = request.url;
        body = jsonDecode(request.body) as Map<String, dynamic>;
        return http.Response(
          jsonEncode({
            'unsignedTx': '0x02ab',
            'toAddress': '0xRecipient',
            'amount': 5,
          }),
          200,
        );
      });

      final info = await build(client).prepareTransfer(
        const RealUnitHardwareTransferRequestDto(toAddress: '0xRecipient', amount: 5),
      );

      expect(sentUri!.path, '/v1/realunit/transfer/hardware');
      expect(body, {'toAddress': '0xRecipient', 'amount': 5});
      expect(info.unsignedTx, '0x02ab');
      expect(info.amount, 5);
    });

    test('201 is accepted', () async {
      final client = MockClient(
        (_) async => http.Response(
          jsonEncode({
            'unsignedTx': '0x02ab',
            'toAddress': '0xRecipient',
            'amount': 5,
          }),
          201,
        ),
      );

      final info = await build(client).prepareTransfer(
        const RealUnitHardwareTransferRequestDto(toAddress: '0xRecipient', amount: 5),
      );
      expect(info.amount, 5);
    });

    test('non-2xx → ApiException', () async {
      final client = MockClient(
        (_) async => http.Response(
          jsonEncode({'statusCode': 400, 'code': 'X', 'message': 'nope'}),
          400,
        ),
      );

      expect(
        () => build(client).prepareTransfer(
          const RealUnitHardwareTransferRequestDto(toAddress: '0xRecipient', amount: 5),
        ),
        throwsA(isA<ApiException>()),
      );
    });

    test('INSUFFICIENT_ETH is a typed exception, not a plain message', () async {
      final client = MockClient(
        (_) async => http.Response(
          jsonEncode({
            'statusCode': 400,
            'code': 'INSUFFICIENT_ETH',
            'message': 'Insufficient ETH for gas: need 0.01 ETH, have 0 ETH',
          }),
          400,
        ),
      );

      expect(
        () => build(client).prepareTransfer(
          const RealUnitHardwareTransferRequestDto(toAddress: '0xRecipient', amount: 5),
        ),
        throwsA(
          isA<InsufficientEthForGasException>().having(
            (error) => error.message,
            'message',
            'Insufficient ETH for gas: need 0.01 ETH, have 0 ETH',
          ),
        ),
      );
    });
  });

  group('broadcastTransfer', () {
    test('200 returns txHash', () async {
      Map<String, dynamic>? body;
      final client = MockClient((request) async {
        body = jsonDecode(request.body) as Map<String, dynamic>;
        expect(request.url.path, '/v1/realunit/transfer/hardware/broadcast');
        return http.Response(jsonEncode({'txHash': '0xhash'}), 200);
      });

      final hash = await build(client).broadcastTransfer(
        const BroadcastTransactionRequestDto(
          unsignedTx: '0x02ab',
          r: '0xr',
          s: '0xs',
          v: 1,
        ),
      );

      expect(hash, '0xhash');
      expect(body!['unsignedTx'], '0x02ab');
    });

    test('201 is accepted', () async {
      final client = MockClient(
        (_) async => http.Response(jsonEncode({'txHash': '0xhash'}), 201),
      );
      expect(
        await build(client).broadcastTransfer(
          const BroadcastTransactionRequestDto(
            unsignedTx: '0x02ab',
            r: '0xr',
            s: '0xs',
            v: 1,
          ),
        ),
        '0xhash',
      );
    });

    test('non-2xx → ApiException', () async {
      final client = MockClient(
        (_) async => http.Response(
          jsonEncode({'statusCode': 500, 'code': 'X', 'message': 'fail'}),
          500,
        ),
      );

      expect(
        () => build(client).broadcastTransfer(
          const BroadcastTransactionRequestDto(
            unsignedTx: '0x02ab',
            r: '0xr',
            s: '0xs',
            v: 1,
          ),
        ),
        throwsA(isA<ApiException>()),
      );
    });
  });
}
