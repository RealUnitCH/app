import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:realunit_wallet/packages/io/documents_directory_port.dart';
import 'package:realunit_wallet/packages/service/dfx/models/pdf/pdf_dto.dart';
import 'package:realunit_wallet/packages/service/dfx/real_unit_pdf_service.dart';
import 'package:realunit_wallet/screens/settings_tax_report/cubit/settings_tax_report_cubit.dart';
import 'package:realunit_wallet/styles/currency.dart';
import 'package:realunit_wallet/styles/language.dart';

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

  @override
  Future<Directory> getApplicationDocumentsDirectory() async => directory;
}

void main() {
  late _MockPdfService service;
  late Directory tempDir;
  late _FakeDocumentsDirectoryPort directoryPort;

  setUpAll(() {
    registerFallbackValue(Currency.chf);
    registerFallbackValue(Language.de);
    registerFallbackValue(DateTime(2026));
  });

  setUp(() {
    service = _MockPdfService();
    tempDir = Directory.systemTemp.createTempSync('tax_report_cubit_test_');
    directoryPort = _FakeDocumentsDirectoryPort(tempDir);
  });

  tearDown(() {
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  SettingsTaxReportCubit buildCubit() => SettingsTaxReportCubit(service, directory: directoryPort);

  group('$SettingsTaxReportCubit', () {
    test('initial state is SettingsTaxReportInitial', () {
      expect(buildCubit().state, isA<SettingsTaxReportInitial>());
    });

    test('default constructor uses production path provider adapter', () {
      // Sanity-check the default-wiring branch — no I/O performed.
      expect(SettingsTaxReportCubit(service), isNotNull);
    });

    test('generateTaxReport writes a PDF and emits Success with the file path', () async {
      final pdfBytes = utf8.encode('%PDF-1.4 fake');
      when(
        () => service.getBalanceReport(
          date: any(named: 'date'),
          currency: any(named: 'currency'),
          language: any(named: 'language'),
        ),
      ).thenAnswer((_) async => PdfDto(pdfData: base64Encode(pdfBytes)));

      final cubit = buildCubit();
      // expectLater verifies the Loading->Success emit sequence end-to-end.
      final emissions = expectLater(
        cubit.stream,
        emitsInOrder(<Matcher>[
          isA<SettingsTaxReportLoading>(),
          isA<SettingsTaxReportSuccess>(),
        ]),
      );

      await cubit.generateTaxReport(
        date: DateTime(2025, 12, 31),
        currency: Currency.chf,
        language: Language.de,
      );
      await emissions;

      expect(cubit.state, isA<SettingsTaxReportSuccess>());
      final success = cubit.state as SettingsTaxReportSuccess;
      expect(success.taxReportPath, '${tempDir.path}/balance_report_31_12_2025.pdf');
      expect(File(success.taxReportPath).existsSync(), isTrue);
      expect(File(success.taxReportPath).readAsBytesSync(), pdfBytes);
      expect(directoryPort.calls, 1);
    });

    test('generateTaxReport uses "now - 1 minute" UTC when the selected date is today', () async {
      DateTime? capturedDate;
      when(
        () => service.getBalanceReport(
          date: any(named: 'date'),
          currency: any(named: 'currency'),
          language: any(named: 'language'),
        ),
      ).thenAnswer((invocation) async {
        capturedDate = invocation.namedArguments[#date] as DateTime;
        return PdfDto(pdfData: base64Encode(<int>[1, 2, 3]));
      });

      final now = DateTime.now();
      final todayMidnight = DateTime(now.year, now.month, now.day);

      final cubit = buildCubit();
      await cubit.generateTaxReport(
        date: todayMidnight,
        currency: Currency.eur,
        language: Language.en,
      );

      expect(capturedDate, isNotNull);
      expect(capturedDate!.isUtc, isTrue);
      // Within the last 2 minutes – exact equality is too brittle because
      // the cubit recomputes `DateTime.now()` internally.
      final diff = DateTime.now().toUtc().difference(capturedDate!).inSeconds;
      expect(diff, lessThan(120));
      expect(diff, greaterThanOrEqualTo(60));
    });

    test('generateTaxReport uses end-of-day-local converted to UTC for past dates', () async {
      DateTime? capturedDate;
      when(
        () => service.getBalanceReport(
          date: any(named: 'date'),
          currency: any(named: 'currency'),
          language: any(named: 'language'),
        ),
      ).thenAnswer((invocation) async {
        capturedDate = invocation.namedArguments[#date] as DateTime;
        return PdfDto(pdfData: base64Encode(<int>[0]));
      });

      final cubit = buildCubit();
      await cubit.generateTaxReport(
        date: DateTime(2024, 6, 15),
        currency: Currency.chf,
        language: Language.de,
      );

      // The cubit constructs a local end-of-day DateTime and calls .toUtc()
      // on it — verify against the exact local→UTC conversion so the test is
      // timezone-stable on the CI runner.
      final expected = DateTime(2024, 6, 15, 23, 59, 59).toUtc();
      expect(capturedDate, isNotNull);
      expect(capturedDate!.isUtc, isTrue);
      expect(capturedDate, expected);
    });

    test('generateTaxReport emits Failure on service error', () async {
      when(
        () => service.getBalanceReport(
          date: any(named: 'date'),
          currency: any(named: 'currency'),
          language: any(named: 'language'),
        ),
      ).thenAnswer((_) async => throw Exception('network'));

      final cubit = buildCubit();
      await cubit.generateTaxReport(
        date: DateTime(2025, 12, 31),
        currency: Currency.chf,
        language: Language.de,
      );

      expect(cubit.state, isA<SettingsTaxReportFailure>());
      final failure = cubit.state as SettingsTaxReportFailure;
      expect(failure.message, contains('network'));
    });

    test('generateTaxReport emits Failure when file I/O throws', () async {
      // Point the cubit at a directory that does not exist so `writeAsBytes`
      // throws — this exercises the path that swallows file-system errors.
      final missing = Directory('${tempDir.path}/does-not-exist');
      final brokenPort = _FakeDocumentsDirectoryPort(missing);

      when(
        () => service.getBalanceReport(
          date: any(named: 'date'),
          currency: any(named: 'currency'),
          language: any(named: 'language'),
        ),
      ).thenAnswer((_) async => PdfDto(pdfData: base64Encode(<int>[1])));

      final cubit = SettingsTaxReportCubit(service, directory: brokenPort);
      await cubit.generateTaxReport(
        date: DateTime(2025, 12, 31),
        currency: Currency.chf,
        language: Language.de,
      );

      expect(cubit.state, isA<SettingsTaxReportFailure>());
    });

    test('does not emit Success when closed during service call', () async {
      final completer = Completer<PdfDto>();
      when(
        () => service.getBalanceReport(
          date: any(named: 'date'),
          currency: any(named: 'currency'),
          language: any(named: 'language'),
        ),
      ).thenAnswer((_) => completer.future);

      final cubit = buildCubit();
      final emitted = <SettingsTaxReportState>[];
      final sub = cubit.stream.listen(emitted.add);

      unawaited(
        cubit.generateTaxReport(
          date: DateTime(2025, 12, 31),
          currency: Currency.chf,
          language: Language.de,
        ),
      );
      await cubit.close();
      completer.complete(PdfDto(pdfData: base64Encode(<int>[1])));
      await sub.cancel();

      // Only Loading should have been observed before close — no Success.
      expect(emitted, [isA<SettingsTaxReportLoading>()]);
    });

    test('does not emit Failure after close', () async {
      final completer = Completer<PdfDto>();
      when(
        () => service.getBalanceReport(
          date: any(named: 'date'),
          currency: any(named: 'currency'),
          language: any(named: 'language'),
        ),
      ).thenAnswer((_) => completer.future);

      final cubit = buildCubit();
      unawaited(
        cubit.generateTaxReport(
          date: DateTime(2025, 12, 31),
          currency: Currency.chf,
          language: Language.de,
        ),
      );
      await cubit.close();
      completer.completeError(Exception('late'));

      // If emit fires after close, StateError is thrown by the framework.
    });
  });
}
