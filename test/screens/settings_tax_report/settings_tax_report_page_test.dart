import 'package:bloc_test/bloc_test.dart';
import 'package:clock/clock.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:realunit_wallet/screens/settings/bloc/settings_bloc.dart';
import 'package:realunit_wallet/screens/settings_tax_report/cubit/settings_tax_report_cubit.dart';
import 'package:realunit_wallet/screens/settings_tax_report/settings_tax_report_page.dart';

import '../../helper/helper.dart';

class _MockSettingsTaxReportCubit extends MockCubit<SettingsTaxReportState>
    implements SettingsTaxReportCubit {}

void main() {
  late MockSettingsBloc settingsBloc;
  late _MockSettingsTaxReportCubit taxReportCubit;

  setUp(() {
    settingsBloc = MockSettingsBloc();
    taxReportCubit = _MockSettingsTaxReportCubit();
    when(() => settingsBloc.state).thenReturn(const SettingsState());
    when(() => taxReportCubit.state)
        .thenReturn(const SettingsTaxReportInitial());
  });

  Widget buildSubject() => MultiBlocProvider(
        providers: [
          BlocProvider<SettingsBloc>.value(value: settingsBloc),
          BlocProvider<SettingsTaxReportCubit>.value(value: taxReportCubit),
        ],
        child: SettingsTaxReportView(),
      );

  group('$SettingsTaxReportView date default', () {
    testWidgets(
      'defaults the date field to the last completed year-end '
      '(31.12 of the previous year)',
      (tester) async {
        // `SettingsTaxReportView` field-initializes `_DatePickerModel`, whose
        // constructor reads `clock.now()`. The clock has to be pinned while
        // the widget tree is *constructed* — hence `withClock` wraps
        // `buildSubject()`, the same zone-scoping constraint the golden test
        // documents.
        await withClock(Clock.fixed(DateTime.utc(2026, 5, 23)), () async {
          await tester.pumpApp(buildSubject());
        });

        // The date field renders `dd.MM.yyyy` — the default must be the last
        // completed year-end, not today.
        expect(find.text('31.12.2025'), findsOneWidget);
        expect(find.text('23.05.2026'), findsNothing);
      },
    );

    testWidgets(
      'default rolls forward with the year (2027 -> 31.12.2026)',
      (tester) async {
        await withClock(Clock.fixed(DateTime.utc(2027, 1, 15)), () async {
          await tester.pumpApp(buildSubject());
        });

        expect(find.text('31.12.2026'), findsOneWidget);
      },
    );
  });
}
