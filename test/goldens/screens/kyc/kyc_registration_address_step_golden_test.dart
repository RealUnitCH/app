import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:mocktail/mocktail.dart';
import 'package:realunit_wallet/packages/service/dfx/dfx_country_service.dart';
import 'package:realunit_wallet/packages/service/dfx/models/country/country.dart';
import 'package:realunit_wallet/screens/kyc/steps/registration/cubits/registration_step/kyc_registration_step_cubit.dart';
import 'package:realunit_wallet/screens/kyc/steps/registration/steps/kyc_registration_address_step.dart';

import '../../../helper/helper.dart';

class _MockKycRegistrationStepCubit extends MockCubit<KycRegistrationStepState>
    implements KycRegistrationStepCubit {}

const _switzerland = Country(id: 41, symbol: 'CH', name: 'Switzerland', kycAllowed: true);
const _germany = Country(id: 49, symbol: 'DE', name: 'Germany', kycAllowed: true);

void main() {
  late _MockKycRegistrationStepCubit stepCubit;

  setUpAll(() {
    final countryService = MockDfxCountryService();
    when(() => countryService.getAllCountries())
        .thenAnswer((_) async => <Country>[_switzerland, _germany]);
    GetIt.instance.registerSingleton<DfxCountryService>(countryService);
  });

  tearDownAll(() async => GetIt.instance.reset());

  setUp(() {
    stepCubit = _MockKycRegistrationStepCubit();
    when(() => stepCubit.state).thenReturn(
      const KycRegistrationStepState(
        step: KycRegistrationStep.address,
        steps: [
          KycRegistrationStep.personal,
          KycRegistrationStep.address,
          KycRegistrationStep.taxResidence,
        ],
      ),
    );
  });

  group('$KycRegistrationAddressStep', () {
    goldenTest(
      'empty address form',
      fileName: 'kyc_registration_address_step_default',
      constraints: phoneConstraints,
      builder: () => wrapForGolden(
        BlocProvider<KycRegistrationStepCubit>.value(
          value: stepCubit,
          child: Scaffold(
            body: KycRegistrationAddressStep(
              addressStreetCtrl: TextEditingController(),
              addressNumberCtrl: TextEditingController(),
              postalCodeCtrl: TextEditingController(),
              cityCtrl: TextEditingController(),
              countryCtrl: ValueNotifier<Country?>(null),
            ),
          ),
        ),
      ),
    );
  });
}
