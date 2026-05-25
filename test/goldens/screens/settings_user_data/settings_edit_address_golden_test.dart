import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:mocktail/mocktail.dart';
import 'package:realunit_wallet/packages/service/dfx/dfx_country_service.dart';
import 'package:realunit_wallet/packages/service/dfx/dfx_kyc_service.dart';
import 'package:realunit_wallet/packages/service/dfx/models/country/country.dart';
import 'package:realunit_wallet/screens/settings_user_data/subpages/edit_address/cubit/settings_edit_address_cubit.dart';
import 'package:realunit_wallet/screens/settings_user_data/subpages/edit_address/settings_edit_address_page.dart';

import '../../../helper/helper.dart';

class _MockSettingsEditAddressCubit extends MockCubit<SettingsEditAddressState>
    implements SettingsEditAddressCubit {}

class _MockDfxKycService extends Mock implements DfxKycService {}

void main() {
  const country = Country(
    id: 41,
    symbol: 'CH',
    name: 'Switzerland',
    kycAllowed: true,
  );

  late _MockSettingsEditAddressCubit cubit;
  late MockDfxCountryService countryService;

  setUp(() {
    cubit = _MockSettingsEditAddressCubit();
    countryService = MockDfxCountryService();
    when(() => cubit.state).thenReturn(const SettingsEditAddressReady('url'));
    when(() => countryService.getAllCountries())
        .thenAnswer((_) async => const [country]);

    final getIt = GetIt.instance;
    if (getIt.isRegistered<DfxCountryService>()) {
      getIt.unregister<DfxCountryService>();
    }
    getIt.registerSingleton<DfxCountryService>(countryService);
  });

  setUpAll(() {
    final getIt = GetIt.instance;
    getIt.registerSingleton<DfxKycService>(_MockDfxKycService());
  });

  tearDownAll(() async {
    await GetIt.instance.reset();
  });

  group('$SettingsEditAddressPage', () {
    goldenTest(
      'default ready state',
      fileName: 'settings_edit_address_page_default',
      constraints: phoneConstraints,
      builder: () => wrapForGolden(
        BlocProvider<SettingsEditAddressCubit>.value(
          value: cubit,
          child: const SettingsEditAddressView(),
        ),
      ),
    );
  });
}
