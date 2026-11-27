import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:realunit_wallet/packages/service/dfx/exceptions/api_exception.dart';
import 'package:realunit_wallet/packages/service/dfx/exceptions/request_timeout_exception.dart';
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
      'verification_code_sent: Loading → CodeSent carrying the submitted email',
      setUp: () => when(() => service.registerEmail(any())).thenAnswer(
        (_) async => RegistrationEmailStatus.verificationCodeSent,
      ),
      build: build,
      act: (c) => c.registerEmail('a@b.com'),
      expect: () => const [
        KycEmailStepLoading(),
        KycEmailStepCodeSent('a@b.com'),
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

  group('timeout', () {
    blocTest<KycEmailStepCubit, KycEmailStepState>(
      'a request timeout is a timeout failure without the exception text',
      setUp: () => when(() => service.registerEmail(any())).thenThrow(const RequestTimeoutException(Duration(seconds: 20))),
      build: build,
      act: (c) => c.registerEmail('a@b.com'),
      expect: () => const [
        KycEmailStepLoading(),
        KycEmailStepFailure(KycEmailStepError.timeout, ''),
      ],
    );
  });

  test('a second submit while register/email runs is ignored', () async {
    final pending = Completer<RegistrationEmailStatus>();
    when(() => service.registerEmail(any())).thenAnswer((_) => pending.future);
    final cubit = build();

    final first = cubit.registerEmail('a@b.com');
    final second = cubit.registerEmail('a@b.com');
    pending.complete(RegistrationEmailStatus.verificationCodeSent);
    await Future.wait([first, second]);

    verify(() => service.registerEmail('a@b.com')).called(1);
    await cubit.close();
  });

  blocTest<KycEmailStepCubit, KycEmailStepState>(
    'a sign-in timeout before the request is not reported as a server timeout',
    setUp: () => when(() => service.registerEmail(any())).thenThrow(TimeoutException('signature')),
    build: build,
    act: (c) => c.registerEmail('a@b.com'),
    expect: () => [
      const KycEmailStepLoading(),
      isA<KycEmailStepFailure>().having((s) => s.error, 'error', KycEmailStepError.unknown),
    ],
  );

  group('closed while register/email is in flight', () {
    for (final outcome in ['status', 'api error', 'other error']) {
      test('a late $outcome does not emit or throw', () async {
        final pending = Completer<RegistrationEmailStatus>();
        when(() => service.registerEmail(any())).thenAnswer((_) => pending.future);
        final cubit = build();
        final states = <KycEmailStepState>[];
        final sub = cubit.stream.listen(states.add);

        final call = cubit.registerEmail('a@b.com');
        await Future<void>.delayed(Duration.zero);
        await cubit.close();
        switch (outcome) {
          case 'status':
            pending.complete(RegistrationEmailStatus.verificationCodeSent);
          case 'api error':
            pending.completeError(const ApiException(statusCode: 500, code: 'UNKNOWN', message: 'boom'));
          default:
            pending.completeError(Exception('offline'));
        }

        await expectLater(call, completes);
        expect(states, const [KycEmailStepLoading()]);
        await sub.cancel();
      });
    }
  });
}
