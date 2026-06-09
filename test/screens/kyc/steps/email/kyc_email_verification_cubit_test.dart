import 'dart:convert';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:realunit_wallet/packages/service/dfx/dfx_auth_service.dart';
import 'package:realunit_wallet/packages/service/dfx/models/registration/kyc/kyc_personal_data.dart';
import 'package:realunit_wallet/packages/service/dfx/models/registration/registration_status.dart';
import 'package:realunit_wallet/packages/service/dfx/models/user/dto/real_unit_user_data_dto.dart';
import 'package:realunit_wallet/packages/service/dfx/models/wallet/real_unit_registration_info_dto.dart';
import 'package:realunit_wallet/packages/service/dfx/models/wallet/real_unit_registration_state.dart';
import 'package:realunit_wallet/packages/service/dfx/real_unit_registration_service.dart';
import 'package:realunit_wallet/screens/kyc/steps/email/cubits/email_verification/kyc_email_verification_cubit.dart';

class _MockAuthService extends Mock implements DFXAuthService {}

class _MockRegistrationService extends Mock implements RealUnitRegistrationService {}

String _fakeJwt(int accountId) {
  final header = base64Url
      .encode(utf8.encode('{"alg":"HS256"}'))
      .replaceAll('=', '');
  final payload = base64Url
      .encode(utf8.encode('{"account":$accountId}'))
      .replaceAll('=', '');
  return '$header.$payload.signature';
}

const _kycData = KycPersonalData(
  accountType: KycAccountType.personal,
  firstName: 'A',
  lastName: 'B',
  phone: '+41',
  address: KycAddress(
    street: 'S',
    zip: '8000',
    city: 'Zurich',
    country: 41,
  ),
);

