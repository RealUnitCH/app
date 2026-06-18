import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:realunit_wallet/packages/service/dfx/models/payment/buy/buy_payment_info.dart';
import 'package:realunit_wallet/screens/buy/buy_payment_details_page.dart';
import 'package:realunit_wallet/styles/currency.dart';

import '../../../helper/helper.dart';

void main() {
  const params = BuyPaymentDetailsParams(
    buyPaymentInfo: BuyPaymentInfo(
      id: 1,
      iban: 'CH00 0000 0000 0000 0000 0',
      bic: 'BICCBIC',
      name: 'RealUnit AG',
      street: 'Bahnhofstrasse',
      number: '1',
      zip: '8001',
      city: 'Zurich',
      country: 'Switzerland',
      currency: Currency.chf,
    ),
    amount: '100',
    purposeOfPayment: 'RU-2026-000123',
  );

  group('$BuyPaymentDetailsPage', () {
    goldenTest(
      'payment details default',
      fileName: 'buy_payment_details_default',
      constraints: const BoxConstraints.tightFor(width: 390, height: 844),
      builder: () => wrapForGolden(const BuyPaymentDetailsPage(params: params)),
    );
  });
}
