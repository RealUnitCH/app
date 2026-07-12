// We deliberately use non-const constructors throughout this file so the
// generative constructor lines get counted as executed in the coverage
// report. Const-only construction is a compile-time optimisation and is
// not visible to the line-coverage instrumentation.
// ignore_for_file: prefer_const_constructors
import 'package:flutter_test/flutter_test.dart';
import 'package:realunit_wallet/packages/service/dfx/models/payment/payment_info_error.dart';
import 'package:realunit_wallet/packages/service/dfx/models/payment/sell/sell_payment_info.dart';
import 'package:realunit_wallet/packages/service/dfx/models/payment/sell/dto/eip7702/eip7702_data_dto.dart';
import 'package:realunit_wallet/packages/service/dfx/models/payment/sell/dto/real_unit_sell_payment_info_dto.dart';
import 'package:realunit_wallet/screens/sell/cubits/sell_payment_info/sell_payment_info_cubit.dart';
import 'package:realunit_wallet/styles/currency.dart';

/// Equatable-`props` surface tests for `SellPaymentInfoState`.
SellPaymentInfo _info() => SellPaymentInfo(
  id: 1,
  eip7702: Eip7702Data.fromJson({
    'relayerAddress': '0xr',
    'delegationManagerAddress': '0xm',
    'delegatorAddress': '0xd',
    'userNonce': 0,
    'domain': {
      'name': 'X',
      'version': '1',
      'chainId': 1,
      'verifyingContract': '0xv',
    },
    'types': {'Delegation': <Map<String, dynamic>>[], 'Caveat': <Map<String, dynamic>>[]},
    'message': {
      'delegate': '0xd',
      'delegator': '0xd',
      'authority': '0xa',
      'caveats': <Map<String, dynamic>>[],
      'salt': 0,
    },
    'tokenAddress': '0xt',
    'amountWei': '1',
    'depositAddress': '0xd',
  }),
  amount: 1,
  exchangeRate: 1,
  rate: 1,
  beneficiary: const BeneficiaryDto(iban: 'CH'),
  estimatedAmount: 1,
  currency: Currency.chf,
  depositAddress: '0xd',
  tokenAddress: '0xt',
  chainId: 1,
  ethBalance: 0,
  requiredGasEth: 0,
);

void main() {
  group('SellPaymentInfoInitial', () {
    test('two instances are equal and props are empty', () {
      final a = SellPaymentInfoInitial();
      final b = SellPaymentInfoInitial();
      expect(a, equals(b));
      expect(a.hashCode, b.hashCode);
      expect(a.props, isEmpty);
    });
  });

  group('SellPaymentInfoLoading', () {
    test('two instances are equal and props are empty', () {
      final a = SellPaymentInfoLoading();
      final b = SellPaymentInfoLoading();
      expect(a, equals(b));
      expect(a.props, isEmpty);
    });
  });

  group('SellPaymentInfoSuccess', () {
    test('same paymentInfo+isBitbox is equal and props match', () {
      final info = _info();
      final a = SellPaymentInfoSuccess(info, isBitbox: false);
      final b = SellPaymentInfoSuccess(info, isBitbox: false);
      expect(a, equals(b));
      expect(a.props, [info, false]);
    });

    test('different isBitbox flag is unequal', () {
      final info = _info();
      final a = SellPaymentInfoSuccess(info, isBitbox: false);
      final b = SellPaymentInfoSuccess(info, isBitbox: true);
      expect(a, isNot(equals(b)));
    });
  });

  group('SellPaymentInfoFailure', () {
    test('same error+message+level is equal and props match', () {
      final a = SellPaymentInfoFailure(
        PaymentInfoError.kycRequired,
        message: 'm',
        requiredLevel: 30,
      );
      final b = SellPaymentInfoFailure(
        PaymentInfoError.kycRequired,
        message: 'm',
        requiredLevel: 30,
      );
      expect(a, equals(b));
      expect(a.props, [PaymentInfoError.kycRequired, 'm', 30, null]);
    });

    test('default message is empty string', () {
      final a = SellPaymentInfoFailure(PaymentInfoError.kycRequired);
      expect(a.message, '');
    });

    test('different message is unequal', () {
      final a = SellPaymentInfoFailure(PaymentInfoError.kycRequired, message: 'a');
      final b = SellPaymentInfoFailure(PaymentInfoError.kycRequired, message: 'b');
      expect(a, isNot(equals(b)));
    });

    test('same error+message+level+context is equal and props match', () {
      final a = SellPaymentInfoFailure(
        PaymentInfoError.kycRequired,
        message: 'm',
        requiredLevel: 30,
        context: 'RealunitSell',
      );
      final b = SellPaymentInfoFailure(
        PaymentInfoError.kycRequired,
        message: 'm',
        requiredLevel: 30,
        context: 'RealunitSell',
      );
      expect(a, equals(b));
      expect(a.props, [PaymentInfoError.kycRequired, 'm', 30, 'RealunitSell']);
    });

    test('different context is unequal', () {
      final a = SellPaymentInfoFailure(
        PaymentInfoError.kycRequired,
        context: 'RealunitBuy',
      );
      final b = SellPaymentInfoFailure(
        PaymentInfoError.kycRequired,
        context: 'RealunitSell',
      );
      expect(a, isNot(equals(b)));
    });
  });

  group('SellPaymentInfoMinAmountNotMet', () {
    test('same minAmount+currency is equal and props match', () {
      final a = SellPaymentInfoMinAmountNotMet(minAmount: 10, currency: Currency.chf);
      final b = SellPaymentInfoMinAmountNotMet(minAmount: 10, currency: Currency.chf);
      expect(a, equals(b));
      expect(a.props, [10, Currency.chf]);
    });

    test('different currency is unequal', () {
      final a = SellPaymentInfoMinAmountNotMet(minAmount: 10, currency: Currency.chf);
      final b = SellPaymentInfoMinAmountNotMet(minAmount: 10, currency: Currency.eur);
      expect(a, isNot(equals(b)));
    });
  });

  group('SellPaymentInfoState (cross-subclass identity)', () {
    test('Initial vs Loading are unequal', () {
      expect(SellPaymentInfoInitial(), isNot(equals(SellPaymentInfoLoading())));
    });

    test('Failure vs MinAmountNotMet are unequal', () {
      final f = SellPaymentInfoFailure(PaymentInfoError.minAmountNotMet);
      final m = SellPaymentInfoMinAmountNotMet(minAmount: 10, currency: Currency.chf);
      expect(f, isNot(equals(m)));
    });
  });
}
