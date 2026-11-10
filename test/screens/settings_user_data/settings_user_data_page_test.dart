import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:realunit_wallet/generated/i18n.dart';
import 'package:realunit_wallet/packages/service/dfx/dfx_country_service.dart';
import 'package:realunit_wallet/packages/service/dfx/dfx_kyc_service.dart';
import 'package:realunit_wallet/packages/service/dfx/models/country/country.dart';
import 'package:realunit_wallet/packages/service/dfx/models/registration/registration_user_type.dart';
import 'package:realunit_wallet/packages/service/dfx/models/user/user_data.dart';
import 'package:realunit_wallet/packages/service/dfx/real_unit_registration_service.dart';
import 'package:realunit_wallet/screens/settings_user_data/cubit/settings_user_data_cubit.dart';
import 'package:realunit_wallet/screens/settings_user_data/settings_user_data_page.dart';
import 'package:realunit_wallet/setup/routing/routes/app_routes.dart';
import 'package:realunit_wallet/widgets/buttons/app_filled_button.dart';

import '../../helper/helper.dart';

class MockSettingsUserDataCubit extends MockCubit<SettingsUserDataState>
    implements SettingsUserDataCubit {}

class MockRealUnitRegistrationService extends Mock implements RealUnitRegistrationService {}

class MockDfxKycService extends Mock implements DfxKycService {}

const _behaviorUserData = UserData(
  email: 'test-direct@dfx.swiss',
  name: 'Test Direct',
  type: RegistrationUserType.human,
  phoneNumber: '+41791234567',
  birthday: null,
  nationality: Country(id: 41, symbol: 'CH', name: 'Switzerland', kycAllowed: true),
  addressStreet: 'Teststrasse',
  addressPostalCode: '8000',
  addressCity: 'Zurich',
  addressCountry: Country(id: 41, symbol: 'CH', name: 'Switzerland', kycAllowed: true),
  swissTaxResidence: true,
  lang: 'DE',
);

void main() {
  late SettingsUserDataCubit settingsUserDataCubit;

  setUp(() {
    settingsUserDataCubit = MockSettingsUserDataCubit();
    when(() => settingsUserDataCubit.state).thenReturn(const SettingsUserDataInitial());
    when(() => settingsUserDataCubit.getUserData()).thenAnswer((_) => Future.value());
  });

  void setupDependencyInjection() {
    final getIt = GetIt.instance;
    getIt.registerSingleton<RealUnitRegistrationService>(MockRealUnitRegistrationService());
    getIt.registerSingleton<DfxCountryService>(fixtureCountryService());
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
      when(() => settingsUserDataCubit.state).thenReturn(const SettingsUserDataFailure());

      await tester.pumpApp(buildSubject(const SettingsUserDataView()));

      expect(find.text(S.current.userDataLoadFailed), findsOne);
    });

    testWidgets('renders correctly when user data loaded successfully', (tester) async {
      final userData = UserData(
        email: 'test-direct@dfx.swiss',
        name: 'Test Direct',
        type: RegistrationUserType.human,
        phoneNumber: '+41791234567',
        birthday: DateTime.now(),
        nationality: const Country(
          id: 41,
          symbol: 'CH',
          name: 'Switzerland',
          kycAllowed: true,
        ),
        addressStreet: 'Teststrasse',
        addressPostalCode: '8000',
        addressCity: 'Zurich',
        addressCountry: const Country(
          id: 41,
          symbol: 'CH',
          name: 'Switzerland',
          kycAllowed: true,
        ),
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

    testWidgets('hides the birthday row when no birthday is on record', (tester) async {
      const userData = UserData(
        email: 'test-direct@dfx.swiss',
        name: 'Test Direct',
        type: RegistrationUserType.human,
        phoneNumber: '+41791234567',
        birthday: null,
        nationality: Country(
          id: 41,
          symbol: 'CH',
          name: 'Switzerland',
          kycAllowed: true,
        ),
        addressStreet: 'Teststrasse',
        addressPostalCode: '8000',
        addressCity: 'Zurich',
        addressCountry: Country(
          id: 41,
          symbol: 'CH',
          name: 'Switzerland',
          kycAllowed: true,
        ),
        swissTaxResidence: true,
        lang: 'DE',
      );

      when(() => settingsUserDataCubit.state).thenReturn(
        const SettingsUserDataSuccess(userData: userData),
      );

      await tester.pumpApp(buildSubject(const SettingsUserDataView()));

      expect(find.text(S.current.birthday), findsNothing);
      expect(find.text('Test Direct'), findsOne);
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

    group('share-register name signing action', () {
      testWidgets('button is visible when the API signing gate is true', (tester) async {
        when(() => settingsUserDataCubit.state).thenReturn(
          const SettingsUserDataSuccess(
            userData: _behaviorUserData,
            shareRegisterNameSigningRequired: true,
          ),
        );
        await tester.pumpApp(buildSubject(const SettingsUserDataView()));
        expect(find.text(S.current.shareRegisterNameAction), findsOne);
      });

      testWidgets('button is hidden when the API signing gate is false', (tester) async {
        when(() => settingsUserDataCubit.state).thenReturn(
          const SettingsUserDataSuccess(userData: _behaviorUserData),
        );
        await tester.pumpApp(buildSubject(const SettingsUserDataView()));
        expect(find.text(S.current.shareRegisterNameAction), findsNothing);
      });

      testWidgets('tap opens /kyc and refreshes user data after returning', (tester) async {
        when(() => settingsUserDataCubit.state).thenReturn(
          const SettingsUserDataSuccess(
            userData: _behaviorUserData,
            shareRegisterNameSigningRequired: true,
          ),
        );

        final router = GoRouter(
          initialLocation: '/settings/userData',
          routes: [
            GoRoute(
              path: '/settings/userData',
              builder: (_, _) => buildSubject(const SettingsUserDataView()),
            ),
            GoRoute(
              name: AppRoutes.kyc,
              path: '/kyc',
              builder: (_, _) => Scaffold(
                appBar: AppBar(title: const Text('KYC')),
                body: const Text('kyc destination'),
              ),
            ),
          ],
        );
        addTearDown(router.dispose);

        await tester.pumpWidget(
          MaterialApp.router(
            routerConfig: router,
            localizationsDelegates: const [
              S.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
            ],
            supportedLocales: S.delegate.supportedLocales,
          ),
        );
        await tester.pumpAndSettle();

        await expectFullyTappable(
          tester,
          find.byType(AppFilledButton),
          within: find.byType(SettingsUserDataView),
          reason: 'share-register name CTA not tappable',
        );
        await tester.pumpAndSettle();
        expect(find.text('kyc destination'), findsOne);
        verifyNever(() => settingsUserDataCubit.getUserData());

        router.pop();
        await tester.pumpAndSettle();

        expect(find.byType(SettingsUserDataView), findsOne);
        verify(() => settingsUserDataCubit.getUserData()).called(1);
      });
    });
  });
}
