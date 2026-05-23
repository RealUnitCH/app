// We deliberately use non-const constructors throughout this file so the
// generative constructor lines get counted as executed in the coverage
// report. Const-only construction is a compile-time optimisation and is
// not visible to the line-coverage instrumentation.
// ignore_for_file: prefer_const_constructors
import 'package:flutter_test/flutter_test.dart';
import 'package:realunit_wallet/screens/transaction_history/cubits/multi_receipt/transaction_history_multi_receipt_cubit.dart';

/// Equatable-`props` surface tests for `TransactionHistoryMultiReceiptState`.
///
/// `Failure` here intentionally inherits the base class' empty `props`,
/// mirroring the single-receipt and tax-report state files. Pin that
/// behaviour so the asymmetry stays observable.
void main() {
  group('TransactionHistoryMultiReceiptInitial', () {
    test('two instances are equal and props are empty', () {
      final a = TransactionHistoryMultiReceiptInitial();
      final b = TransactionHistoryMultiReceiptInitial();
      expect(a, equals(b));
      expect(a.hashCode, b.hashCode);
      expect(a.props, isEmpty);
    });
  });

  group('TransactionHistoryMultiReceiptLoading', () {
    test('two instances are equal and props are empty', () {
      final a = TransactionHistoryMultiReceiptLoading();
      final b = TransactionHistoryMultiReceiptLoading();
      expect(a, equals(b));
      expect(a.props, isEmpty);
    });
  });

  group('TransactionHistoryMultiReceiptSuccess', () {
    test('same receiptPath is equal and props match', () {
      final a = TransactionHistoryMultiReceiptSuccess('/tmp/a.pdf');
      final b = TransactionHistoryMultiReceiptSuccess('/tmp/a.pdf');
      expect(a, equals(b));
      expect(a.props, ['/tmp/a.pdf']);
    });

    test('different receiptPath is unequal', () {
      final a = TransactionHistoryMultiReceiptSuccess('/tmp/a.pdf');
      final b = TransactionHistoryMultiReceiptSuccess('/tmp/b.pdf');
      expect(a, isNot(equals(b)));
    });
  });

  group('TransactionHistoryMultiReceiptFailure', () {
    test('does not override props → message difference does not affect equality', () {
      final a = TransactionHistoryMultiReceiptFailure('boom');
      final b = TransactionHistoryMultiReceiptFailure('other');
      expect(a, equals(b));
      expect(a.message, 'boom');
      expect(b.message, 'other');
      expect(a.props, isEmpty);
    });
  });

  group('TransactionHistoryMultiReceiptState (cross-subclass identity)', () {
    test('Initial vs Loading are unequal', () {
      expect(
        TransactionHistoryMultiReceiptInitial(),
        isNot(equals(TransactionHistoryMultiReceiptLoading())),
      );
    });

    test('Success vs Failure are unequal even with overlapping props', () {
      final s = TransactionHistoryMultiReceiptSuccess('/tmp/x');
      final f = TransactionHistoryMultiReceiptFailure('/tmp/x');
      expect(s, isNot(equals(f)));
    });
  });
}
