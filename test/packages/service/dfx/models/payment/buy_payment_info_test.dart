import 'package:flutter_test/flutter_test.dart';
import 'package:realunit_wallet/packages/service/dfx/models/payment/buy/buy_payment_info.dart';
import 'package:realunit_wallet/styles/currency.dart';

void main() {
  const base = BuyPaymentInfo(
    amount: 300,
    id: 1,
    iban: 'CH93 0076 2011 6238 52957',
    bic: 'UBSWCHZH80A',
    name: 'DFX AG',
    street: 'Bahnhofstrasse',
    number: '1',
    zip: '6300',
    city: 'Zug',
    country: 'CH',
    currency: Currency.chf,
  );

  group('BuyPaymentInfo equality (regression for #207)', () {
    test('same id but different iban are NOT equal', () {
      const other = BuyPaymentInfo(
        amount: 300,
        id: 1,
        iban: 'DE89 3704 0044 0532 0130 00',
        bic: 'UBSWCHZH80A',
        name: 'DFX AG',
        street: 'Bahnhofstrasse',
        number: '1',
        zip: '6300',
        city: 'Zug',
        country: 'CH',
        currency: Currency.chf,
      );

      expect(base, isNot(other));
    });

    test('same id but different currency are NOT equal', () {
      const other = BuyPaymentInfo(
        amount: 300,
        id: 1,
        iban: 'CH93 0076 2011 6238 52957',
        bic: 'UBSWCHZH80A',
        name: 'DFX AG',
        street: 'Bahnhofstrasse',
        number: '1',
        zip: '6300',
        city: 'Zug',
        country: 'CH',
        currency: Currency.eur,
      );

      expect(base, isNot(other));
    });

    test('identical fields are equal', () {
      const clone = BuyPaymentInfo(
        amount: 300,
        id: 1,
        iban: 'CH93 0076 2011 6238 52957',
        bic: 'UBSWCHZH80A',
        name: 'DFX AG',
        street: 'Bahnhofstrasse',
        number: '1',
        zip: '6300',
        city: 'Zug',
        country: 'CH',
        currency: Currency.chf,
      );

      expect(base, clone);
    });
  });
}
