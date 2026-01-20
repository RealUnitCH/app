import 'dart:convert';
import 'dart:io';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:realunit_wallet/packages/service/dfx/real_unit_pdf_service.dart';
import 'package:realunit_wallet/styles/currency.dart';
import 'package:realunit_wallet/styles/language.dart';

part 'settings_tax_report_state.dart';

class SettingsTaxReportCubit extends Cubit<SettingsTaxReportState> {
  final RealUnitPdfService _pdfService;

  SettingsTaxReportCubit(RealUnitPdfService pdfService)
      : _pdfService = pdfService,
        super(const SettingsTaxReportInitial());

  Future<void> generateTaxReport({
    required DateTime date,
    required Currency currency,
    required Language language,
  }) async {
    try {
      emit(const SettingsTaxReportLoading());

      final response = await _pdfService.getBalanceReport(
        date: date,
        currency: currency,
        language: language,
      );
      final file = await _createFileFromBytes(response.pdfData, date);

      emit(SettingsTaxReportSuccess(file.path));
    } catch (e) {
      emit(SettingsTaxReportFailure(e.toString()));
    }
  }

  Future<File> _createFileFromBytes(String data, DateTime date) async {
    final bytes = base64Decode(data);
    final tempDir = await getTemporaryDirectory();
    final file =
        File('${tempDir.path}/balance_report_${DateFormat('dd_MM_yyyy').format(date)}.pdf');
    await file.writeAsBytes(bytes, flush: true);
    return file;
  }
}
