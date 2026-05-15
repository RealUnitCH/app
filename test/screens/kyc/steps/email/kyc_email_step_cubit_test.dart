import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:realunit_wallet/packages/service/dfx/exceptions/api_exception.dart';
import 'package:realunit_wallet/packages/service/dfx/models/registration/registration_email_status.dart';
import 'package:realunit_wallet/packages/service/dfx/real_unit_registration_service.dart';
import 'package:realunit_wallet/screens/kyc/steps/email/cubits/email_step/kyc_email_step_cubit.dart';

class _MockRegistrationService extends Mock implements RealUnitRegistrationService {}

void main() {
  late _MockRegistrationService service;

  setUp(() {
    service = _MockRegistrationService();
  });

  KycEmailStepCubit build() => KycEmailStepCubit(service);

  group('initial state', () {
    test('emits $KycEmailStepInitial', () {
      expect(build().state, isA<KycEmailStepInitial>());
    });
  });

  group('registerEmail', () {
    blocTest<KycEmailStepCubit, KycEmailStepState>(
      'success: Loading → Success carrying the wire status',
      setUp: () => when(() => service.registerEmail(any())).thenAnswer(
        (_) async => RegistrationEmailStatus.emailRegistered,
      ),
      build: build,
      act: (c) => c.registerEmail('a@b.com'),
      expect: () => const [
        KycEmailStepLoading(),
        KycEmailStepSuccess(RegistrationEmailStatus.emailRegistered),
      ],
    );

    blocTest<KycEmailStepCubit, KycEmailStepState>(
      'ApiException "does not match verified email" maps to emailDoesNotMatch',
      setUp: () => when(() => service.registerEmail(any())).thenAnswer(
        (_) async => throw const ApiException(
          code: 'EMAIL_MISMATCH',
          message: 'does not match verified email',
        ),
      ),
      build: build,
      act: (c) => c.registerEmail('a@b.com'),
      expect: () => [
        const KycEmailStepLoading(),
        isA<KycEmailStepFailure>().having(
          (s) => s.error,
          'error',
          KycEmailStepError.emailDoesNotMatch,
        ),
      ],
    );

    blocTest<KycEmailStepCubit, KycEmailStepState>(
      'other ApiException → unknown error',
      setUp: () => when(() => service.registerEmail(any())).thenAnswer(
        (_) async => throw const ApiException(
          code: 'SOMETHING_ELSE',
          message: 'random failure',
        ),
      ),
      build: build,
      act: (c) => c.registerEmail('a@b.com'),
      expect: () => [
        const KycEmailStepLoading(),
        isA<KycEmailStepFailure>()
            .having((s) => s.error, 'error', KycEmailStepError.unknown)
            .having((s) => s.message, 'message', 'random failure'),
      ],
    );

    blocTest<KycEmailStepCubit, KycEmailStepState>(
      'non-Api exception → unknown error carrying e.toString()',
      setUp: () => when(() => service.registerEmail(any())).thenAnswer(
        (_) async => throw Exception('socket down'),
      ),
      build: build,
      act: (c) => c.registerEmail('a@b.com'),
      expect: () => [
        const KycEmailStepLoading(),
        isA<KycEmailStepFailure>().having(
          (s) => s.error,
          'error',
          KycEmailStepError.unknown,
        ),
      ],
    );
  });

  group('$KycEmailStepFailure', () {
    test('Equatable props cover error + message', () {
      const a = KycEmailStepFailure(KycEmailStepError.unknown, 'x');
      const b = KycEmailStepFailure(KycEmailStepError.unknown, 'x');
      const c = KycEmailStepFailure(KycEmailStepError.unknown, 'y');

      expect(a, b);
      expect(a, isNot(c));
    });
  });

  group('$KycEmailStepSuccess', () {
    test('Equatable props cover status', () {
      const a = KycEmailStepSuccess(RegistrationEmailStatus.emailRegistered);
      const b = KycEmailStepSuccess(RegistrationEmailStatus.emailRegistered);
      const c = KycEmailStepSuccess(RegistrationEmailStatus.mergeRequested);

      expect(a, b);
      expect(a, isNot(c));
    });
  });
}
