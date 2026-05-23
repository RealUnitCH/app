// We deliberately use non-const constructors throughout this file so the
// generative constructor lines get counted as executed in the coverage
// report. Const-only construction is a compile-time optimisation and is
// not visible to the line-coverage instrumentation.
// ignore_for_file: prefer_const_constructors
import 'package:flutter_test/flutter_test.dart';
import 'package:realunit_wallet/screens/transaction_history/cubits/receipt/transaction_history_receipt_cubit.dart';

/// Equatable-`props` surface tests for `TransactionHistoryReceiptState`.
///
/// `Failure` here intentionally inherits the empty `props` from the base
/// class, mirroring the multi-receipt and tax-report state files.
void main() {
  group('TransactionHistoryReceiptInitial', () {
    test('two instances are equal and props are empty', () {
      final a = TransactionHistoryReceiptInitial();
      final b = TransactionHistoryReceiptInitial();
      expect(a, equals(b));
      expect(a.hashCode, b.hashCode);
      expect(a.props, isEmpty);
    });
  });

  group('TransactionHistoryReceiptLoading', () {
    test('two instances are equal and props are empty', () {
      final a = TransactionHistoryReceiptLoading();
      final b = TransactionHistoryReceiptLoading();
      expect(a, equals(b));
      expect(a.props, isEmpty);
    });
  });

  group('TransactionHistoryReceiptSuccess', () {
    test('same receiptPath is equal and props match', () {
      final a = TransactionHistoryReceiptSuccess('/tmp/a.pdf');
      final b = TransactionHistoryReceiptSuccess('/tmp/a.pdf');
      expect(a, equals(b));
      expect(a.props, ['/tmp/a.pdf']);
    });

    test('different receiptPath is unequal', () {
      final a = TransactionHistoryReceiptSuccess('/tmp/a.pdf');
      final b = TransactionHistoryReceiptSuccess('/tmp/b.pdf');
      expect(a, isNot(equals(b)));
    });
  });

  group('TransactionHistoryReceiptFailure', () {
    test('does not override props → message difference does not affect equality', () {
      final a = TransactionHistoryReceiptFailure('boom');
      final b = TransactionHistoryReceiptFailure('other');
      expect(a, equals(b));
      expect(a.message, 'boom');
      expect(b.message, 'other');
      expect(a.props, isEmpty);
    });
  });

  group('TransactionHistoryReceiptState (cross-subclass identity)', () {
    test('Initial vs Loading are unequal', () {
      expect(
        TransactionHistoryReceiptInitial(),
        isNot(equals(TransactionHistoryReceiptLoading())),
      );
    });

    test('Success vs Failure are unequal even with overlapping props', () {
      final s = TransactionHistoryReceiptSuccess('/tmp/x');
      final f = TransactionHistoryReceiptFailure('/tmp/x');
      expect(s, isNot(equals(f)));
    });
  });
}
