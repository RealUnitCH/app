import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:realunit_wallet/packages/service/dfx/models/pdf/pdf_dto.dart';
import 'package:realunit_wallet/packages/service/dfx/real_unit_pdf_service.dart';
import 'package:realunit_wallet/screens/transaction_history/cubits/multi_receipt/transaction_history_multi_receipt_cubit.dart';
import 'package:realunit_wallet/styles/currency.dart';

class _MockPdfService extends Mock implements RealUnitPdfService {}

void main() {
  late _MockPdfService service;

  setUpAll(() {
    registerFallbackValue(Currency.chf);
  });

  setUp(() {
    service = _MockPdfService();
  });

  group('$TransactionHistoryMultiReceiptCubit', () {
    test('initial state is TransactionHistoryMultiReceiptInitial', () {
      expect(
        TransactionHistoryMultiReceiptCubit(service).state,
        isA<TransactionHistoryMultiReceiptInitial>(),
      );
    });

    test('generateReceipt emits Failure on service error', () async {
      when(() => service.getTransactionsReceipt(any(), currency: any(named: 'currency')))
          .thenAnswer((_) async => throw Exception('network'));

      final cubit = TransactionHistoryMultiReceiptCubit(service);
      await cubit.generateReceipt(['tx-1', 'tx-2']);

      expect(cubit.state, isA<TransactionHistoryMultiReceiptFailure>());
    });

    test('does not emit after close', () async {
      final completer = Completer<PdfDto>();
      when(() => service.getTransactionsReceipt(any(), currency: any(named: 'currency')))
          .thenAnswer((_) => completer.future);

      final cubit = TransactionHistoryMultiReceiptCubit(service);
      unawaited(cubit.generateReceipt(['tx-1']));
      await cubit.close();
      completer.completeError(Exception('late'));

      // If emit fires after close, StateError is thrown by the framework.
    });
  });
}
