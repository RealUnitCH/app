// We deliberately use non-const constructors throughout this file so the
// generative constructor lines get counted as executed in the coverage
// report. Const-only construction is a compile-time optimisation and is
// not visible to the line-coverage instrumentation.
// ignore_for_file: prefer_const_constructors
import 'package:flutter_test/flutter_test.dart';
import 'package:realunit_wallet/models/transaction.dart';
import 'package:realunit_wallet/packages/utils/default_assets.dart';
import 'package:realunit_wallet/screens/transaction_history/cubits/filter/transaction_history_filter_cubit.dart';

/// Constructor + `copyWith` surface tests for `TransactionHistoryFilterState`.
///
/// `TransactionHistoryFilterState` deliberately does NOT extend Equatable —
/// it's a plain value class wrapped by Bloc's `emit`. These tests pin the
/// default-window behaviour (1 year back to now) plus every `copyWith`
/// branch so the file lands at 100% line coverage.
Transaction _tx(DateTime ts) => Transaction(
  height: 1,
  txId: 'tx-${ts.millisecondsSinceEpoch}',
  chainId: realUnitAsset.chainId,
  senderAddress: '0x1',
  receiverAddress: '0x2',
  amount: BigInt.one,
  asset: realUnitAsset,
  type: TransactionTypes.tokenTransfer,
  note: null,
  data: null,
  timestamp: ts,
);

void main() {
  group('TransactionHistoryFilterState defaults', () {
    test('all + filtered default to empty', () {
      final state = TransactionHistoryFilterState();
      expect(state.all, isEmpty);
      expect(state.filtered, isEmpty);
    });

    test('startDate defaults to ~1 year before now, endDate to now', () {
      final before = DateTime.now();
      final state = TransactionHistoryFilterState();
      final after = DateTime.now();

      // startDate is now - 365d ± clock skew between `before` and `after`.
      final lower = before.subtract(const Duration(days: 366));
      final upper = after.subtract(const Duration(days: 364));
      expect(state.startDate, isNotNull);
      expect(
        state.startDate!.isAfter(lower) && state.startDate!.isBefore(upper),
        isTrue,
        reason: 'startDate should fall between $lower and $upper, was ${state.startDate}',
      );

      expect(state.endDate, isNotNull);
      expect(state.endDate!.isAfter(before.subtract(const Duration(seconds: 1))), isTrue);
      expect(state.endDate!.isBefore(after.add(const Duration(seconds: 1))), isTrue);
    });

    test('explicit startDate + endDate are honoured', () {
      final s = DateTime.utc(2026, 1, 1);
      final e = DateTime.utc(2026, 6, 1);
      final state = TransactionHistoryFilterState(startDate: s, endDate: e);
      expect(state.startDate, s);
      expect(state.endDate, e);
    });
  });

  group('TransactionHistoryFilterState.copyWith', () {
    test('copyWith with no args preserves every field', () {
      final s = DateTime.utc(2026, 1, 1);
      final e = DateTime.utc(2026, 6, 1);
      final tx = _tx(DateTime.utc(2026, 3, 1));
      final base = TransactionHistoryFilterState(
        all: [tx],
        filtered: [tx],
        startDate: s,
        endDate: e,
      );

      final next = base.copyWith();
      expect(next.all, base.all);
      expect(next.filtered, base.filtered);
      expect(next.startDate, s);
      expect(next.endDate, e);
    });

    test('copyWith with `all` rewrites only that field', () {
      final base = TransactionHistoryFilterState();
      final tx = _tx(DateTime.utc(2026, 3, 1));
      final next = base.copyWith(all: [tx]);
      expect(next.all, [tx]);
      expect(next.filtered, isEmpty);
    });

    test('copyWith with `filtered` rewrites only that field', () {
      final base = TransactionHistoryFilterState();
      final tx = _tx(DateTime.utc(2026, 3, 1));
      final next = base.copyWith(filtered: [tx]);
      expect(next.filtered, [tx]);
      expect(next.all, isEmpty);
    });

    test('copyWith with new startDate/endDate replaces them', () {
      final base = TransactionHistoryFilterState();
      final s = DateTime.utc(2026, 1, 1);
      final e = DateTime.utc(2026, 6, 1);
      final next = base.copyWith(startDate: s, endDate: e);
      expect(next.startDate, s);
      expect(next.endDate, e);
    });
  });
}
