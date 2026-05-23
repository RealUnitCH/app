import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:realunit_wallet/packages/io/documents_directory_port.dart';
import 'package:realunit_wallet/packages/service/dfx/models/pdf/pdf_dto.dart';
import 'package:realunit_wallet/packages/service/dfx/real_unit_pdf_service.dart';
import 'package:realunit_wallet/screens/transaction_history/cubits/multi_receipt/transaction_history_multi_receipt_cubit.dart';
import 'package:realunit_wallet/styles/currency.dart';

class _MockPdfService extends Mock implements RealUnitPdfService {}

/// Returns a real, writable [Directory] under `Directory.systemTemp`, so the
/// cubit's `File.writeAsBytes` path executes for-real without crossing the
/// `path_provider` platform channel.
class _FakeDocumentsDirectoryPort implements DocumentsDirectoryPort {
  _FakeDocumentsDirectoryPort(this.directory);

  final Directory directory;
  int calls = 0;

  @override
  Future<Directory> getTemporaryDirectory() async {
    calls++;
    return directory;
  }
}

void main() {
  late _MockPdfService service;
  late Directory tempDir;
  late _FakeDocumentsDirectoryPort directoryPort;

  setUpAll(() {
    registerFallbackValue(Currency.chf);
  });

  setUp(() {
    service = _MockPdfService();
    tempDir = Directory.systemTemp.createTempSync('multi_receipt_cubit_test_');
    directoryPort = _FakeDocumentsDirectoryPort(tempDir);
  });

  tearDown(() {
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  TransactionHistoryMultiReceiptCubit buildCubit() =>
      TransactionHistoryMultiReceiptCubit(service, directory: directoryPort);

  group('$TransactionHistoryMultiReceiptCubit', () {
    test('initial state is TransactionHistoryMultiReceiptInitial', () {
      expect(buildCubit().state, isA<TransactionHistoryMultiReceiptInitial>());
    });

    test('default constructor uses production path provider adapter', () {
      expect(TransactionHistoryMultiReceiptCubit(service), isNotNull);
    });

    test('generateReceipt writes the PDF and emits Success with the file path', () async {
      final pdfBytes = utf8.encode('%PDF-1.4 fake-multi');
      when(
        () => service.getTransactionsReceipt(any(), currency: any(named: 'currency')),
      ).thenAnswer((_) async => PdfDto(pdfData: base64Encode(pdfBytes)));

      final cubit = buildCubit();
      final emissions = expectLater(
        cubit.stream,
        emitsInOrder(<Matcher>[
          isA<TransactionHistoryMultiReceiptLoading>(),
          isA<TransactionHistoryMultiReceiptSuccess>(),
        ]),
      );

      await cubit.generateReceipt(['tx-1', 'tx-2'], currency: Currency.eur);
      await emissions;

      expect(cubit.state, isA<TransactionHistoryMultiReceiptSuccess>());
      final success = cubit.state as TransactionHistoryMultiReceiptSuccess;
      expect(success.receiptPath, '${tempDir.path}/receipt.pdf');
      expect(File(success.receiptPath).existsSync(), isTrue);
      expect(File(success.receiptPath).readAsBytesSync(), pdfBytes);
      expect(directoryPort.calls, 1);
      verify(
        () => service.getTransactionsReceipt(['tx-1', 'tx-2'], currency: Currency.eur),
      ).called(1);
    });

    test('generateReceipt uses Currency.chf as default', () async {
      when(
        () => service.getTransactionsReceipt(any(), currency: any(named: 'currency')),
      ).thenAnswer((_) async => PdfDto(pdfData: base64Encode(<int>[1])));

      final cubit = buildCubit();
      await cubit.generateReceipt(['tx-1']);

      verify(() => service.getTransactionsReceipt(['tx-1'], currency: Currency.chf)).called(1);
    });

    test('generateReceipt emits Failure on service error', () async {
      when(
        () => service.getTransactionsReceipt(any(), currency: any(named: 'currency')),
      ).thenAnswer((_) async => throw Exception('network'));

      final cubit = buildCubit();
      await cubit.generateReceipt(['tx-1', 'tx-2']);

      expect(cubit.state, isA<TransactionHistoryMultiReceiptFailure>());
      final failure = cubit.state as TransactionHistoryMultiReceiptFailure;
      expect(failure.message, contains('network'));
    });

    test('generateReceipt emits Failure when the directory is missing', () async {
      final missing = Directory('${tempDir.path}/does-not-exist');
      final brokenPort = _FakeDocumentsDirectoryPort(missing);

      when(
        () => service.getTransactionsReceipt(any(), currency: any(named: 'currency')),
      ).thenAnswer((_) async => PdfDto(pdfData: base64Encode(<int>[1])));

      final cubit = TransactionHistoryMultiReceiptCubit(service, directory: brokenPort);
      await cubit.generateReceipt(['tx-1']);

      expect(cubit.state, isA<TransactionHistoryMultiReceiptFailure>());
    });

    test('does not emit Success when closed during service call', () async {
      final completer = Completer<PdfDto>();
      when(
        () => service.getTransactionsReceipt(any(), currency: any(named: 'currency')),
      ).thenAnswer((_) => completer.future);

      final cubit = buildCubit();
      unawaited(cubit.generateReceipt(['tx-1']));
      await cubit.close();
      completer.complete(PdfDto(pdfData: base64Encode(<int>[1])));
    });

    test('does not emit Failure after close', () async {
      final completer = Completer<PdfDto>();
      when(
        () => service.getTransactionsReceipt(any(), currency: any(named: 'currency')),
      ).thenAnswer((_) => completer.future);

      final cubit = buildCubit();
      unawaited(cubit.generateReceipt(['tx-1']));
      await cubit.close();
      completer.completeError(Exception('late'));
    });
  });
}
