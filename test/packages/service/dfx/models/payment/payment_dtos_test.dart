import 'package:flutter_test/flutter_test.dart';
import 'package:realunit_wallet/packages/service/dfx/models/payment/price_step_dto.dart';
import 'package:realunit_wallet/packages/service/dfx/models/payment/sell/dto/broadcast_transaction_request_dto.dart';
import 'package:realunit_wallet/packages/service/dfx/models/payment/sell/dto/broadcast_transaction_response_dto.dart';
import 'package:realunit_wallet/packages/service/dfx/models/payment/sell/dto/eip7702/eip7702_confirm_dto.dart';
import 'package:realunit_wallet/packages/service/dfx/models/payment/sell/dto/real_unit_sell_confirm_dto.dart';
import 'package:realunit_wallet/packages/service/dfx/models/payment/sell/dto/real_unit_unsigned_transactions_request_dto.dart';

void main() {
  group('$PriceStep.fromJson', () {
    test('parses the wire shape and converts price to double', () {
      final step = PriceStep.fromJson({
        'source': 'Kraken',
        'from': 'CHF',
        'to': 'USDT',
        'price': 1.12,
        'timestamp': '2026-05-15T10:00:00Z',
      });

      expect(step.source, 'Kraken');
      expect(step.from, 'CHF');
      expect(step.to, 'USDT');
      expect(step.price, 1.12);
      expect(step.timestamp, DateTime.utc(2026, 5, 15, 10));
    });

    test('accepts an integer price and widens to double', () {
      final step = PriceStep.fromJson({
        'source': 'X',
        'from': 'A',
        'to': 'B',
        'price': 1,
        'timestamp': '2026-01-01T00:00:00Z',
      });

      expect(step.price, 1.0);
    });
  });

  group('$BroadcastTransactionRequestDto', () {
    test('toJson serialises unsignedTx + r + s + v', () {
      const dto = BroadcastTransactionRequestDto(
        unsignedTx: '0xunsigned',
        r: '0xrr',
        s: '0xss',
        v: 27,
      );

      expect(dto.toJson(), {
        'unsignedTx': '0xunsigned',
        'r': '0xrr',
        's': '0xss',
        'v': 27,
      });
    });
  });

  group('$BroadcastTransactionResponseDto.fromJson', () {
    test('extracts txHash from the wire body', () {
      final dto = BroadcastTransactionResponseDto.fromJson({'txHash': '0xabc'});

      expect(dto.txHash, '0xabc');
    });
  });

  group('$RealUnitUnsignedTransactionsRequestDto.fromJson', () {
    test('parses swap + deposit', () {
      final dto = RealUnitUnsignedTransactionsRequestDto.fromJson({
        'swap': '0xswap',
        'deposit': '0xdeposit',
      });

      expect(dto.swap, '0xswap');
      expect(dto.deposit, '0xdeposit');
    });
  });

  group('$RealUnitSellConfirmDto.toJson', () {
    test('serialises only the txHash branch', () {
      const dto = RealUnitSellConfirmDto(txHash: '0xtx');

      expect(dto.toJson(), {'txHash': '0xtx'});
    });

    test('serialises only the eip7702 branch when given', () {
      final auth = Eip7702AuthorizationDto(
        chainId: 1,
        address: '0xa',
        nonce: 0,
        yParity: 0,
        r: '0xr',
        s: '0xs',
      );
      final delegation = Eip7702DelegationDto(
        delegate: '0xd',
        delegator: '0xdr',
        authority: '0xauth',
        salt: '0',
        signature: '0xsig',
      );
      final confirm = Eip7702ConfirmDto(
        authorization: auth,
        delegation: delegation,
      );
      final dto = RealUnitSellConfirmDto(eip7702ConfirmDto: confirm);

      final json = dto.toJson();
      expect(json.containsKey('eip7702'), isTrue);
      expect(json.containsKey('txHash'), isFalse);
    });

    test('serialises both fields when both provided', () {
      final auth = Eip7702AuthorizationDto(
        chainId: 1,
        address: '0xa',
        nonce: 0,
        yParity: 0,
        r: '0xr',
        s: '0xs',
      );
      final delegation = Eip7702DelegationDto(
        delegate: '0xd',
        delegator: '0xdr',
        authority: '0xauth',
        salt: '0',
        signature: '0xsig',
      );
      final confirm = Eip7702ConfirmDto(
        authorization: auth,
        delegation: delegation,
      );
      final dto = RealUnitSellConfirmDto(
        eip7702ConfirmDto: confirm,
        txHash: '0xtx',
      );

      final json = dto.toJson();
      expect(json['txHash'], '0xtx');
      expect(json['eip7702'], isA<Map<String, dynamic>>());
    });

    test('serialises empty object when both fields are null', () {
      const dto = RealUnitSellConfirmDto();

      expect(dto.toJson(), <String, dynamic>{});
    });
  });

  group('$Eip7702DelegationDto.toJson', () {
    test('round-trips the five fields', () {
      final dto = Eip7702DelegationDto(
        delegate: '0xd',
        delegator: '0xdr',
        authority: '0xauth',
        salt: '0',
        signature: '0xsig',
      );

      expect(dto.toJson(), {
        'delegate': '0xd',
        'delegator': '0xdr',
        'authority': '0xauth',
        'salt': '0',
        'signature': '0xsig',
      });
    });
  });
}
