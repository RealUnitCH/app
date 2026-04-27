import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:mocktail/mocktail.dart';
import 'package:realunit_wallet/packages/service/dfx/dfx_kyc_service.dart';
import 'package:realunit_wallet/screens/settings_user_data/subpages/edit_name/cubit/settings_edit_name_cubit.dart';
import 'package:realunit_wallet/screens/settings_user_data/subpages/edit_name/settings_edit_name_page.dart';
import 'package:realunit_wallet/screens/settings_user_data/subpages/others/settings_edit_failure_page.dart';
import 'package:realunit_wallet/screens/settings_user_data/subpages/others/settings_edit_loading_page.dart';
import 'package:realunit_wallet/screens/settings_user_data/subpages/others/settings_edit_pending_page.dart';
import 'package:realunit_wallet/screens/settings_user_data/subpages/others/settings_edit_requires_tfa_page.dart';
import 'package:realunit_wallet/widgets/form/file_picker_field.dart';
import 'package:realunit_wallet/widgets/form/labeled_text_field.dart';

import '../../../helper/pump_app.dart';

class MockSettingsEditNameCubit extends MockCubit<SettingsEditNameState>
    implements SettingsEditNameCubit {}

class MockDfxKycService extends Mock implements DfxKycService {}

void main() {
  late SettingsEditNameCubit settingsEditNameCubit;

  setUp(() {
    settingsEditNameCubit = MockSettingsEditNameCubit();
    when(() => settingsEditNameCubit.state).thenReturn(const SettingsEditNameInitial());
  });

  void setupDependencyInjection() {
    final getIt = GetIt.instance;
    getIt.registerSingleton<DfxKycService>(MockDfxKycService());
  }

  setUpAll(() {
    setupDependencyInjection();
  });

  Widget buildSubject(Widget child) {
    return BlocProvider.value(
      value: settingsEditNameCubit,
      child: child,
    );
  }

  group('$SettingsEditNamePage', () {
    testWidgets('renders $SettingsEditNameView', (tester) async {
      await tester.pumpApp(const SettingsEditNamePage());

      expect(find.byType(SettingsEditNameView), findsOne);
    });
  });

  group('$SettingsEditNameView', () {
    testWidgets('renders initially correctly', (tester) async {
      await tester.pumpApp(buildSubject(const SettingsEditNameView()));

      expect(find.byType(Scaffold), findsOne);
    });

    testWidgets('renders correctly when loading', (tester) async {
      when(() => settingsEditNameCubit.state).thenReturn(const SettingsEditNameLoading());

      await tester.pumpApp(buildSubject(const SettingsEditNameView()));

      expect(find.byType(SettingsEditLoadingPage), findsOne);
    });

    testWidgets('renders correctly when pending', (tester) async {
      when(() => settingsEditNameCubit.state).thenReturn(const SettingsEditNamePending());

      await tester.pumpApp(buildSubject(const SettingsEditNameView()));

      expect(find.byType(SettingsEditPendingPage), findsOne);
    });

    testWidgets('renders correctly when loading failed', (tester) async {
      when(() => settingsEditNameCubit.state).thenReturn(const SettingsEditNameFailure('failed'));

      await tester.pumpApp(buildSubject(const SettingsEditNameView()));

      expect(find.byType(SettingsEditFailurePage), findsOne);
    });

    testWidgets('renders correctly when 2FA is required', (tester) async {
      when(() => settingsEditNameCubit.state).thenReturn(const SettingsEditNameRequiresTfa());

      await tester.pumpApp(buildSubject(const SettingsEditNameView()));

      expect(find.byType(SettingsEditRequiresTfaPage), findsOne);
    });

    testWidgets('renders correctly when successfully loaded', (tester) async {
      when(() => settingsEditNameCubit.state).thenReturn(const SettingsEditNameReady('url'));

      await tester.pumpApp(buildSubject(const SettingsEditNameView()));

      expect(find.byType(LabeledTextField), findsNWidgets(2));
      expect(find.byType(FilePickerField), findsOne);
      expect(find.byType(FilledButton), findsOne);
      expect(find.byType(CupertinoActivityIndicator), findsNothing);
    });

    testWidgets('renders correctly when submitting', (tester) async {
      when(() => settingsEditNameCubit.state).thenReturn(const SettingsEditNameSubmitting('url'));

      await tester.pumpApp(buildSubject(const SettingsEditNameView()));

      expect(find.byType(LabeledTextField), findsNWidgets(2));
      expect(find.byType(FilePickerField), findsOne);
      expect(find.byType(FilledButton), findsOne);
      expect(find.byType(CupertinoActivityIndicator), findsOne);
    });
  });
}