const _userData = RealUnitUserDataDto(
  email: 'a@b.com',
  name: 'A B',
  type: 'HUMAN',
  phoneNumber: '+41',
  birthday: '2000-01-01',
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
  late _MockAuthService auth;
  late _MockRegistrationService registrationService;

  setUpAll(() {
    registerFallbackValue(_userData);
  });

  setUp(() {
    auth = _MockAuthService();
    registrationService = _MockRegistrationService();
    when(() => auth.invalidateAuthToken()).thenReturn(null);
  });

  KycEmailVerificationCubit build() => KycEmailVerificationCubit(
        dfxService: auth,
        registrationService: registrationService,
      );

  group('initial state', () {
    test('emits $KycEmailVerificationInitial', () {
      expect(build().state, isA<KycEmailVerificationInitial>());
    });
  });

  group('checkEmailVerification', () {
    blocTest<KycEmailVerificationCubit, KycEmailVerificationState>(
      'same account id before + after invalidation → Failure',
      setUp: () {
        // Both calls return the same token, so the same account id is parsed.
        when(() => auth.getAuthToken()).thenAnswer((_) async => _fakeJwt(1));
      },
      build: build,
      act: (c) => c.checkEmailVerification(),
      expect: () => [
        isA<KycEmailVerificationLoading>(),
        isA<KycEmailVerificationFailure>(),
      ],
      verify: (_) {
        verify(() => auth.invalidateAuthToken()).called(1);
        verifyNever(() => registrationService.registerWallet(any()));
      },
    );

    blocTest<KycEmailVerificationCubit, KycEmailVerificationState>(
      'changed account id + existing user data → registerWallet + Success',
      setUp: () {
        final tokens = [_fakeJwt(1), _fakeJwt(2)];
        var i = 0;
        when(() => auth.getAuthToken()).thenAnswer((_) async => tokens[i++]);
        when(() => registrationService.getRegistrationInfo()).thenAnswer(
          (_) async => RealUnitRegistrationInfoDto(
            state: RealUnitRegistrationState.addWallet,
            realUnitUserDataDto: _userData,
          ),
        );
        when(() => registrationService.registerWallet(any()))
            .thenAnswer((_) async => RegistrationStatus.completed);
      },
      build: build,
      act: (c) => c.checkEmailVerification(),
      expect: () => [
        isA<KycEmailVerificationLoading>(),
        isA<KycEmailVerificationSuccess>(),
      ],
      verify: (_) => verify(() => registrationService.registerWallet(_userData)).called(1),
    );

    blocTest<KycEmailVerificationCubit, KycEmailVerificationState>(
      'changed account id + NewRegistration → Success (hands off to the KYC flow), '
      'no registerWallet — the merged account has no prior RealUnit registration '
      'so register/wallet would 400 "No RealUnit registration found"',
      setUp: () {
        final tokens = [_fakeJwt(1), _fakeJwt(2)];
        var i = 0;
        when(() => auth.getAuthToken()).thenAnswer((_) async => tokens[i++]);
        when(() => registrationService.getRegistrationInfo()).thenAnswer(
          (_) async => RealUnitRegistrationInfoDto(
            state: RealUnitRegistrationState.newRegistration,
            realUnitUserDataDto: null,
          ),
        );
      },
      build: build,
      act: (c) => c.checkEmailVerification(),
      expect: () => [
        isA<KycEmailVerificationLoading>(),
        isA<KycEmailVerificationSuccess>(),
      ],
      verify: (_) {
        verifyNever(() => registrationService.registerWallet(any()));
      },
    );

    blocTest<KycEmailVerificationCubit, KycEmailVerificationState>(
      'NewRegistration WITH userData present still hands off (Success), no '
      'registerWallet — reproduces the real bug: existing KYC data makes '
      'userData non-null while the account still has no RealUnit registration',
      setUp: () {
        final tokens = [_fakeJwt(1), _fakeJwt(2)];
        var i = 0;
        when(() => auth.getAuthToken()).thenAnswer((_) async => tokens[i++]);
        when(() => registrationService.getRegistrationInfo()).thenAnswer(
          (_) async => RealUnitRegistrationInfoDto(
            state: RealUnitRegistrationState.newRegistration,
            realUnitUserDataDto: _userData,
          ),
        );
      },
      build: build,
      act: (c) => c.checkEmailVerification(),
      expect: () => [
        isA<KycEmailVerificationLoading>(),
        isA<KycEmailVerificationSuccess>(),
      ],
      verify: (_) {
        verifyNever(() => registrationService.registerWallet(any()));
      },
    );

    blocTest<KycEmailVerificationCubit, KycEmailVerificationState>(
      'registerWallet throws → RegistrationFailure, no Success '
      '(failure is surfaced so the user can retry instead of proceeding '
      'with a wallet that is not actually registered)',
      setUp: () {
        final tokens = [_fakeJwt(1), _fakeJwt(2)];
        var i = 0;
        when(() => auth.getAuthToken()).thenAnswer((_) async => tokens[i++]);
        when(() => registrationService.getRegistrationInfo()).thenAnswer(
          (_) async => RealUnitRegistrationInfoDto(
            state: RealUnitRegistrationState.addWallet,
            realUnitUserDataDto: _userData,
          ),
        );
        when(() => registrationService.registerWallet(any()))
            .thenAnswer((_) async => throw Exception('boom'));
      },
      build: build,
      act: (c) => c.checkEmailVerification(),
      expect: () => [
        isA<KycEmailVerificationLoading>(),
        isA<KycEmailVerificationRegistrationFailure>(),
      ],
      verify: (_) => verify(() => registrationService.registerWallet(_userData)).called(1),
    );

    blocTest<KycEmailVerificationCubit, KycEmailVerificationState>(
      'retry after a transient registerWallet failure (AddWallet): the second '
      'call skips the account-id check via _mergeDetected → registerWallet '
      'succeeds → Success',
      setUp: () {
        // First call detects the merge (account 1 → 2). The second call must
        // skip the same-account-id guard (which would otherwise emit Failure,
        // "email not yet confirmed") thanks to `_mergeDetected`, and retry the
        // AddWallet registration.
        final tokens = [_fakeJwt(1), _fakeJwt(2)];
        var i = 0;
        when(() => auth.getAuthToken()).thenAnswer((_) async => tokens[i++]);
        when(() => registrationService.getRegistrationInfo()).thenAnswer(
          (_) async => RealUnitRegistrationInfoDto(
            state: RealUnitRegistrationState.addWallet,
            realUnitUserDataDto: _userData,
          ),
        );
        var calls = 0;
        when(() => registrationService.registerWallet(any())).thenAnswer((_) async {
          calls++;
          if (calls == 1) throw Exception('transient');
          return RegistrationStatus.completed;
        });
      },
      build: build,
      act: (c) async {
        await c.checkEmailVerification();
        await c.checkEmailVerification();
      },
      expect: () => [
        isA<KycEmailVerificationLoading>(),
        isA<KycEmailVerificationRegistrationFailure>(),
        isA<KycEmailVerificationLoading>(),
        isA<KycEmailVerificationSuccess>(),
      ],
      verify: (_) {
        verify(() => registrationService.registerWallet(_userData)).called(2);
      },
    );
  });

  group('getAccountId', () {
    test('returns null when there is no token', () async {
      when(() => auth.getAuthToken()).thenAnswer((_) async => null);

      expect(await build().getAccountId(), isNull);
    });

    test('returns the account claim from a valid JWT', () async {
      when(() => auth.getAuthToken()).thenAnswer((_) async => _fakeJwt(42));

      expect(await build().getAccountId(), 42);
    });
  });
}
