import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:realunit_wallet/packages/service/dfx/exceptions/bitbox_exception.dart';
import 'package:realunit_wallet/packages/service/dfx/models/registration/kyc/kyc_personal_data.dart';
import 'package:realunit_wallet/packages/service/dfx/models/registration/registration.dart';
import 'package:realunit_wallet/packages/service/dfx/models/registration/registration_status.dart';
import 'package:realunit_wallet/packages/service/dfx/models/user/dto/real_unit_user_data_dto.dart';
import 'package:realunit_wallet/packages/service/dfx/real_unit_registration_service.dart';
import 'package:realunit_wallet/screens/kyc/steps/register/cubits/kyc_register_cubit.dart';

class _MockRegistrationService extends Mock implements RealUnitRegistrationService {}

class _FakeRegistration extends Fake implements Registration {}

const _kycData = KycPersonalData(
  accountType: KycAccountType.personal,
  firstName: 'Ada',
  lastName: 'Lovelace',
  phone: '+41790000000',
  address: KycAddress(street: 'S', zip: '8000', city: 'Zurich', country: 41),
);

const _userData = RealUnitUserDataDto(
  email: 'ada@example.com',
  name: 'Ada Lovelace',
  type: 'HUMAN',
  phoneNumber: '+41790000000',
  birthday: '1815-12-10',
  nationality: 'CH',
  addressStreet: 'S',
  addressPostalCode: '8000',
  addressCity: 'Zurich',
  addressCountry: 'CH',
  swissTaxResidence: true,
  lang: 'de',
  kycData: _kycData,
);

// Same shape as `_userData`, but with one required field cleared — exercises
// the defensive Profile-Incomplete guard. The cubit must not invoke the
// registration service in this branch.
const _kycDataMissingPhone = KycPersonalData(
  accountType: KycAccountType.personal,
  firstName: 'Ada',
  lastName: 'Lovelace',
  phone: '',
  address: KycAddress(street: 'S', zip: '8000', city: 'Zurich', country: 41),
);

const _userDataMissingPhone = RealUnitUserDataDto(
  email: 'ada@example.com',
  name: 'Ada Lovelace',
  type: 'HUMAN',
  phoneNumber: '+41790000000',
  birthday: '1815-12-10',
  nationality: 'CH',
  addressStreet: 'S',
  addressPostalCode: '8000',
  addressCity: 'Zurich',
  addressCountry: 'CH',
  swissTaxResidence: true,
  lang: 'de',
  kycData: _kycDataMissingPhone,
);

// Same shape as `_userData`, but with the address country set to its int
// default (0). Prefills that arrive this way previously bypassed the
// profile-complete guard and produced a server 400 on submit — the cubit
// must now route to ProfileIncomplete.
const _kycDataCountryZero = KycPersonalData(
  accountType: KycAccountType.personal,
  firstName: 'Ada',
  lastName: 'Lovelace',
  phone: '+41790000000',
  address: KycAddress(street: 'S', zip: '8000', city: 'Zurich', country: 0),
);

const _userDataCountryZero = RealUnitUserDataDto(
  email: 'ada@example.com',
  name: 'Ada Lovelace',
  type: 'HUMAN',
  phoneNumber: '+41790000000',
  birthday: '1815-12-10',
  nationality: 'CH',
  addressStreet: 'S',
  addressPostalCode: '8000',
  addressCity: 'Zurich',
  addressCountry: 'CH',
  swissTaxResidence: true,
  lang: 'de',
  kycData: _kycDataCountryZero,
);

// Empty email — flows into the EIP-712 envelope, so a server validation
// would reject it. The cubit must route to ProfileIncomplete instead of
// submitting and 400-ing.
const _userDataMissingEmail = RealUnitUserDataDto(
  email: '',
  name: 'Ada Lovelace',
  type: 'HUMAN',
  phoneNumber: '+41790000000',
  birthday: '1815-12-10',
  nationality: 'CH',
  addressStreet: 'S',
  addressPostalCode: '8000',
  addressCity: 'Zurich',
  addressCountry: 'CH',
  swissTaxResidence: true,
  lang: 'de',
  kycData: _kycData,
);

