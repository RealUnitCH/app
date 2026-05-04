import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:mocktail/mocktail.dart';
import 'package:realunit_wallet/packages/service/dfx/dfx_kyc_service.dart';
import 'package:realunit_wallet/screens/settings_user_data/subpages/edit_name/settings_edit_name_page.dart';
import 'package:realunit_wallet/screens/settings_user_data/subpages/edit_phone_number/cubit/settings_edit_phone_number_cubit.dart';
import 'package:realunit_wallet/screens/settings_user_data/subpages/edit_phone_number/settings_edit_phone_number_page.dart';
import 'package:realunit_wallet/widgets/buttons/app_filled_button.dart';
import 'package:realunit_wallet/widgets/form/phone_number_field.dart';

import '../../../helper/pump_app.dart';

class MockSettingsEditPhoneNumberCubit extends MockCubit<SettingsEditPhoneNumberState>
    implements SettingsEditPhoneNumberCubit {}

class MockDfxKycService extends Mock implements DfxKycService {}

void main() {
  late SettingsEditPhoneNumberCubit settingsEditPhoneNumberCubit;

  setUp(() {
    settingsEditPhoneNumberCubit = MockSettingsEditPhoneNumberCubit();
    when(
      () => settingsEditPhoneNumberCubit.state,
    ).thenReturn(const SettingsEditPhoneNumberInitial());
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
      value: settingsEditPhoneNumberCubit,
      child: child,
    );
  }

  group('$SettingsEditPhoneNumberPage', () {
    testWidgets('renders $SettingsEditPhoneNumberView', (tester) async {
      await tester.pumpApp(const SettingsEditPhoneNumberPage());

      expect(find.byType(SettingsEditPhoneNumberView), findsOne);
    });
  });

  group('$SettingsEditNameView', () {
    testWidgets('renders initially correctly', (tester) async {
      await tester.pumpApp(buildSubject(const SettingsEditPhoneNumberView()));

      expect(find.byType(PhoneNumberField), findsOne);
      expect(find.byType(AppFilledButton), findsOne);
      expect(find.byType(CupertinoActivityIndicator), findsNothing);
    });

    testWidgets('renders correctly when submitting', (tester) async {
      when(
        () => settingsEditPhoneNumberCubit.state,
      ).thenReturn(const SettingsEditPhoneNumberSubmitting());

      await tester.pumpApp(buildSubject(const SettingsEditPhoneNumberView()));

      expect(find.byType(PhoneNumberField), findsOne);
      expect(find.byType(AppFilledButton), findsOne);
      expect(find.byType(CupertinoActivityIndicator), findsOne);
    });

    testWidgets('renders correctly when submitting failed', (tester) async {
      final error = 'failed';
      when(
        () => settingsEditPhoneNumberCubit.state,
      ).thenReturn(SettingsEditPhoneNumberFailure(error));
      await tester.pumpApp(buildSubject(const SettingsEditPhoneNumberView()));

      expect(find.byType(PhoneNumberField), findsOne);
      expect(find.text(error), findsOne);
      expect(find.byType(AppFilledButton), findsOne);
      expect(find.byType(CupertinoActivityIndicator), findsNothing);
    });
  });
}
