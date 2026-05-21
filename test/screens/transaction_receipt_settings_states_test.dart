import 'package:flutter_test/flutter_test.dart';
import 'package:realunit_wallet/screens/settings_contact/cubit/settings_contact_cubit.dart';
import 'package:realunit_wallet/screens/settings_tax_report/cubit/settings_tax_report_cubit.dart';
import 'package:realunit_wallet/screens/transaction_history/cubits/multi_receipt/transaction_history_multi_receipt_cubit.dart';
import 'package:realunit_wallet/screens/transaction_history/cubits/receipt/transaction_history_receipt_cubit.dart';

void main() {
  group('$SettingsContactState', () {
    test('Success defaults supportAvailable to false', () {
      const state = SettingsContactSuccess();
      expect(state.supportAvailable, isFalse);
    });

    test('Success.copyWith preserves untouched field', () {
      const base = SettingsContactSuccess(supportAvailable: true);
      final next = base.copyWith();
      expect(next.supportAvailable, isTrue);
    });

    test('Success Equatable props pin supportAvailable', () {
      expect(
        const SettingsContactSuccess(supportAvailable: true),
        const SettingsContactSuccess(supportAvailable: true),
      );
      expect(
        const SettingsContactSuccess(supportAvailable: true),
        isNot(const SettingsContactSuccess()),
      );
    });
  });

  group('$TransactionHistoryReceiptState', () {
    test('Success props pin the receiptPath', () {
      expect(
        const TransactionHistoryReceiptSuccess('/tmp/a.pdf'),
        const TransactionHistoryReceiptSuccess('/tmp/a.pdf'),
      );
      expect(
        const TransactionHistoryReceiptSuccess('/tmp/a.pdf'),
        isNot(const TransactionHistoryReceiptSuccess('/tmp/b.pdf')),
      );
    });

    test('Initial and Loading are distinct singletons', () {
      expect(const TransactionHistoryReceiptInitial(),
          const TransactionHistoryReceiptInitial());
      expect(const TransactionHistoryReceiptInitial(),
          isNot(const TransactionHistoryReceiptLoading()));
    });
  });

  group('$TransactionHistoryMultiReceiptState', () {
    test('Success props pin the receiptPath', () {
      expect(
        const TransactionHistoryMultiReceiptSuccess('/tmp/a.pdf'),
        const TransactionHistoryMultiReceiptSuccess('/tmp/a.pdf'),
      );
      expect(
        const TransactionHistoryMultiReceiptSuccess('/tmp/a.pdf'),
        isNot(const TransactionHistoryMultiReceiptSuccess('/tmp/b.pdf')),
      );
    });
  });

  group('$SettingsTaxReportState', () {
    test('Success props pin the taxReportPath', () {
      expect(
        const SettingsTaxReportSuccess('/tmp/tax.pdf'),
        const SettingsTaxReportSuccess('/tmp/tax.pdf'),
      );
      expect(
        const SettingsTaxReportSuccess('/tmp/tax.pdf'),
        isNot(const SettingsTaxReportSuccess('/tmp/other.pdf')),
      );
    });

    test('Initial and Loading are distinct singletons', () {
      expect(const SettingsTaxReportInitial(), const SettingsTaxReportInitial());
      expect(
        const SettingsTaxReportInitial(),
        isNot(const SettingsTaxReportLoading()),
      );
    });
  });
}
