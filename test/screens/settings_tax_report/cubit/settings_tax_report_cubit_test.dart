import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:realunit_wallet/packages/service/dfx/models/pdf/pdf_dto.dart';
import 'package:realunit_wallet/packages/service/dfx/real_unit_pdf_service.dart';
import 'package:realunit_wallet/screens/settings_tax_report/cubit/settings_tax_report_cubit.dart';
import 'package:realunit_wallet/styles/currency.dart';
import 'package:realunit_wallet/styles/language.dart';

class _MockPdfService extends Mock implements RealUnitPdfService {}

void main() {
  late _MockPdfService service;

  setUpAll(() {
    registerFallbackValue(Currency.chf);
    registerFallbackValue(Language.de);
    registerFallbackValue(DateTime(2026));
  });

  setUp(() {
    service = _MockPdfService();
  });

  group('$SettingsTaxReportCubit', () {
    test('initial state is SettingsTaxReportInitial', () {
      expect(
        SettingsTaxReportCubit(service).state,
        isA<SettingsTaxReportInitial>(),
      );
    });

    test('generateTaxReport emits Failure on service error', () async {
      when(() => service.getBalanceReport(
            date: any(named: 'date'),
            currency: any(named: 'currency'),
            language: any(named: 'language'),
          )).thenAnswer((_) async => throw Exception('network'));

      final cubit = SettingsTaxReportCubit(service);
      await cubit.generateTaxReport(
        date: DateTime(2025, 12, 31),
        currency: Currency.chf,
        language: Language.de,
      );

      expect(cubit.state, isA<SettingsTaxReportFailure>());
    });

    test('does not emit after close', () async {
      final completer = Completer<PdfDto>();
      when(() => service.getBalanceReport(
            date: any(named: 'date'),
            currency: any(named: 'currency'),
            language: any(named: 'language'),
          )).thenAnswer((_) => completer.future);

      final cubit = SettingsTaxReportCubit(service);
      unawaited(cubit.generateTaxReport(
        date: DateTime(2025, 12, 31),
        currency: Currency.chf,
        language: Language.de,
      ));
      await cubit.close();
      completer.completeError(Exception('late'));

      // If emit fires after close, StateError is thrown by the framework.
    });
  });
}
