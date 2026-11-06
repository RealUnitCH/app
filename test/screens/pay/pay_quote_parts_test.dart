import 'package:flutter_test/flutter_test.dart';
import 'package:realunit_wallet/packages/service/dfx/models/history/dto/pay_quote_dto.dart';
import 'package:realunit_wallet/screens/pay/pay_quote_parts.dart';

void main() {
  test('payQuoteParts matches the quote figures for two shares', () {
    final parts = payQuoteParts(
      billChf: 2,
      shares: 2,
      proceedsChf: 2.4,
      feeChf: 0.05,
      feeRealu: 0.05 / 1.2,
    );

    expect(formatPayRealu(parts.billRealu), '1.66666667 REALU');
    expect(formatPayRealu(parts.feeRealu), '0.04166667 REALU');
    expect(formatPayFiat(parts.feeChf, 'CHF'), '0.05 CHF');
    expect(formatPayFiat(parts.roundingChf, 'CHF'), '0.35 CHF');
    expect(formatPayRealu(parts.roundingRealu), '0.29166667 REALU');
    expect(formatPayFiat(parts.totalChf, 'CHF'), '2.40 CHF');
    expect(formatWholeRealu(2), '2 REALU');
    expect(formatPayRealu(parts.totalRealu), '2.00 REALU');
  });

  test('tryParse rejects a referral amount, empty text, and the wrong shape', () {
    expect(PayQuoteDto.tryParse('246.50'), isNull);
    expect(PayQuoteDto.tryParse(''), isNull);
    expect(PayQuoteDto.tryParse(null), isNull);
    expect(PayQuoteDto.tryParse('[]'), isNull);
    expect(PayQuoteDto.tryParse('not json'), isNull);
    expect(PayQuoteDto.tryParse('{}'), isNull);
    expect(PayQuoteDto.tryParse('{"kind":"other"}'), isNull);
  });

  test('encode and tryParse keep the numbers', () {
    const breakdown = PayQuoteDto(
      merchantName: 'Café Zürich',
      billChf: 2,
      shares: 3,
      proceedsChf: 3.6,
      feeChf: 0.05,
      feeRealu: 0.05 / 1.2,
    );

    final parsed = PayQuoteDto.tryParse(breakdown.encode());

    expect(parsed, isNotNull);
    expect(parsed!.merchantName, breakdown.merchantName);
    expect(parsed.billChf, breakdown.billChf);
    expect(parsed.shares, breakdown.shares);
    expect(parsed.proceedsChf, breakdown.proceedsChf);
    expect(parsed.feeChf, breakdown.feeChf);
    expect(parsed.feeRealu, breakdown.feeRealu);
  });

  test('tryFromJson rejects a non-finite number and a non-string merchant', () {
    expect(
      PayQuoteDto.tryFromJson({
        'billChf': double.nan,
        'shares': 3,
        'proceedsChf': 3.6,
        'feeChf': 0.05,
        'feeRealu': 0.04,
      }),
      isNull,
    );
    expect(
      PayQuoteDto.tryFromJson({
        'merchantName': 1,
        'billChf': 2,
        'shares': 3,
        'proceedsChf': 3.6,
        'feeChf': 0.05,
        'feeRealu': 0.04,
      }),
      isNull,
    );
    expect(
      PayQuoteDto.tryFromJson({
        'kind': 'payQuote',
        'billChf': double.infinity,
        'shares': 3,
        'proceedsChf': 3.6,
        'feeChf': 0.05,
        'feeRealu': 0.04,
      }),
      isNull,
    );
  });

  test('encode omits a null or blank merchant name', () {
    const blank = PayQuoteDto(
      merchantName: '   ',
      billChf: 2,
      shares: 3,
      proceedsChf: 3.6,
      feeChf: 0.05,
      feeRealu: 0.05 / 1.2,
    );
    const missing = PayQuoteDto(
      merchantName: null,
      billChf: 2,
      shares: 3,
      proceedsChf: 3.6,
      feeChf: 0.05,
      feeRealu: 0.05 / 1.2,
    );

    expect(blank.encode(), isNot(contains('merchantName')));
    expect(missing.encode(), isNot(contains('merchantName')));
    expect(blank.encode(), contains('payQuote'));
  });
}
