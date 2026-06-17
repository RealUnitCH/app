import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:mocktail/mocktail.dart';
import 'package:realunit_wallet/packages/service/dfx/dfx_country_service.dart';
import 'package:realunit_wallet/packages/service/dfx/dfx_kyc_service.dart';
import 'package:realunit_wallet/packages/service/dfx/models/country/country.dart';
import 'package:realunit_wallet/screens/settings_user_data/subpages/edit_address/cubit/settings_edit_address_cubit.dart';
import 'package:realunit_wallet/screens/settings_user_data/subpages/edit_address/settings_edit_address_page.dart';
import 'package:realunit_wallet/screens/settings_user_data/subpages/others/settings_edit_failure_page.dart';
import 'package:realunit_wallet/screens/settings_user_data/subpages/others/settings_edit_loading_page.dart';
import 'package:realunit_wallet/screens/settings_user_data/subpages/others/settings_edit_pending_page.dart';
import 'package:realunit_wallet/widgets/buttons/app_filled_button.dart';
import 'package:realunit_wallet/widgets/form/country_field.dart';
import 'package:realunit_wallet/widgets/form/file_picker_field.dart';
import 'package:realunit_wallet/widgets/form/labeled_text_field.dart';

import '../../../helper/pump_app.dart';

class MockSettingsEditAddressCubit extends MockCubit<SettingsEditAddressState>
    implements SettingsEditAddressCubit {}

class MockDfxKycService extends Mock implements DfxKycService {}

class MockDfxCountryService extends Mock implements DfxCountryService {}

void main() {
  late SettingsEditAddressCubit settingsEditAddressCubit;
  late MockDfxCountryService countryService;

  const country = Country(
    id: 41,
    symbol: 'CH',
    name: 'Switzerland',
    kycAllowed: true,
  );

  setUp(() {
    settingsEditAddressCubit = MockSettingsEditAddressCubit();
    when(() => settingsEditAddressCubit.state).thenReturn(const SettingsEditAddressInitial());
    when(() => countryService.getAllCountries()).thenAnswer((_) async => [country]);
  });

  void setupDependencyInjection() {
    final getIt = GetIt.instance;
    countryService = MockDfxCountryService();
    getIt.registerSingleton<DfxKycService>(MockDfxKycService());
    getIt.registerSingleton<DfxCountryService>(countryService);
  }

  setUpAll(() {
    setupDependencyInjection();
  });

  Widget buildSubject(Widget child) {
    return BlocProvider.value(
      value: settingsEditAddressCubit,
      child: child,
    );
  }

  group('$SettingsEditAddressPage', () {
    testWidgets('renders $SettingsEditAddressView', (tester) async {
      await tester.pumpApp(const SettingsEditAddressPage());

      expect(find.byType(SettingsEditAddressView), findsOne);
    });
  });

  group('$SettingsEditAddressView', () {
    testWidgets('renders initially correctly', (tester) async {
      await tester.pumpApp(buildSubject(const SettingsEditAddressView()));

      expect(find.byType(Scaffold), findsOne);
    });

    testWidgets('renders correctly when loading', (tester) async {
      when(() => settingsEditAddressCubit.state).thenReturn(const SettingsEditAddressLoading());

      await tester.pumpApp(buildSubject(const SettingsEditAddressView()));

      expect(find.byType(SettingsEditLoadingPage), findsOne);
    });

    testWidgets('renders correctly when pending', (tester) async {
      when(() => settingsEditAddressCubit.state).thenReturn(const SettingsEditAddressPending());

      await tester.pumpApp(buildSubject(const SettingsEditAddressView()));

      expect(find.byType(SettingsEditPendingPage), findsOne);
    });

    testWidgets('renders correctly when loading failed', (tester) async {
      when(
        () => settingsEditAddressCubit.state,
      ).thenReturn(const SettingsEditAddressFailure('failed'));

      await tester.pumpApp(buildSubject(const SettingsEditAddressView()));

      expect(find.byType(SettingsEditFailurePage), findsOne);
    });

    testWidgets('renders correctly when successfully loaded', (tester) async {
      when(() => settingsEditAddressCubit.state).thenReturn(const SettingsEditAddressReady('url'));

      await tester.pumpApp(buildSubject(const SettingsEditAddressView()));
      // Let the CountryField's country-list future resolve.
      await tester.pumpAndSettle();

      expect(find.byType(LabeledTextField), findsNWidgets(4));
      expect(find.byType(CountryField), findsOne);
      expect(find.byType(FilePickerField), findsOne);
      expect(find.byType(AppFilledButton), findsOne);
      expect(find.byType(CupertinoActivityIndicator), findsNothing);
    });

    testWidgets('postal code field uses a text keyboard for alphanumeric codes',
        (tester) async {
      // Foreign postal codes are alphanumeric (NL "1011 AB", UK "EC1A 1BB").
      // A number-only keyboard would make them impossible to type.
      when(() => settingsEditAddressCubit.state).thenReturn(const SettingsEditAddressReady('url'));

      await tester.pumpApp(buildSubject(const SettingsEditAddressView()));
      await tester.pumpAndSettle();

      final postalField = tester.widget<LabeledTextField>(
        find.byWidgetPredicate((w) => w is LabeledTextField && w.hintText == '8000'),
      );
      expect(postalField.keyboardType, TextInputType.text);
    });

    testWidgets('renders correctly when submitting', (tester) async {
      when(
        () => settingsEditAddressCubit.state,
      ).thenReturn(const SettingsEditAddressSubmitting('url'));

      await tester.pumpApp(buildSubject(const SettingsEditAddressView()));
      // Flush the CountryField's country-list future. pumpAndSettle is unusable
      // here: the submitting state shows a perpetually-animating spinner.
      await tester.pump();

      expect(find.byType(LabeledTextField), findsNWidgets(4));
      expect(find.byType(CountryField), findsOne);
      expect(find.byType(FilePickerField), findsOne);
      expect(find.byType(AppFilledButton), findsOne);
      expect(find.byType(CupertinoActivityIndicator), findsOne);
    });
  });
}
