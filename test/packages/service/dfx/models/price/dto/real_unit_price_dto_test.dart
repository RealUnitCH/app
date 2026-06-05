import 'package:flutter_test/flutter_test.dart';
import 'package:realunit_wallet/packages/service/dfx/models/price/dto/real_unit_price_dto.dart';

void main() {
  group('$RealUnitPriceDto', () {
    test('parses chf, eur, and timestamp from a fully populated payload', () {
      final dto = RealUnitPriceDto.fromJson({
        'chf': 1.13,
        'eur': 1.05,
        'timestamp': '2026-06-05T00:00:00Z',
      });

      expect(dto.chf, 1.13);
      expect(dto.eur, 1.05);
      expect(dto.timestamp, DateTime.utc(2026, 6, 5));
    });

    test('coerces integer price values to double', () {
      final dto = RealUnitPriceDto.fromJson({
        'chf': 1,
        'eur': 2,
        'timestamp': '2026-06-05T00:00:00Z',
      });

      expect(dto.chf, 1.0);
      expect(dto.eur, 2.0);
    });

    test('parses a timestamp-only payload (unpriced) to all-null prices', () {
      // The live endpoint returns exactly this shape while no price is
      // published for the timestamp — the bug this DTO guards against.
      final dto = RealUnitPriceDto.fromJson({
        'timestamp': '2026-06-05T08:20:40.232Z',
      });

      expect(dto.chf, isNull);
      expect(dto.eur, isNull);
      expect(dto.timestamp, DateTime.parse('2026-06-05T08:20:40.232Z'));
    });

    test('timestamp is null when absent', () {
      final dto = RealUnitPriceDto.fromJson({'chf': 1.13, 'eur': 1.05});

      expect(dto.timestamp, isNull);
    });

    test('timestamp is null when not a string', () {
      final dto = RealUnitPriceDto.fromJson({
        'chf': 1.13,
        'eur': 1.05,
        'timestamp': 1749081600000,
      });

      expect(dto.timestamp, isNull);
    });

    test('timestamp is null when not parseable as a date', () {
      final dto = RealUnitPriceDto.fromJson({
        'chf': 1.13,
        'eur': 1.05,
        'timestamp': 'not-a-date',
      });

      expect(dto.timestamp, isNull);
    });
  });
}
