import 'package:alchemist/alchemist.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:mocktail/mocktail.dart';
import 'package:realunit_wallet/packages/service/dfx/dfx_country_service.dart';
import 'package:realunit_wallet/packages/service/dfx/dfx_kyc_service.dart';
import 'package:realunit_wallet/packages/service/dfx/models/country/country.dart';
import 'package:realunit_wallet/packages/service/dfx/models/registration/registration_user_type.dart';
import 'package:realunit_wallet/packages/service/dfx/models/user/user_data.dart';
import 'package:realunit_wallet/packages/service/dfx/real_unit_wallet_service.dart';
import 'package:realunit_wallet/screens/settings_user_data/cubit/settings_user_data_cubit.dart';
import 'package:realunit_wallet/screens/settings_user_data/settings_user_data_page.dart';

import '../../../helper/helper.dart';

class _MockSettingsUserDataCubit extends MockCubit<SettingsUserDataState>
    implements SettingsUserDataCubit {}

class _MockRealUnitWalletService extends Mock implements RealUnitWalletService {}

class _MockDfxCountryService extends Mock implements DfxCountryService {}

class _MockDfxKycService extends Mock implements DfxKycService {}

void main() {
  const phoneConstraints = BoxConstraints.tightFor(width: 390, height: 844);

  late _MockSettingsUserDataCubit cubit;

  setUp(() {
    cubit = _MockSettingsUserDataCubit();
    final userData = UserData(
      email: 'test-direct@dfx.swiss',
      name: 'Test Direct',
      type: RegistrationUserType.human,
      phoneNumber: '+41791234567',
      birthday: DateTime.utc(1990, 1, 1),
      nationality: const Country(
        id: 41,
        symbol: 'CH',
        name: 'Switzerland',
        kycAllowed: true,
      ),
      addressStreet: 'Teststrasse 1',
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
    when(() => cubit.state).thenReturn(
      SettingsUserDataSuccess(userData: userData),
    );
    when(() => cubit.getUserData()).thenAnswer((_) => Future.value());
  });

  setUpAll(() {
    final getIt = GetIt.instance;
    getIt.registerSingleton<RealUnitWalletService>(_MockRealUnitWalletService());
    getIt.registerSingleton<DfxCountryService>(_MockDfxCountryService());
    getIt.registerSingleton<DfxKycService>(_MockDfxKycService());
  });

  tearDownAll(() async {
    await GetIt.instance.reset();
  });

  group('$SettingsUserDataPage', () {
    goldenTest(
      'default state with user data loaded',
      fileName: 'settings_user_data_page_default',
      constraints: phoneConstraints,
      builder: () => wrapForGolden(
        BlocProvider<SettingsUserDataCubit>.value(
          value: cubit,
          child: const SettingsUserDataView(),
        ),
      ),
    );
  });
}
