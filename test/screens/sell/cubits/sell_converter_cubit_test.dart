import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:realunit_wallet/packages/service/dfx/dfx_brokerbot_service.dart';
import 'package:realunit_wallet/packages/service/dfx/models/brokerbot/dfx_buy_price_dto.dart';
import 'package:realunit_wallet/packages/service/dfx/models/brokerbot/dfx_sell_price_dto.dart';
import 'package:realunit_wallet/packages/service/dfx/models/brokerbot/dfx_sell_shares_dto.dart';
import 'package:realunit_wallet/screens/sell/cubits/sell_converter/sell_converter_cubit.dart';
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

  group('$SellConverterCubit', () {
    test('initial state is empty with CHF', () {
      final cubit = SellConverterCubit(service);

      expect(cubit.state.fiatText, '');
      expect(cubit.state.sharesText, '');
      expect(cubit.state.currency, Currency.chf);
      expect(cubit.state.loading, isFalse);
    });

    test('onFiatChanged debounces, then writes shares from getSellShares', () async {
      when(() => service.getSellShares(any(), any())).thenAnswer(
        (_) async => BrokerbotSellSharesDto(
          targetAmount: 100,
          shares: 8,
          pricePerShare: 12.5,
          currency: 'CHF',
        ),
      );

      final cubit = SellConverterCubit(service);
      await cubit.onFiatChanged('100');
      await Future<void>.delayed(const Duration(milliseconds: 250));

      expect(cubit.state.fiatText, '100');
      expect(cubit.state.sharesText, '8');
      expect(cubit.state.loading, isFalse);
      verify(() => service.getSellShares('100', Currency.chf)).called(1);
    });

    test('onFiatChanged respects an explicit currency argument', () async {
      when(() => service.getSellShares(any(), any())).thenAnswer(
        (_) async => BrokerbotSellSharesDto(
          targetAmount: 100,
          shares: 8,
          pricePerShare: 12.5,
          currency: 'EUR',
        ),
      );

      final cubit = SellConverterCubit(service);
      await cubit.onFiatChanged('100', currency: Currency.eur);
      await Future<void>.delayed(const Duration(milliseconds: 250));

      verify(() => service.getSellShares('100', Currency.eur)).called(1);
    });

    test('onFiatChanged debounce keeps only the latest value', () async {
      when(() => service.getSellShares(any(), any())).thenAnswer(
        (_) async => BrokerbotSellSharesDto(
          targetAmount: 1,
          shares: 1,
          pricePerShare: 1,
          currency: 'CHF',
        ),
      );

      final cubit = SellConverterCubit(service);
      await cubit.onFiatChanged('1');
      await cubit.onFiatChanged('12');
      await cubit.onFiatChanged('123');
      await Future<void>.delayed(const Duration(milliseconds: 250));

      verify(() => service.getSellShares('123', any())).called(1);
      verifyNever(() => service.getSellShares('1', any()));
      verifyNever(() => service.getSellShares('12', any()));
    });

    test('onFiatChanged leaves state stable on service error', () async {
      when(
        () => service.getSellShares(any(), any()),
      ).thenAnswer((_) async => throw Exception('throttle'));

      final cubit = SellConverterCubit(service);
      await cubit.onFiatChanged('5');
      await Future<void>.delayed(const Duration(milliseconds: 250));

      expect(cubit.state.fiatText, '5');
      expect(cubit.state.sharesText, '');
      expect(cubit.state.loading, isFalse);
    });

    test('onSharesChanged writes estimatedAmount with matching fractional digits', () async {
      when(() => service.getSellPrice(any(), any())).thenAnswer(
        (_) async => BrokerbotSellPriceDto(
          shares: 10,
          estimatedAmount: 125.5,
          pricePerShare: 12.55,
          currency: 'CHF',
        ),
      );

      final cubit = SellConverterCubit(service);
      // 3 fractional digits in input → 3 in output.
      await cubit.onSharesChanged('10.000');
      await Future<void>.delayed(const Duration(milliseconds: 250));

      expect(cubit.state.sharesText, '10.000');
      expect(cubit.state.fiatText, '125.500');
    });

    test('onSharesChanged leaves state stable on service error', () async {
      // Symmetry guard: the `onFiatChanged` throw path is already pinned;
      // the shares-side debounce body must also reset `loading=false`
      // instead of stranding the UI on a spinner.
      when(
        () => service.getSellPrice(any(), any()),
      ).thenAnswer((_) async => throw Exception('throttle'));

      final cubit = SellConverterCubit(service);
      await cubit.onSharesChanged('5');
      await Future<void>.delayed(const Duration(milliseconds: 250));

      expect(cubit.state.sharesText, '5');
      expect(cubit.state.fiatText, '');
      expect(cubit.state.loading, isFalse);
    });

    test('onSharesChanged defaults to 2 fractional digits when input has no dot', () async {
      when(() => service.getSellPrice(any(), any())).thenAnswer(
        (_) async => BrokerbotSellPriceDto(
          shares: 10,
          estimatedAmount: 125.5,
          pricePerShare: 12.55,
          currency: 'CHF',
        ),
      );

      final cubit = SellConverterCubit(service);
      await cubit.onSharesChanged('10');
      await Future<void>.delayed(const Duration(milliseconds: 250));

      expect(cubit.state.fiatText, '125.50');
    });

    test('onCurrencyChanged calls getBuyPrice (not getSellPrice) with current shares', () async {
      // Note: the cubit uses BUY price for currency switch (likely on purpose
      // to convert the displayed share count to a fiat estimate without the
      // sell-side fee deduction). This test pins that contract.
      when(() => service.getBuyPrice(any(), any())).thenAnswer(
        (_) async => BrokerbotBuyPriceDto(
          totalCost: 50.0,
          pricePerShare: 5.0,
          availableShares: 100,
        ),
      );

      final cubit = SellConverterCubit(service);
      // Seed with some shares via onSharesChanged so currency switch has input.
      when(() => service.getSellPrice(any(), any())).thenAnswer(
        (_) async => BrokerbotSellPriceDto(
          shares: 10,
          estimatedAmount: 100,
          pricePerShare: 10,
          currency: 'CHF',
        ),
      );
      await cubit.onSharesChanged('10');
      await Future<void>.delayed(const Duration(milliseconds: 250));

      await cubit.onCurrencyChanged(Currency.eur);

      expect(cubit.state.currency, Currency.eur);
      expect(cubit.state.fiatText, '50.00');
      verify(() => service.getBuyPrice('10', Currency.eur)).called(1);
    });

    test('onCurrencyChanged flips currency even when getBuyPrice throws', () async {
      when(
        () => service.getBuyPrice(any(), any()),
      ).thenAnswer((_) async => throw Exception('throttle'));

      final cubit = SellConverterCubit(service);
      await cubit.onCurrencyChanged(Currency.eur);

      expect(cubit.state.currency, Currency.eur);
      expect(cubit.state.loading, isFalse);
    });

    test('close() cancels pending debounce timers', () async {
      when(() => service.getSellShares(any(), any())).thenAnswer(
        (_) async => BrokerbotSellSharesDto(
          targetAmount: 1,
          shares: 1,
          pricePerShare: 1,
          currency: 'CHF',
        ),
      );

      final cubit = SellConverterCubit(service);
      await cubit.onFiatChanged('5');
      await cubit.close();
      await Future<void>.delayed(const Duration(milliseconds: 250));

      verifyNever(() => service.getSellShares(any(), any()));
    });

    test('does not emit after close', () async {
      final completer = Completer<BrokerbotSellSharesDto>();
      when(() => service.getSellShares(any(), any())).thenAnswer((_) => completer.future);

      final cubit = SellConverterCubit(service);
      await cubit.onFiatChanged('100');
      // Let the debounce timer fire.
      await Future<void>.delayed(const Duration(milliseconds: 150));
      await cubit.close();
      completer.complete(
        BrokerbotSellSharesDto(
          targetAmount: 100,
          shares: 1,
          pricePerShare: 100,
          currency: 'CHF',
        ),
      );

      // If emit fires after close, StateError is thrown by the framework.
    });
  });
}
