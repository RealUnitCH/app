import 'dart:convert';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:realunit_wallet/packages/service/dfx/dfx_auth_service.dart';
import 'package:realunit_wallet/packages/service/dfx/models/registration/registration_status.dart';
import 'package:realunit_wallet/packages/service/dfx/models/user/dto/real_unit_user_data_dto.dart';
import 'package:realunit_wallet/packages/service/dfx/models/registration/kyc/kyc_personal_data.dart';
import 'package:realunit_wallet/packages/service/dfx/models/wallet/real_unit_wallet_status_dto.dart';
import 'package:realunit_wallet/packages/service/dfx/real_unit_registration_service.dart';
import 'package:realunit_wallet/packages/service/dfx/real_unit_wallet_service.dart';
import 'package:realunit_wallet/screens/kyc/steps/email/cubits/email_verification/kyc_email_verification_cubit.dart';

class _MockAuthService extends Mock implements DFXAuthService {}

class _MockWalletService extends Mock implements RealUnitWalletService {}

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
  late _MockWalletService walletService;
  late _MockRegistrationService registrationService;

  setUpAll(() {
    registerFallbackValue(_userData);
  });

  setUp(() {
    auth = _MockAuthService();
    walletService = _MockWalletService();
    registrationService = _MockRegistrationService();
    when(() => auth.invalidateAuthToken()).thenReturn(null);
  });

  KycEmailVerificationCubit build() => KycEmailVerificationCubit(
        dfxService: auth,
        walletService: walletService,
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
        when(() => walletService.getWalletStatus()).thenAnswer(
          (_) async => RealUnitWalletStatusDto(
            isRegistered: true,
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
      'changed account id but no userData → cubit settles on Success (Registration'
      'Failure is intermediate, overwritten by the outer Success emit)',
      setUp: () {
        final tokens = [_fakeJwt(1), _fakeJwt(2)];
        var i = 0;
        when(() => auth.getAuthToken()).thenAnswer((_) async => tokens[i++]);
        when(() => walletService.getWalletStatus()).thenAnswer(
          (_) async => RealUnitWalletStatusDto(
            isRegistered: false,
            realUnitUserDataDto: null,
          ),
        );
      },
      build: build,
      act: (c) => c.checkEmailVerification(),
      verify: (c) => expect(c.state, isA<KycEmailVerificationSuccess>()),
    );

    blocTest<KycEmailVerificationCubit, KycEmailVerificationState>(
      'registerWallet throws: cubit still settles on Success (does not crash)',
      setUp: () {
        final tokens = [_fakeJwt(1), _fakeJwt(2)];
        var i = 0;
        when(() => auth.getAuthToken()).thenAnswer((_) async => tokens[i++]);
        when(() => walletService.getWalletStatus()).thenAnswer(
          (_) async => RealUnitWalletStatusDto(
            isRegistered: true,
            realUnitUserDataDto: _userData,
          ),
        );
        when(() => registrationService.registerWallet(any()))
            .thenAnswer((_) async => throw Exception('boom'));
      },
      build: build,
      act: (c) => c.checkEmailVerification(),
      verify: (c) {
        expect(c.state, isA<KycEmailVerificationSuccess>());
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
