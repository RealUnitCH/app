import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:realunit_wallet/packages/service/dfx/models/pdf/pdf_dto.dart';
import 'package:realunit_wallet/packages/service/dfx/real_unit_pdf_service.dart';
import 'package:realunit_wallet/screens/transaction_history/cubits/receipt/transaction_history_receipt_cubit.dart';
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

  group('$TransactionHistoryReceiptCubit', () {
    test('initial state is TransactionHistoryReceiptInitial', () {
      expect(
        TransactionHistoryReceiptCubit(service).state,
        isA<TransactionHistoryReceiptInitial>(),
      );
    });

    test('generateReceipt emits Failure on service error', () async {
      when(() => service.getTransactionReceipt(any(), currency: any(named: 'currency')))
          .thenAnswer((_) async => throw Exception('network'));

      final cubit = TransactionHistoryReceiptCubit(service);
      await cubit.generateReceipt('tx-1');

      expect(cubit.state, isA<TransactionHistoryReceiptFailure>());
    });

    test('does not emit after close', () async {
      final completer = Completer<PdfDto>();
      when(() => service.getTransactionReceipt(any(), currency: any(named: 'currency')))
          .thenAnswer((_) => completer.future);

      final cubit = TransactionHistoryReceiptCubit(service);
      unawaited(cubit.generateReceipt('tx-1'));
      await cubit.close();
      completer.completeError(Exception('late'));

      // If emit fires after close, StateError is thrown by the framework.
    });
  });
}
