import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:realunit_wallet/packages/service/dfx/exceptions/api_exception.dart';
import 'package:realunit_wallet/packages/service/dfx/models/payment/pay/dto/lnurlp_payment_dto.dart';
import 'package:realunit_wallet/packages/service/dfx/real_unit_pay_service.dart';
import 'package:realunit_wallet/screens/pay/cubits/pay_quote/pay_quote_cubit.dart';

class _MockPayService extends Mock implements RealUnitPayService {}

LnurlpPaymentDto _details({
  required DateTime expiration,
  bool withEthZchf = true,
  double zchf = 42.7,
}) {
  return LnurlpPaymentDto(
    requestedAmount: const LnurlpRequestedAmountDto(asset: 'CHF', amount: 42.5),
    quote: LnurlpQuoteDto(id: 'quote_xyz', expiration: expiration),
    recipient: '0xrecipient',
    transferAmounts: [
      if (withEthZchf)
        LnurlpTransferAmountDto(
          method: 'Ethereum',
          assets: [LnurlpTransferAssetDto(asset: 'ZCHF', amount: zchf)],
        )
      else
        const LnurlpTransferAmountDto(
          method: 'Bitcoin',
          assets: [LnurlpTransferAssetDto(asset: 'BTC', amount: 0.0005)],
        ),
    ],
  );
}

void main() {
  late _MockPayService payService;

  setUp(() => payService = _MockPayService());

  PayQuoteCubit build() => PayQuoteCubit(payService, 'pl_abc');

  blocTest<PayQuoteCubit, PayQuoteState>(
    'a fresh quote with an Ethereum/ZCHF method emits PayQuoteReady',
    build: build,
    setUp: () {
      when(() => payService.getPaymentDetails('pl_abc')).thenAnswer(
        (_) async => _details(expiration: DateTime.now().add(const Duration(minutes: 5))),
      );
    },
    act: (cubit) => cubit.load(),
    expect: () => [isA<PayQuoteLoading>(), isA<PayQuoteReady>()],
    verify: (cubit) {
      final state = cubit.state as PayQuoteReady;
      expect(state.quoteId, 'quote_xyz');
      expect(state.fiatAsset, 'CHF');
      expect(state.fiatAmount, 42.5);
      expect(state.zchfAmount, 42.7);
    },
  );

  blocTest<PayQuoteCubit, PayQuoteState>(
    'an expired quote emits PayQuoteExpired',
    build: build,
    setUp: () {
      when(() => payService.getPaymentDetails('pl_abc')).thenAnswer(
        (_) async => _details(expiration: DateTime.now().subtract(const Duration(minutes: 1))),
      );
    },
    act: (cubit) => cubit.load(),
    expect: () => [isA<PayQuoteLoading>(), isA<PayQuoteExpired>()],
  );

  blocTest<PayQuoteCubit, PayQuoteState>(
    'a link without an Ethereum/ZCHF method emits PayQuoteUnavailable',
    build: build,
    setUp: () {
      when(() => payService.getPaymentDetails('pl_abc')).thenAnswer(
        (_) async => _details(
          expiration: DateTime.now().add(const Duration(minutes: 5)),
          withEthZchf: false,
        ),
      );
    },
    act: (cubit) => cubit.load(),
    expect: () => [isA<PayQuoteLoading>(), isA<PayQuoteUnavailable>()],
  );

  blocTest<PayQuoteCubit, PayQuoteState>(
    'a service error emits PayQuoteError',
    build: build,
    setUp: () {
      when(() => payService.getPaymentDetails('pl_abc')).thenThrow(
        const ApiException(code: 'X', message: 'boom'),
      );
    },
    act: (cubit) => cubit.load(),
    expect: () => [isA<PayQuoteLoading>(), isA<PayQuoteError>()],
  );
}
