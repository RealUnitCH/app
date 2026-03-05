import 'dart:convert';
import 'dart:io';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:path_provider/path_provider.dart';
import 'package:realunit_wallet/packages/service/dfx/real_unit_pdf_service.dart';
import 'package:realunit_wallet/styles/currency.dart';

part 'transaction_history_multi_receipt_state.dart';

class TransactionHistoryMultiReceiptCubit extends Cubit<TransactionHistoryMultiReceiptState> {
  final RealUnitPdfService _pdfService;

  TransactionHistoryMultiReceiptCubit(RealUnitPdfService pdfService)
    : _pdfService = pdfService,
      super(const TransactionHistoryMultiReceiptInitial());

  Future<void> generateReceipt(List<String> ids, {Currency currency = Currency.chf}) async {
    try {
      emit(const TransactionHistoryMultiReceiptLoading());

      final response = await _pdfService.getTransactionsReceipt(ids, currency: currency);
      final file = await _createFileFromBytes(response.pdfData);

      emit(TransactionHistoryMultiReceiptSuccess(file.path));
    } catch (e) {
      emit(TransactionHistoryMultiReceiptFailure(e.toString()));
    }
  }

  Future<File> _createFileFromBytes(String data) async {
    final bytes = base64Decode(data);
    final tempDir = await getTemporaryDirectory();
    final file = File('${tempDir.path}/receipt.pdf');
    await file.writeAsBytes(bytes, flush: true);
    return file;
  }
}
