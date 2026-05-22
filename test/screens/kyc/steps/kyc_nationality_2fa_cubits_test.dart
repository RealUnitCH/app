import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:realunit_wallet/packages/service/dfx/dfx_kyc_service.dart';
import 'package:realunit_wallet/packages/service/dfx/models/country/country.dart';
import 'package:realunit_wallet/screens/kyc/steps/2fa/cubits/kyc_2fa/kyc_2fa_cubit.dart';
import 'package:realunit_wallet/screens/kyc/steps/2fa/cubits/kyc_2fa_verify/kyc_2fa_verify_cubit.dart';
import 'package:realunit_wallet/screens/kyc/steps/nationality/cubit/kyc_nationality/kyc_nationality_cubit.dart';

class _MockKycService extends Mock implements DfxKycService {}

void main() {
  late _MockKycService service;

  setUpAll(() {
    registerFallbackValue(<String, dynamic>{});
  });

  setUp(() {
    service = _MockKycService();
  });

  group('$KycNationalityCubit', () {
    test('initial state', () {
      expect(KycNationalityCubit(service).state, isA<KycNationalityInitial>());
    });

    blocTest<KycNationalityCubit, KycNationalityState>(
      'happy path: setData fires with {"nationality": {"id": <id>}}; emits Loading → Success',
      setUp: () => when(() => service.setData(any(), any())).thenAnswer((_) async {}),
      build: () => KycNationalityCubit(service),
      act: (c) => c.registerNationality(
        url: 'https://kyc/nat',
        nationality: const Country(
          id: 41,
          symbol: 'CH',
          name: 'Switzerland',
          nationalityAllowed: true,
          locationAllowed: true,
        ),
      ),
      expect: () => [
        isA<KycNationalityLoading>(),
        isA<KycNationalitySuccess>(),
      ],
      verify: (_) => verify(
        () => service.setData('https://kyc/nat', {
          'nationality': {'id': 41},
        }),
      ).called(1),
    );

    blocTest<KycNationalityCubit, KycNationalityState>(
      'failure: setData throws → emits Loading then Failure carrying e.toString()',
      setUp: () => when(
        () => service.setData(any(), any()),
      ).thenAnswer((_) async => throw Exception('boom')),
      build: () => KycNationalityCubit(service),
      act: (c) => c.registerNationality(
        url: 'https://kyc/nat',
        nationality: const Country(
          id: 41,
          symbol: 'CH',
          name: 'Switzerland',
          nationalityAllowed: true,
          locationAllowed: true,
        ),
      ),
      expect: () => [
        isA<KycNationalityLoading>(),
        isA<KycNationalityFailure>().having((s) => s.message, 'message', contains('boom')),
      ],
    );
  });

  group('$Kyc2FaCubit (requestCode)', () {
    test('initial state', () {
      expect(Kyc2FaCubit(service).state, isA<Kyc2FaInitial>());
    });

    blocTest<Kyc2FaCubit, Kyc2FaState>(
      'happy path: request2FaCode → Loading → Success',
      setUp: () => when(() => service.request2FaCode()).thenAnswer((_) async {}),
      build: () => Kyc2FaCubit(service),
      act: (c) => c.requestCode(),
      expect: () => [
        isA<Kyc2FaLoading>(),
        isA<Kyc2FaSuccess>(),
      ],
    );

    blocTest<Kyc2FaCubit, Kyc2FaState>(
      'failure: request2FaCode throws → Loading → Failure(errorMessage)',
      setUp: () => when(
        () => service.request2FaCode(),
      ).thenAnswer((_) async => throw Exception('rate limited')),
      build: () => Kyc2FaCubit(service),
      act: (c) => c.requestCode(),
      expect: () => [
        isA<Kyc2FaLoading>(),
        isA<Kyc2FaFailure>().having(
          (s) => s.errorMessage,
          'errorMessage',
          contains('rate limited'),
        ),
      ],
    );
  });

  group('$Kyc2FaVerifyCubit (verifyCode)', () {
    test('initial state', () {
      expect(Kyc2FaVerifyCubit(service).state, isA<Kyc2FaVerifyInitial>());
    });

    blocTest<Kyc2FaVerifyCubit, Kyc2FaVerifyState>(
      'happy path: verify2FaCode → Loading → Success',
      setUp: () => when(() => service.verify2FaCode(any())).thenAnswer((_) async {}),
      build: () => Kyc2FaVerifyCubit(service),
      act: (c) => c.verifyCode('123456'),
      expect: () => [
        isA<Kyc2FaVerifyLoading>(),
        isA<Kyc2FaVerifySuccess>(),
      ],
      verify: (_) => verify(() => service.verify2FaCode('123456')).called(1),
    );

    blocTest<Kyc2FaVerifyCubit, Kyc2FaVerifyState>(
      'failure: verify2FaCode throws → Loading → Failure(errorMessage)',
      setUp: () => when(
        () => service.verify2FaCode(any()),
      ).thenAnswer((_) async => throw Exception('wrong code')),
      build: () => Kyc2FaVerifyCubit(service),
      act: (c) => c.verifyCode('000000'),
      expect: () => [
        isA<Kyc2FaVerifyLoading>(),
        isA<Kyc2FaVerifyFailure>().having(
          (s) => s.errorMessage,
          'errorMessage',
          contains('wrong code'),
        ),
      ],
    );
  });
}
