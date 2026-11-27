import 'dart:async';

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
      'a 409 on confirmation lets register/email decide: merge_requested completes',
      setUp: () {
        when(() => service.verifyEmail(any())).thenThrow(
          const ApiException(statusCode: 409, code: 'UNKNOWN', message: 'any conflict text'),
        );
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
      verify: (_) => verify(() => service.registerEmail('a@b.com')).called(1),
    );

    blocTest<KycEmailCodeCubit, KycEmailCodeState>(
      'a 409 on confirmation is an unknown failure when register/email fails too',
      setUp: () {
        when(() => service.verifyEmail(any())).thenThrow(
          const ApiException(statusCode: 409, code: 'UNKNOWN', message: 'Account already exists'),
        );
        when(() => service.registerEmail(any())).thenThrow(
          const ApiException(statusCode: 409, code: 'UNKNOWN', message: 'Account already exists'),
        );
      },
      build: build,
      act: (c) => c.verify('123456'),
      expect: () => const [
        KycEmailCodeVerifying(),
        KycEmailCodeFailure(KycEmailCodeError.unknown),
      ],
    );

    blocTest<KycEmailCodeCubit, KycEmailCodeState>(
      'another error on confirmation is an unknown failure without register/email',
      setUp: () => when(() => service.verifyEmail(any())).thenThrow(
        const ApiException(statusCode: 500, code: 'UNKNOWN', message: 'boom'),
      ),
      build: build,
      act: (c) => c.verify('123456'),
      expect: () => const [
        KycEmailCodeVerifying(),
        KycEmailCodeFailure(KycEmailCodeError.unknown),
      ],
      verify: (_) => verifyNever(() => service.registerEmail(any())),
    );

    blocTest<KycEmailCodeCubit, KycEmailCodeState>(
      'a 403 after a timed-out try is settled by register/email, not shown as a wrong code',
      setUp: () {
        var calls = 0;
        when(() => service.verifyEmail(any())).thenAnswer((_) async {
          calls++;
          if (calls == 1) throw TimeoutException('stalled');
          throw const ApiException(
            statusCode: 403,
            code: 'UNKNOWN',
            message: 'Invalid or expired mail verification token',
          );
        });
        when(() => service.registerEmail(any())).thenAnswer(
          (_) async => RegistrationEmailStatus.emailRegistered,
        );
      },
      build: build,
      act: (c) async {
        await c.verify('123456');
        await c.verify('123456');
      },
      expect: () => const [
        KycEmailCodeVerifying(),
        KycEmailCodeFailure(KycEmailCodeError.unknown),
        KycEmailCodeVerifying(),
        KycEmailCodeCompleted(RegistrationEmailStatus.emailRegistered),
      ],
      verify: (_) {
        verify(() => service.verifyEmail('123456')).called(2);
        verify(() => service.registerEmail('a@b.com')).called(1);
      },
    );

    blocTest<KycEmailCodeCubit, KycEmailCodeState>(
      'a 403 without an earlier timeout stays a wrong code',
      setUp: () {
        var calls = 0;
        when(() => service.verifyEmail(any())).thenAnswer((_) async {
          calls++;
          if (calls == 1) throw TimeoutException('stalled');
          throw const ApiException(statusCode: 403, code: 'UNKNOWN', message: 'Invalid or expired mail verification token');
        });
        when(() => service.registerEmail(any())).thenAnswer(
          (_) async => RegistrationEmailStatus.verificationCodeSent,
        );
      },
      build: build,
      act: (c) async {
        await c.verify('123456'); // times out
        await c.verify('123456'); // 403 → register/email sends a new code
        await c.verify('000000'); // 403 again: a plain wrong code now
      },
      expect: () => const [
        KycEmailCodeVerifying(),
        KycEmailCodeFailure(KycEmailCodeError.unknown),
        KycEmailCodeVerifying(),
        KycEmailCodeResent(),
        KycEmailCodeVerifying(),
        KycEmailCodeFailure(KycEmailCodeError.invalidCode),
      ],
      verify: (_) => verify(() => service.registerEmail('a@b.com')).called(1),
    );

    blocTest<KycEmailCodeCubit, KycEmailCodeState>(
      'a non-API error on confirmation is an unknown failure',
      setUp: () => when(() => service.verifyEmail(any())).thenThrow(Exception('offline')),
      build: build,
      act: (c) => c.verify('123456'),
      expect: () => const [
        KycEmailCodeVerifying(),
        KycEmailCodeFailure(KycEmailCodeError.unknown),
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
        KycEmailCodeFailure(KycEmailCodeError.unknown),
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

  group('timeouts', () {
    blocTest<KycEmailCodeCubit, KycEmailCodeState>(
      'a timed-out confirmation is a retryable failure with the generic text',
      setUp: () => when(() => service.verifyEmail(any())).thenThrow(TimeoutException('stalled')),
      build: build,
      act: (c) => c.verify('123456'),
      expect: () => const [
        KycEmailCodeVerifying(),
        KycEmailCodeFailure(KycEmailCodeError.unknown),
      ],
    );

    blocTest<KycEmailCodeCubit, KycEmailCodeState>(
      'a timed-out register/email is a retryable failure with the generic text',
      setUp: () => when(() => service.registerEmail(any())).thenThrow(TimeoutException('stalled')),
      build: build,
      act: (c) => c.resend(),
      expect: () => const [
        KycEmailCodeResending(),
        KycEmailCodeFailure(KycEmailCodeError.unknown),
      ],
    );
  });

  group('possibly used code after a timeout', () {
    blocTest<KycEmailCodeCubit, KycEmailCodeState>(
      'an unrelated API error keeps the doubt, so a later 403 is still settled by register/email',
      setUp: () {
        var calls = 0;
        when(() => service.verifyEmail(any())).thenAnswer((_) async {
          calls++;
          if (calls == 1) throw TimeoutException('stalled');
          if (calls == 2) throw const ApiException(statusCode: 500, code: 'UNKNOWN', message: 'boom');
          throw const ApiException(statusCode: 403, code: 'UNKNOWN', message: 'Invalid or expired mail verification token');
        });
        when(() => service.registerEmail(any())).thenAnswer(
          (_) async => RegistrationEmailStatus.emailRegistered,
        );
      },
      build: build,
      act: (c) async {
        await c.verify('123456'); // timeout
        await c.verify('123456'); // 500
        await c.verify('123456'); // 403: the timed-out try may have used it
      },
      expect: () => const [
        KycEmailCodeVerifying(),
        KycEmailCodeFailure(KycEmailCodeError.unknown),
        KycEmailCodeVerifying(),
        KycEmailCodeFailure(KycEmailCodeError.unknown),
        KycEmailCodeVerifying(),
        KycEmailCodeCompleted(RegistrationEmailStatus.emailRegistered),
      ],
      verify: (_) => verify(() => service.registerEmail('a@b.com')).called(1),
    );

    blocTest<KycEmailCodeCubit, KycEmailCodeState>(
      'a successful resend clears the doubt, so a 403 on the new code is a wrong code',
      setUp: () {
        var calls = 0;
        when(() => service.verifyEmail(any())).thenAnswer((_) async {
          calls++;
          if (calls == 1) throw TimeoutException('stalled');
          throw const ApiException(statusCode: 403, code: 'UNKNOWN', message: 'Invalid or expired mail verification token');
        });
        when(() => service.registerEmail(any())).thenAnswer(
          (_) async => RegistrationEmailStatus.verificationCodeSent,
        );
      },
      build: build,
      act: (c) async {
        await c.verify('123456'); // timeout
        await c.resend(); // new code sent
        await c.verify('000000'); // 403 on the new code
      },
      expect: () => const [
        KycEmailCodeVerifying(),
        KycEmailCodeFailure(KycEmailCodeError.unknown),
        KycEmailCodeResending(),
        KycEmailCodeResent(),
        KycEmailCodeVerifying(),
        KycEmailCodeFailure(KycEmailCodeError.invalidCode),
      ],
      verify: (_) => verify(() => service.registerEmail('a@b.com')).called(1),
    );
  });

  group('second tap while a request runs', () {
    test('a second verify is ignored', () async {
      final pending = Completer<void>();
      when(() => service.verifyEmail(any())).thenAnswer((_) => pending.future);
      when(() => service.registerEmail(any())).thenAnswer(
        (_) async => RegistrationEmailStatus.emailRegistered,
      );
      final cubit = build();

      final first = cubit.verify('123456');
      final second = cubit.verify('123456');
      pending.complete();
      await Future.wait([first, second]);

      verify(() => service.verifyEmail('123456')).called(1);
      verify(() => service.registerEmail('a@b.com')).called(1);
      await cubit.close();
    });

    test('resend while verify runs, and a second resend, are ignored', () async {
      final pendingVerify = Completer<void>();
      final pendingRegister = Completer<RegistrationEmailStatus>();
      when(() => service.verifyEmail(any())).thenAnswer((_) => pendingVerify.future);
      when(() => service.registerEmail(any())).thenAnswer((_) => pendingRegister.future);
      final cubit = build();

      final verifying = cubit.verify('123456');
      await cubit.resend();
      pendingVerify.completeError(
        const ApiException(statusCode: 403, code: 'UNKNOWN', message: 'Invalid or expired mail verification token'),
      );
      await verifying;
      verifyNever(() => service.registerEmail(any()));

      final firstResend = cubit.resend();
      final secondResend = cubit.resend();
      pendingRegister.complete(RegistrationEmailStatus.verificationCodeSent);
      await Future.wait([firstResend, secondResend]);

      verify(() => service.registerEmail('a@b.com')).called(1);
      await cubit.close();
    });
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
      'an API error is an unknown failure',
      setUp: () => when(() => service.registerEmail(any())).thenThrow(
        const ApiException(statusCode: 429, code: 'UNKNOWN', message: 'Too many requests'),
      ),
      build: build,
      act: (c) => c.resend(),
      expect: () => const [
        KycEmailCodeResending(),
        KycEmailCodeFailure(KycEmailCodeError.unknown),
      ],
    );

    blocTest<KycEmailCodeCubit, KycEmailCodeState>(
      'a non-API error is an unknown failure',
      setUp: () => when(() => service.registerEmail(any())).thenThrow(Exception('offline')),
      build: build,
      act: (c) => c.resend(),
      expect: () => const [
        KycEmailCodeResending(),
        KycEmailCodeFailure(KycEmailCodeError.unknown),
      ],
    );
  });

  group('closed while a request is in flight', () {
    test('a late verify answer does not emit or throw', () async {
      final pending = Completer<void>();
      when(() => service.verifyEmail(any())).thenAnswer((_) => pending.future);
      final cubit = build();
      final states = <KycEmailCodeState>[];
      final sub = cubit.stream.listen(states.add);

      final call = cubit.verify('123456');
      await Future<void>.delayed(Duration.zero);
      await cubit.close();
      pending.completeError(
        const ApiException(statusCode: 403, code: 'UNKNOWN', message: 'Invalid or expired mail verification token'),
      );

      await expectLater(call, completes);
      expect(states, const [KycEmailCodeVerifying()]);
      verifyNever(() => service.registerEmail(any()));
      await sub.cancel();
    });

    test('an accepted code still finishes register/email after close, without emitting', () async {
      final pending = Completer<void>();
      when(() => service.verifyEmail(any())).thenAnswer((_) => pending.future);
      when(() => service.registerEmail(any())).thenAnswer(
        (_) async => RegistrationEmailStatus.emailRegistered,
      );
      final cubit = build();
      final states = <KycEmailCodeState>[];
      final sub = cubit.stream.listen(states.add);

      final call = cubit.verify('123456');
      await Future<void>.delayed(Duration.zero);
      await cubit.close();
      pending.complete();

      await expectLater(call, completes);
      verify(() => service.registerEmail('a@b.com')).called(1);
      expect(states, const [KycEmailCodeVerifying()]);
      await sub.cancel();
    });

    test('a late register/email answer does not emit or throw', () async {
      final pending = Completer<RegistrationEmailStatus>();
      when(() => service.registerEmail(any())).thenAnswer((_) => pending.future);
      final cubit = build();
      final states = <KycEmailCodeState>[];
      final sub = cubit.stream.listen(states.add);

      final call = cubit.resend();
      await Future<void>.delayed(Duration.zero);
      await cubit.close();
      pending.complete(RegistrationEmailStatus.emailRegistered);

      await expectLater(call, completes);
      expect(states, const [KycEmailCodeResending()]);
      await sub.cancel();
    });

    test('a late register/email error does not emit or throw', () async {
      final pending = Completer<RegistrationEmailStatus>();
      when(() => service.registerEmail(any())).thenAnswer((_) => pending.future);
      final cubit = build();

      final call = cubit.resend();
      await Future<void>.delayed(Duration.zero);
      await cubit.close();
      pending.completeError(Exception('offline'));

      await expectLater(call, completes);
    });

    test('verify and resend on a closed cubit do nothing', () async {
      final cubit = build();
      await cubit.close();

      await cubit.verify('123456');
      await cubit.resend();

      verifyNever(() => service.verifyEmail(any()));
      verifyNever(() => service.registerEmail(any()));
    });
  });

  group('states', () {
    test('compare by value', () {
      expect(
        const KycEmailCodeCompleted(RegistrationEmailStatus.emailRegistered),
        const KycEmailCodeCompleted(RegistrationEmailStatus.emailRegistered),
      );
      expect(
        const KycEmailCodeFailure(KycEmailCodeError.unknown),
        isNot(const KycEmailCodeFailure(KycEmailCodeError.invalidCode)),
      );
      expect(const KycEmailCodeResent(), const KycEmailCodeResent());
      expect(const KycEmailCodeResending().props, isEmpty);
    });
  });
}
