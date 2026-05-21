import 'dart:convert';
import 'dart:io';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:path_provider/path_provider.dart';
import 'package:realunit_wallet/packages/service/dfx/real_unit_pdf_service.dart';
import 'package:realunit_wallet/styles/currency.dart';

part 'transaction_history_receipt_state.dart';

class TransactionHistoryReceiptCubit extends Cubit<TransactionHistoryReceiptState> {
  final RealUnitPdfService _pdfService;

  TransactionHistoryReceiptCubit(RealUnitPdfService pdfService)
    : _pdfService = pdfService,
      super(const TransactionHistoryReceiptInitial());

  Future<void> generateReceipt(String txId, {Currency currency = Currency.chf}) async {
    try {
      emit(const TransactionHistoryReceiptLoading());

      final response = await _pdfService.getTransactionReceipt(txId, currency: currency);
      if (isClosed) return;
      final file = await _createFileFromBytes(response.pdfData, txId);
      if (isClosed) return;

      emit(TransactionHistoryReceiptSuccess(file.path));
    } catch (e) {
      if (isClosed) return;
      emit(TransactionHistoryReceiptFailure(e.toString()));
    }
  }

  Future<File> _createFileFromBytes(String data, String dfxId) async {
    final bytes = base64Decode(data);
    final tempDir = await getTemporaryDirectory();
    final file = File('${tempDir.path}/receipt_$dfxId.pdf');
    await file.writeAsBytes(bytes, flush: true);
    return file;
  }
}
