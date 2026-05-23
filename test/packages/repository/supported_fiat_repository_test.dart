import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:realunit_wallet/packages/repository/supported_fiat_repository.dart';
import 'package:realunit_wallet/packages/service/dfx/dfx_fiat_service.dart';
import 'package:realunit_wallet/packages/service/dfx/models/fiat/dto/dfx_fiat_dto.dart';
import 'package:realunit_wallet/styles/currency.dart';

class _MockFiatService extends Mock implements DfxFiatService {}

void main() {
  late _MockFiatService fiatService;
  late SupportedFiatRepository repo;

  setUp(() {
    fiatService = _MockFiatService();
    repo = SupportedFiatRepository(fiatService);
  });

  group('$SupportedFiatRepository', () {
    test('getBuyable returns only buyable fiats mapped to local Currency', () async {
      when(() => fiatService.getAllFiats()).thenAnswer(
        (_) async => const [
          DfxFiatDto(id: 1, name: 'CHF', buyable: true, sellable: true),
          DfxFiatDto(id: 2, name: 'EUR', buyable: true, sellable: false),
          DfxFiatDto(id: 3, name: 'USD', buyable: false, sellable: true),
        ],
      );

      final buyable = await repo.getBuyable();

      expect(buyable, [Currency.chf, Currency.eur]);
    });

    test('getSellable returns only sellable fiats', () async {
      when(() => fiatService.getAllFiats()).thenAnswer(
        (_) async => const [
          DfxFiatDto(id: 1, name: 'CHF', buyable: true, sellable: true),
          DfxFiatDto(id: 2, name: 'EUR', buyable: true, sellable: false),
        ],
      );

      final sellable = await repo.getSellable();

      expect(sellable, [Currency.chf]);
    });

    test('getAll returns every parseable currency regardless of buy/sell flags', () async {
      // Coverage pin for `getAll` — the only call site that passes the
      // pass-through filter `(_) => true`. The picker uses this when both
      // directions are valid (e.g. portfolio totals), so a regression that
      // accidentally filters out fiat by buyable/sellable would only show up
      // here.
      when(() => fiatService.getAllFiats()).thenAnswer(
        (_) async => const [
          DfxFiatDto(id: 1, name: 'CHF', buyable: false, sellable: false),
          DfxFiatDto(id: 2, name: 'EUR', buyable: false, sellable: true),
          DfxFiatDto(id: 3, name: 'XXX', buyable: true, sellable: true),
        ],
      );

      final all = await repo.getAll();

      // CHF + EUR survive — neither flag filters them out. XXX has no enum
      // value so the skip-with-log path catches it.
      expect(all, [Currency.chf, Currency.eur]);
    });

    test('unknown backend currencies are skipped, not thrown', () async {
      when(() => fiatService.getAllFiats()).thenAnswer(
        (_) async => const [
          DfxFiatDto(id: 1, name: 'CHF', buyable: true, sellable: true),
          DfxFiatDto(id: 99, name: 'USD', buyable: true, sellable: true),
        ],
      );

      final buyable = await repo.getBuyable();

      expect(buyable, [Currency.chf]);
    });
  });
}