void main() {
  late _MockRegistrationService registrationService;

  setUpAll(() {
    registerFallbackValue(_FakeRegistration());
  });

  setUp(() {
    registrationService = _MockRegistrationService();
  });

  // Constructor seeds the userData straight into `Ready` — no fetch round-trip
  // is performed by the cubit. The parent `KycCubit` has already produced this
  // value as part of its routing decision.
  KycRegisterCubit build(RealUnitUserDataDto userData) =>
      KycRegisterCubit(registrationService, userData);

  group('initial state', () {
    test('cubit starts in Ready(userData) with whatever the parent handed in', () {
      final cubit = build(_userData);
      expect(cubit.state, const KycRegisterReady(_userData));
    });

    test('cubit starts in ProfileIncomplete when required fields are missing', () {
      final cubit = build(_userDataMissingPhone);
      expect(cubit.state, const KycRegisterProfileIncomplete());
    });

    test('cubit starts in ProfileIncomplete when address.country is the unset int default (0)', () {
      // Previously bypassed the guard because the predicate only checked
      // the addressCountry string field. Drives the new `address.country
      // != 0` branch.
      final cubit = build(_userDataCountryZero);
      expect(cubit.state, const KycRegisterProfileIncomplete());
    });

    test('cubit starts in ProfileIncomplete when email is empty', () {
      // Email is part of the EIP-712 envelope; an empty value used to
      // submit and 400 on the server. Drives the new `email.trim()
      // .isNotEmpty` branch.
      final cubit = build(_userDataMissingEmail);
      expect(cubit.state, const KycRegisterProfileIncomplete());
    });
  });

  group('submit', () {
    blocTest<KycRegisterCubit, KycRegisterState>(
      'completeRegistration succeeds → Submitting → Success',
      setUp: () {
        when(() => registrationService.completeRegistration(any()))
            .thenAnswer((_) async => RegistrationStatus.completed);
      },
      build: () => build(_userData),
      act: (c) => c.submit(_userData),
      expect: () => [
        const KycRegisterSubmitting(_userData),
        const KycRegisterSuccess(),
      ],
      verify: (_) {
        // Wire-level call unchanged: still POST /v1/realunit/register/complete
        // via `completeRegistration`.
        verify(() => registrationService.completeRegistration(any())).called(1);
      },
    );

    blocTest<KycRegisterCubit, KycRegisterState>(
      'completeRegistration throws BitboxNotConnectedException → BitboxRequired (recoverable)',
      setUp: () {
        when(() => registrationService.completeRegistration(any()))
            .thenThrow(const BitboxNotConnectedException());
      },
      build: () => build(_userData),
      act: (c) => c.submit(_userData),
      // The page listens for `KycRegisterBitboxRequired` and surfaces the
      // existing reconnect sheet — collapsing this into `KycRegisterFailure`
      // would force the user to restart a one-time heavyweight ceremony
      // (legal disclaimer + EIP-712 sign) on any BLE link drop.
      expect: () => [
        const KycRegisterSubmitting(_userData),
        const KycRegisterBitboxRequired(_userData),
      ],
    );

    blocTest<KycRegisterCubit, KycRegisterState>(
      'completeRegistration throws generic exception → Failure',
      setUp: () {
        when(() => registrationService.completeRegistration(any()))
            .thenAnswer((_) async => throw Exception('network down'));
      },
      build: () => build(_userData),
      act: (c) => c.submit(_userData),
      expect: () => [
        const KycRegisterSubmitting(_userData),
        isA<KycRegisterFailure>(),
      ],
    );
  });

  group('revertToReady', () {
    blocTest<KycRegisterCubit, KycRegisterState>(
      'BitboxRequired → revertToReady → Ready (cancel-without-reconnect path)',
      setUp: () {
        when(() => registrationService.completeRegistration(any()))
            .thenThrow(const BitboxNotConnectedException());
      },
      build: () => build(_userData),
      act: (c) async {
        await c.submit(_userData);
        c.revertToReady(_userData);
      },
      expect: () => [
        const KycRegisterSubmitting(_userData),
        const KycRegisterBitboxRequired(_userData),
        const KycRegisterReady(_userData),
      ],
    );
  });
}
