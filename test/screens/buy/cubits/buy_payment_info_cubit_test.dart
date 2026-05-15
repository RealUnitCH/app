import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:realunit_wallet/packages/service/dfx/dfx_price_service.dart';
import 'package:realunit_wallet/packages/service/dfx/exceptions/payment/buy_exceptions.dart';
import 'package:realunit_wallet/packages/service/dfx/models/payment/buy/buy_payment_info.dart';
import 'package:realunit_wallet/packages/service/dfx/models/payment/payment_info_error.dart';
import 'package:realunit_wallet/packages/service/dfx/real_unit_buy_payment_info_service.dart';
import 'package:realunit_wallet/screens/buy/cubits/buy_payment_info/buy_payment_info_cubit.dart';
import 'package:realunit_wallet/styles/currency.dart';

class _MockBuyPaymentInfoService extends Mock
    implements RealUnitBuyPaymentInfoService {}

class _MockPriceService extends Mock implements DFXPriceService {}

const _info = BuyPaymentInfo(
  id: 1,
  iban: 'CH56 0483 5012 3456 78',
  bic: 'CRESCHZZ80A',
  name: 'DFX AG',
  street: 'Bahnhofstrasse',
  number: '1',
  zip: '8000',
  city: 'Zurich',
  country: 'CH',
  currency: Currency.chf,
);

void main() {
  late _MockBuyPaymentInfoService service;
  late _MockPriceService priceService;

  setUpAll(() {
    registerFallbackValue(Currency.chf);
  });

  setUp(() {
    service = _MockBuyPaymentInfoService();
    priceService = _MockPriceService();
  });

  BuyPaymentInfoCubit build() => BuyPaymentInfoCubit(service, priceService);

  group('$BuyPaymentInfoCubit', () {
    test('initial state is BuyPaymentInfoInitial', () {
      expect(build().state, isA<BuyPaymentInfoInitial>());
    });

    test('happy path with CHF emits Loading then Success', () async {
      when(() => service.getPaymentInfo(any(), currency: any(named: 'currency')))
          .thenAnswer((_) async => _info);

      final cubit = build();
      await cubit.getPaymentInfo(amount: '300');

      expect(cubit.state, isA<BuyPaymentInfoSuccess>());
      expect((cubit.state as BuyPaymentInfoSuccess).buyPaymentInfo, _info);
      verify(() => service.getPaymentInfo(300, currency: Currency.chf)).called(1);
    });

    test('amount below 100 CHF minimum → MinAmountNotMetFailure', () async {
      final cubit = build();
      await cubit.getPaymentInfo(amount: '50');

      expect(cubit.state, isA<BuyPaymentInfoMinAmountNotMetFailure>());
      final f = cubit.state as BuyPaymentInfoMinAmountNotMetFailure;
      expect(f.error, PaymentInfoError.minAmountNotMet);
      expect(f.minAmount, 100);
      verifyNever(() => service.getPaymentInfo(any(), currency: any(named: 'currency')));
    });

    test('EUR minimum is scaled by getChfToEurRate (ceil'
        ')', () async {
      // 100 CHF * 0.92 EUR/CHF = 92 → ceil = 92.
      when(() => priceService.getChfToEurRate()).thenAnswer((_) async => 0.92);

      final cubit = build();
      await cubit.getPaymentInfo(amount: '50', currency: Currency.eur);

      expect(cubit.state, isA<BuyPaymentInfoMinAmountNotMetFailure>());
      final f = cubit.state as BuyPaymentInfoMinAmountNotMetFailure;
      expect(f.minAmount, 92);
    });

    test('EUR amount above scaled minimum proceeds to service', () async {
      when(() => priceService.getChfToEurRate()).thenAnswer((_) async => 0.92);
      when(() => service.getPaymentInfo(any(), currency: any(named: 'currency')))
          .thenAnswer((_) async => _info);

      final cubit = build();
      await cubit.getPaymentInfo(amount: '200', currency: Currency.eur);

      expect(cubit.state, isA<BuyPaymentInfoSuccess>());
      verify(() => service.getPaymentInfo(200, currency: Currency.eur)).called(1);
    });

    test('empty amount string is treated as 0 → below minimum', () async {
      final cubit = build();
      await cubit.getPaymentInfo(amount: '');

      expect(cubit.state, isA<BuyPaymentInfoMinAmountNotMetFailure>());
    });

    test('comma decimal separator is normalised to dot', () async {
      when(() => service.getPaymentInfo(any(), currency: any(named: 'currency')))
          .thenAnswer((_) async => _info);

      final cubit = build();
      await cubit.getPaymentInfo(amount: '300,75');

      // 300.75 rounded to 301.
      verify(() => service.getPaymentInfo(301, currency: Currency.chf)).called(1);
    });

    test('KycLevelRequiredException → Failure(kycRequired, requiredLevel)', () async {
      when(() => service.getPaymentInfo(any(), currency: any(named: 'currency')))
          .thenAnswer(
        (_) async => throw const KycLevelRequiredException(
          statusCode: 403,
          code: 'KYC_REQUIRED',
          message: 'KYC required',
          requiredLevel: 30,
          currentLevel: 10,
        ),
      );

      final cubit = build();
      await cubit.getPaymentInfo(amount: '300');

      final f = cubit.state as BuyPaymentInfoFailure;
      expect(f.error, PaymentInfoError.kycRequired);
      expect(f.requiredLevel, 30);
    });

    test('RegistrationRequiredException → Failure(registrationRequired)', () async {
      when(() => service.getPaymentInfo(any(), currency: any(named: 'currency')))
          .thenAnswer(
        (_) async => throw const RegistrationRequiredException(
          statusCode: 403,
          code: 'REGISTRATION_REQUIRED',
          message: 'Sign first',
        ),
      );

      final cubit = build();
      await cubit.getPaymentInfo(amount: '300');

      final f = cubit.state as BuyPaymentInfoFailure;
      expect(f.error, PaymentInfoError.registrationRequired);
    });

    test('generic exception → Failure(unknown)', () async {
      when(() => service.getPaymentInfo(any(), currency: any(named: 'currency')))
          .thenAnswer((_) async => throw Exception('network'));

      final cubit = build();
      await cubit.getPaymentInfo(amount: '300');

      final f = cubit.state as BuyPaymentInfoFailure;
      expect(f.error, PaymentInfoError.unknown);
    });
  });
}
