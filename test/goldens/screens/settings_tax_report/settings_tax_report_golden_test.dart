import 'package:bloc_test/bloc_test.dart';
import 'package:clock/clock.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:mocktail/mocktail.dart';
import 'package:realunit_wallet/packages/service/dfx/real_unit_pdf_service.dart';
import 'package:realunit_wallet/screens/settings/bloc/settings_bloc.dart';
import 'package:realunit_wallet/screens/settings_tax_report/cubit/settings_tax_report_cubit.dart';
import 'package:realunit_wallet/screens/settings_tax_report/settings_tax_report_page.dart';

import '../../../helper/helper.dart';

class _MockSettingsTaxReportCubit extends MockCubit<SettingsTaxReportState>
    implements SettingsTaxReportCubit {}

class _MockRealUnitPdfService extends Mock implements RealUnitPdfService {}

void main() {

  late MockSettingsBloc settingsBloc;
  late _MockSettingsTaxReportCubit taxReportCubit;

  setUp(() {
    settingsBloc = MockSettingsBloc();
    taxReportCubit = _MockSettingsTaxReportCubit();
    when(() => settingsBloc.state).thenReturn(const SettingsState());
    when(() => taxReportCubit.state).thenReturn(const SettingsTaxReportInitial());
  });

  setUpAll(() {
    final getIt = GetIt.instance;
    getIt.registerSingleton<RealUnitPdfService>(_MockRealUnitPdfService());
  });

  tearDownAll(() async {
    await GetIt.instance.reset();
  });

  group('$SettingsTaxReportPage', () {
    withClock(Clock.fixed(DateTime.utc(2026, 5, 23)), () {
      goldenTest(
        'default state',
        fileName: 'settings_tax_report_page_default',
        constraints: phoneConstraints,
        builder: () => wrapForGolden(
          MultiBlocProvider(
            providers: [
              BlocProvider<SettingsBloc>.value(value: settingsBloc),
              BlocProvider<SettingsTaxReportCubit>.value(value: taxReportCubit),
            ],
            child: SettingsTaxReportView(),
          ),
        ),
      );

      goldenTest(
        'loading',
        fileName: 'settings_tax_report_page_loading',
        constraints: phoneConstraints,
        // Loading state shows a CircularProgressIndicator that never
        // settles. See buy_golden_test.dart `payment info loading` for
        // the same workaround.
        pumpBeforeTest: pumpOnce,
        builder: () {
          when(() => taxReportCubit.state)
              .thenReturn(const SettingsTaxReportLoading());
          return wrapForGolden(
            MultiBlocProvider(
              providers: [
                BlocProvider<SettingsBloc>.value(value: settingsBloc),
                BlocProvider<SettingsTaxReportCubit>.value(value: taxReportCubit),
              ],
              child: SettingsTaxReportView(),
            ),
          );
        },
      );

      goldenTest(
        'failure',
        fileName: 'settings_tax_report_page_failure',
        constraints: phoneConstraints,
        builder: () {
          when(() => taxReportCubit.state).thenReturn(
            const SettingsTaxReportFailure(
              'Konnte Steuerausweis nicht generieren.',
            ),
          );
          return wrapForGolden(
            MultiBlocProvider(
              providers: [
                BlocProvider<SettingsBloc>.value(value: settingsBloc),
                BlocProvider<SettingsTaxReportCubit>.value(value: taxReportCubit),
              ],
              child: SettingsTaxReportView(),
            ),
          );
        },
      );
    });
  });
}
