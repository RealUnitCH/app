import 'package:alchemist/alchemist.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:mocktail/mocktail.dart';
import 'package:realunit_wallet/packages/service/dfx/dfx_country_service.dart';
import 'package:realunit_wallet/packages/service/dfx/models/country/country.dart';
import 'package:realunit_wallet/screens/kyc/cubits/kyc/kyc_cubit.dart';
import 'package:realunit_wallet/screens/kyc/steps/nationality/cubit/kyc_nationality/kyc_nationality_cubit.dart';
import 'package:realunit_wallet/screens/kyc/steps/nationality/kyc_nationality_page.dart';

import '../../../helper/helper.dart';

class _MockKycNationalityCubit extends MockCubit<KycNationalityState>
    implements KycNationalityCubit {}

class _MockKycCubit extends MockCubit<KycState> implements KycCubit {}

void main() {

  late _MockKycNationalityCubit kycNationalityCubit;
  late _MockKycCubit kycCubit;
  late MockDfxCountryService countryService;

  const country = Country(
    id: 41,
    symbol: 'CH',
    name: 'Switzerland',
    kycAllowed: true,
  );

  setUp(() {
    kycNationalityCubit = _MockKycNationalityCubit();
    kycCubit = _MockKycCubit();

    when(() => kycNationalityCubit.state)
        .thenReturn(const KycNationalityInitial());
    when(() => kycCubit.state).thenReturn(const KycInitial());
  });

  setUpAll(() {
    countryService = MockDfxCountryService();
    when(() => countryService.getAllCountries())
        .thenAnswer((_) async => const [country]);
    GetIt.instance.registerSingleton<DfxCountryService>(countryService);
  });

  tearDownAll(() async => GetIt.instance.reset());

  group('$KycNationalityView', () {
    goldenTest(
      'initial state',
      fileName: 'kyc_nationality_page_default',
      constraints: phoneConstraints,
      builder: () => wrapForGolden(
        MultiBlocProvider(
          providers: [
            BlocProvider<KycNationalityCubit>.value(value: kycNationalityCubit),
            BlocProvider<KycCubit>.value(value: kycCubit),
          ],
          child: const KycNationalityView(url: 'https://example.com'),
        ),
      ),
    );
  });
}
