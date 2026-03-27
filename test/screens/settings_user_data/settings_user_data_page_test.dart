import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:mocktail/mocktail.dart';
import 'package:realunit_wallet/generated/i18n.dart';
import 'package:realunit_wallet/packages/service/dfx/dfx_country_service.dart';
import 'package:realunit_wallet/packages/service/dfx/dfx_kyc_service.dart';
import 'package:realunit_wallet/packages/service/dfx/models/country/country.dart';
import 'package:realunit_wallet/packages/service/dfx/models/registration/registration_user_type.dart';
import 'package:realunit_wallet/packages/service/dfx/models/user/user_data.dart';
import 'package:realunit_wallet/packages/service/dfx/real_unit_wallet_service.dart';
import 'package:realunit_wallet/screens/settings_user_data/cubit/settings_user_data_cubit.dart';
import 'package:realunit_wallet/screens/settings_user_data/settings_user_data_page.dart';

import '../../helper/helper.dart';

class MockSettingsUserDataCubit extends MockCubit<SettingsUserDataState>
    implements SettingsUserDataCubit {}

class MockRealUnitWalletService extends Mock implements RealUnitWalletService {}

class MockDfxCountryService extends Mock implements DfxCountryService {}

class MockDfxKycService extends Mock implements DfxKycService {}

void main() {
  late SettingsUserDataCubit settingsUserDataCubit;

  setUp(() {
    settingsUserDataCubit = MockSettingsUserDataCubit();
    when(() => settingsUserDataCubit.state).thenReturn(const SettingsUserDataInitial());
    when(() => settingsUserDataCubit.getUserData()).thenAnswer((_) => Future.value());
  });

  void setupDependencyInjection() {
    final getIt = GetIt.instance;
    getIt.registerSingleton<RealUnitWalletService>(MockRealUnitWalletService());
    getIt.registerSingleton<DfxCountryService>(MockDfxCountryService());
    getIt.registerSingleton<DfxKycService>(MockDfxKycService());
  }

  setUpAll(() {
    setupDependencyInjection();
  });

  Widget buildSubject(Widget child) {
    return BlocProvider.value(
      value: settingsUserDataCubit,
      child: child,
    );
  }

  group('$SettingsUserDataPage', () {
    testWidgets('renders $SettingsUserDataView', (tester) async {
      await tester.pumpApp(const SettingsUserDataPage());

      expect(find.byType(SettingsUserDataView), findsOne);
    });
  });

  group('$SettingsUserDataView', () {
    testWidgets('renders initially correctly', (tester) async {
      await tester.pumpApp(buildSubject(const SettingsUserDataView()));

      expect(find.byType(SizedBox), findsOne);
    });

    testWidgets('renders correctly when loading user data', (tester) async {
      when(() => settingsUserDataCubit.state).thenReturn(const SettingsUserDataLoading());
      await tester.pumpApp(buildSubject(const SettingsUserDataView()));

      expect(find.byType(CupertinoActivityIndicator), findsOne);
    });

    testWidgets('renders correctly when loading user data failed', (tester) async {
      final errorMessage = 'not working bro';
      when(() => settingsUserDataCubit.state).thenReturn(SettingsUserDataFailure(errorMessage));

      await tester.pumpApp(buildSubject(const SettingsUserDataView()));

      expect(
        find.byWidgetPredicate((Widget widget) => widget is Text && widget.data == errorMessage),
        findsOne,
      );
    });

    testWidgets('renders correctly when user data loaded successfully', (tester) async {
      final userData = UserData(
        email: 'test-direct@dfx.swiss',
        name: 'Test Direct',
        type: RegistrationUserType.human,
        phoneNumber: '+41791234567',
        birthday: DateTime.now(),
        nationality: const Country(id: 41, symbol: 'CH', name: 'Switzerland'),
        addressStreet: 'Teststrasse',
        addressPostalCode: '8000',
        addressCity: 'Zurich',
        addressCountry: const Country(id: 41, symbol: 'CH', name: 'Switzerland'),
        swissTaxResidence: true,
        lang: 'DE',
      );

      when(() => settingsUserDataCubit.state).thenReturn(
        SettingsUserDataSuccess(userData: userData),
      );

      await tester.pumpApp(buildSubject(const SettingsUserDataView()));

      expect(
        find.byWidgetPredicate((Widget widget) => widget is Column && widget.children.length == 7),
        findsOne,
      );
    });

    testWidgets('renders correctly when user data was not found', (tester) async {
      when(() => settingsUserDataCubit.state).thenReturn(
        const SettingsUserDataSuccess(),
      );

      await tester.pumpApp(buildSubject(const SettingsUserDataView()));

      expect(
        find.byWidgetPredicate((Widget widget) => widget is Column && widget.children.length == 7),
        findsNothing,
      );
      expect(find.text(S.current.userDataNotFound), findsOne);
    });
  });
}
