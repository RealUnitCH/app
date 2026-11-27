import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:realunit_wallet/packages/service/dfx/exceptions/api_exception.dart';
import 'package:realunit_wallet/packages/service/dfx/models/registration/registration_email_status.dart';
import 'package:realunit_wallet/packages/service/dfx/real_unit_registration_service.dart';
import 'package:realunit_wallet/screens/kyc/steps/email/cubits/email_code/kyc_email_code_cubit.dart';

class _MockRegistrationService extends Mock implements RealUnitRegistrationService {}

void main() {
  late _MockRegistrationService service;

  setUp(() {
    service = _MockRegistrationService();
  });

  KycEmailCodeCubit build() => KycEmailCodeCubit(service, email: 'a@b.com');

  test('starts in $KycEmailCodeInitial and keeps the address', () {
    final cubit = build();
    expect(cubit.state, const KycEmailCodeInitial());
    expect(cubit.email, 'a@b.com');
  });

  group('verify', () {
    blocTest<KycEmailCodeCubit, KycEmailCodeState>(
      'confirms the code, registers the email again and completes with its status',
      setUp: () {
        when(() => service.verifyEmail(any())).thenAnswer((_) async {});
        when(() => service.registerEmail(any())).thenAnswer(
          (_) async => RegistrationEmailStatus.emailRegistered,
        );
      },
      build: build,
      act: (c) => c.verify('123456'),
      expect: () => const [
        KycEmailCodeVerifying(),
        KycEmailCodeCompleted(RegistrationEmailStatus.emailRegistered),
      ],
      verify: (_) {
        verify(() => service.verifyEmail('123456')).called(1);
        verify(() => service.registerEmail('a@b.com')).called(1);
      },
    );

    blocTest<KycEmailCodeCubit, KycEmailCodeState>(
      'completes with mergeRequested when the second register/email asks for a merge',
      setUp: () {
        when(() => service.verifyEmail(any())).thenAnswer((_) async {});
        when(() => service.registerEmail(any())).thenAnswer(
          (_) async => RegistrationEmailStatus.mergeRequested,
        );
      },
      build: build,
      act: (c) => c.verify('123456'),
      expect: () => const [
        KycEmailCodeVerifying(),
        KycEmailCodeCompleted(RegistrationEmailStatus.mergeRequested),
      ],
    );

    blocTest<KycEmailCodeCubit, KycEmailCodeState>(
      'a 403 (wrong or expired code) is invalidCode and skips register/email',
      setUp: () => when(() => service.verifyEmail(any())).thenThrow(
        const ApiException(
          statusCode: 403,
          code: 'UNKNOWN',
          message: 'Invalid or expired mail verification token',
        ),
      ),
      build: build,
      act: (c) => c.verify('000000'),
      expect: () => const [
        KycEmailCodeVerifying(),
        KycEmailCodeFailure(KycEmailCodeError.invalidCode),
      ],
      verify: (_) => verifyNever(() => service.registerEmail(any())),
    );

    blocTest<KycEmailCodeCubit, KycEmailCodeState>(
      'a 409 merge request on confirmation completes with mergeRequested',
      setUp: () => when(() => service.verifyEmail(any())).thenThrow(
        const ApiException(
          statusCode: 409,
          code: 'UNKNOWN',
          message: 'account merge request sent',
        ),
      ),
      build: build,
      act: (c) => c.verify('123456'),
      expect: () => const [
        KycEmailCodeVerifying(),
        KycEmailCodeCompleted(RegistrationEmailStatus.mergeRequested),
      ],
      verify: (_) => verifyNever(() => service.registerEmail(any())),
    );

    blocTest<KycEmailCodeCubit, KycEmailCodeState>(
      'another 409 is an unknown failure with the API message',
      setUp: () => when(() => service.verifyEmail(any())).thenThrow(
        const ApiException(
          statusCode: 409,
          code: 'UNKNOWN',
          message: 'Account already exists',
        ),
      ),
      build: build,
      act: (c) => c.verify('123456'),
      expect: () => const [
        KycEmailCodeVerifying(),
        KycEmailCodeFailure(KycEmailCodeError.unknown, message: 'Account already exists'),
      ],
    );

    blocTest<KycEmailCodeCubit, KycEmailCodeState>(
      'a non-API error on confirmation is an unknown failure',
      setUp: () => when(() => service.verifyEmail(any())).thenThrow(Exception('offline')),
      build: build,
      act: (c) => c.verify('123456'),
      expect: () => const [
        KycEmailCodeVerifying(),
        KycEmailCodeFailure(KycEmailCodeError.unknown, message: 'Exception: offline'),
      ],
    );

    blocTest<KycEmailCodeCubit, KycEmailCodeState>(
      'a failed second register/email is retried without sending the used code again',
      setUp: () {
        when(() => service.verifyEmail(any())).thenAnswer((_) async {});
        var calls = 0;
        when(() => service.registerEmail(any())).thenAnswer((_) async {
          calls++;
          if (calls == 1) {
            throw const ApiException(statusCode: 500, code: 'UNKNOWN', message: 'boom');
          }
          return RegistrationEmailStatus.emailRegistered;
        });
      },
      build: build,
      act: (c) async {
        await c.verify('123456');
        await c.verify('123456');
      },
      expect: () => const [
        KycEmailCodeVerifying(),
        KycEmailCodeFailure(KycEmailCodeError.unknown, message: 'boom'),
        KycEmailCodeVerifying(),
        KycEmailCodeCompleted(RegistrationEmailStatus.emailRegistered),
      ],
      verify: (_) {
        verify(() => service.verifyEmail('123456')).called(1);
        verify(() => service.registerEmail('a@b.com')).called(2);
      },
    );

    blocTest<KycEmailCodeCubit, KycEmailCodeState>(
      'a new code sent by the second register/email asks for that code',
      setUp: () {
        when(() => service.verifyEmail(any())).thenAnswer((_) async {});
        when(() => service.registerEmail(any())).thenAnswer(
          (_) async => RegistrationEmailStatus.verificationCodeSent,
        );
      },
      build: build,
      act: (c) async {
        await c.verify('123456');
        await c.verify('654321');
      },
      expect: () => const [
        KycEmailCodeVerifying(),
        KycEmailCodeResent(),
        KycEmailCodeVerifying(),
        KycEmailCodeResent(),
      ],
      verify: (_) {
        verify(() => service.verifyEmail('123456')).called(1);
        verify(() => service.verifyEmail('654321')).called(1);
      },
    );
  });

  group('resend', () {
    blocTest<KycEmailCodeCubit, KycEmailCodeState>(
      'calls register/email again and reports the new code',
      setUp: () => when(() => service.registerEmail(any())).thenAnswer(
        (_) async => RegistrationEmailStatus.verificationCodeSent,
      ),
      build: build,
      act: (c) => c.resend(),
      expect: () => const [
        KycEmailCodeResending(),
        KycEmailCodeResent(),
      ],
      verify: (_) => verify(() => service.registerEmail('a@b.com')).called(1),
    );

    blocTest<KycEmailCodeCubit, KycEmailCodeState>(
      'completes when the API already registered the address',
      setUp: () => when(() => service.registerEmail(any())).thenAnswer(
        (_) async => RegistrationEmailStatus.emailRegistered,
      ),
      build: build,
      act: (c) => c.resend(),
      expect: () => const [
        KycEmailCodeResending(),
        KycEmailCodeCompleted(RegistrationEmailStatus.emailRegistered),
      ],
    );

    blocTest<KycEmailCodeCubit, KycEmailCodeState>(
      'an API error is an unknown failure with the API message',
      setUp: () => when(() => service.registerEmail(any())).thenThrow(
        const ApiException(statusCode: 429, code: 'UNKNOWN', message: 'Too many requests'),
      ),
      build: build,
      act: (c) => c.resend(),
      expect: () => const [
        KycEmailCodeResending(),
        KycEmailCodeFailure(KycEmailCodeError.unknown, message: 'Too many requests'),
      ],
    );

    blocTest<KycEmailCodeCubit, KycEmailCodeState>(
      'a non-API error is an unknown failure',
      setUp: () => when(() => service.registerEmail(any())).thenThrow(Exception('offline')),
      build: build,
      act: (c) => c.resend(),
      expect: () => const [
        KycEmailCodeResending(),
        KycEmailCodeFailure(KycEmailCodeError.unknown, message: 'Exception: offline'),
      ],
    );
  });

  group('states', () {
    test('compare by value', () {
      expect(
        const KycEmailCodeCompleted(RegistrationEmailStatus.emailRegistered),
        const KycEmailCodeCompleted(RegistrationEmailStatus.emailRegistered),
      );
      expect(
        const KycEmailCodeFailure(KycEmailCodeError.unknown, message: 'a'),
        isNot(const KycEmailCodeFailure(KycEmailCodeError.unknown, message: 'b')),
      );
      expect(const KycEmailCodeResent(), const KycEmailCodeResent());
      expect(const KycEmailCodeResending().props, isEmpty);
    });
  });
}
