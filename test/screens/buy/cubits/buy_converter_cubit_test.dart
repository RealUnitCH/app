import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:realunit_wallet/packages/service/dfx/dfx_brokerbot_service.dart';
import 'package:realunit_wallet/packages/service/dfx/models/brokerbot/dfx_buy_price_dto.dart';
import 'package:realunit_wallet/packages/service/dfx/models/brokerbot/dfx_buy_shares_dto.dart';
import 'package:realunit_wallet/screens/buy/cubits/buy_converter/buy_converter_cubit.dart';
import 'package:realunit_wallet/styles/currency.dart';

class _MockBrokerbotService extends Mock implements DfxBrokerbotService {}

void main() {
  late _MockBrokerbotService service;

  setUpAll(() {
    registerFallbackValue(Currency.chf);
  });

  setUp(() {
    service = _MockBrokerbotService();
  });

  group('$BuyConverterCubit', () {
    test('initial state is empty with CHF', () {
      final cubit = BuyConverterCubit(service);

      expect(cubit.state.fiatText, '');
      expect(cubit.state.sharesText, '');
      expect(cubit.state.currency, Currency.chf);
      expect(cubit.state.loading, isFalse);
    });

    test('onFiatChanged debounces, then writes the converted shares', () async {
      when(() => service.getBuyShares(any(), any())).thenAnswer(
        (_) async => BrokerbotBuySharesDto(
          shares: 7,
          pricePerShare: 12.5,
          availableShares: 100,
        ),
      );

      final cubit = BuyConverterCubit(service);
      await cubit.onFiatChanged('100');
      // Past the 100ms debounce.
      await Future<void>.delayed(const Duration(milliseconds: 250));

      expect(cubit.state.fiatText, '100');
      expect(cubit.state.sharesText, '7');
      expect(cubit.state.loading, isFalse);
      verify(() => service.getBuyShares('100', Currency.chf)).called(1);
    });

    test('onFiatChanged debounces — only the latest value reaches the service', () async {
      when(() => service.getBuyShares(any(), any())).thenAnswer(
        (_) async => BrokerbotBuySharesDto(
          shares: 9,
          pricePerShare: 1,
          availableShares: 99,
        ),
      );

      final cubit = BuyConverterCubit(service);
      // Three rapid keystrokes; only the last should reach the service.
      await cubit.onFiatChanged('1');
      await cubit.onFiatChanged('12');
      await cubit.onFiatChanged('123');
      await Future<void>.delayed(const Duration(milliseconds: 250));

      verify(() => service.getBuyShares('123', any())).called(1);
      verifyNever(() => service.getBuyShares('1', any()));
      verifyNever(() => service.getBuyShares('12', any()));
    });

    test('onFiatChanged keeps state intact when the service throws', () async {
      when(
        () => service.getBuyShares(any(), any()),
      ).thenAnswer((_) async => throw Exception('bad input'));

      final cubit = BuyConverterCubit(service);
      await cubit.onFiatChanged('-1');
      await Future<void>.delayed(const Duration(milliseconds: 250));

      expect(cubit.state.fiatText, '-1');
      expect(cubit.state.sharesText, '');
      expect(cubit.state.loading, isFalse);
    });

    test(
      'onSharesChanged debounces, then writes the converted fiat with matching fractional digits',
      () async {
        when(() => service.getBuyPrice(any(), any())).thenAnswer(
          (_) async => BrokerbotBuyPriceDto(
            totalCost: 125.5,
            pricePerShare: 25.1,
            availableShares: 100,
          ),
        );

        final cubit = BuyConverterCubit(service);
        // Input has 3 fractional digits → output has 3.
        await cubit.onSharesChanged('5.000');
        await Future<void>.delayed(const Duration(milliseconds: 250));

        expect(cubit.state.sharesText, '5.000');
        expect(cubit.state.fiatText, '125.500');
      },
    );

    test('onSharesChanged keeps state intact when the service throws', () async {
      // Mirror of the `onFiatChanged` throw guard: the sell-side debounce
      // body must not leak a state.loading=true when getBuyPrice fails.
      when(
        () => service.getBuyPrice(any(), any()),
      ).thenAnswer((_) async => throw Exception('throttle'));

      final cubit = BuyConverterCubit(service);
      await cubit.onSharesChanged('5');
      await Future<void>.delayed(const Duration(milliseconds: 250));

      expect(cubit.state.sharesText, '5');
      expect(cubit.state.fiatText, '');
      expect(cubit.state.loading, isFalse);
    });

    test('onSharesChanged uses 2 fractional digits when input has no dot', () async {
      when(() => service.getBuyPrice(any(), any())).thenAnswer(
        (_) async => BrokerbotBuyPriceDto(
          totalCost: 125.5,
          pricePerShare: 25.1,
          availableShares: 100,
        ),
      );

      final cubit = BuyConverterCubit(service);
      await cubit.onSharesChanged('5');
      await Future<void>.delayed(const Duration(milliseconds: 250));

      expect(cubit.state.fiatText, '125.50');
    });

    test(
      'onCurrencyChanged refetches shares with the new currency and emits both fields',
      () async {
        when(() => service.getBuyShares(any(), any())).thenAnswer(
          (_) async => BrokerbotBuySharesDto(
            shares: 3,
            pricePerShare: 10,
            availableShares: 100,
          ),
        );

        final cubit = BuyConverterCubit(service);
        await cubit.onCurrencyChanged(Currency.eur);

        expect(cubit.state.currency, Currency.eur);
        expect(cubit.state.sharesText, '3');
        expect(cubit.state.loading, isFalse);
        verify(() => service.getBuyShares('', Currency.eur)).called(1);
      },
    );

    test('onCurrencyChanged still flips currency even on service error', () async {
      when(
        () => service.getBuyShares(any(), any()),
      ).thenAnswer((_) async => throw Exception('throttle'));

      final cubit = BuyConverterCubit(service);
      await cubit.onCurrencyChanged(Currency.eur);

      expect(cubit.state.currency, Currency.eur);
      expect(cubit.state.loading, isFalse);
    });

    test('close() cancels pending debounce timers', () async {
      when(() => service.getBuyShares(any(), any())).thenAnswer(
        (_) async => BrokerbotBuySharesDto(
          shares: 1,
          pricePerShare: 1,
          availableShares: 1,
        ),
      );

      final cubit = BuyConverterCubit(service);
      await cubit.onFiatChanged('5');
      // Close before the 100ms debounce fires.
      await cubit.close();
      await Future<void>.delayed(const Duration(milliseconds: 250));

      verifyNever(() => service.getBuyShares(any(), any()));
    });

    test('does not emit after close', () async {
      final completer = Completer<BrokerbotBuySharesDto>();
      when(() => service.getBuyShares(any(), any())).thenAnswer((_) => completer.future);

      final cubit = BuyConverterCubit(service);
      await cubit.onFiatChanged('100');
      await Future<void>.delayed(const Duration(milliseconds: 150));
      await cubit.close();
      completer.complete(
        BrokerbotBuySharesDto(
          shares: 1,
          pricePerShare: 100,
          availableShares: 100,
        ),
      );
    });
  });
}
