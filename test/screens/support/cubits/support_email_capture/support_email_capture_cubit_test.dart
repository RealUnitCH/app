import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:realunit_wallet/packages/service/dfx/exceptions/api_exception.dart';
import 'package:realunit_wallet/packages/service/dfx/exceptions/request_timeout_exception.dart';
import 'package:realunit_wallet/packages/service/dfx/models/registration/registration_email_status.dart';
import 'package:realunit_wallet/packages/service/dfx/real_unit_registration_service.dart';
import 'package:realunit_wallet/screens/support/cubits/support_email_capture/support_email_capture_cubit.dart';

class _MockRegistrationService extends Mock implements RealUnitRegistrationService {}

void main() {
  late _MockRegistrationService service;

  setUp(() {
    service = _MockRegistrationService();
  });

  SupportEmailCaptureCubit build() => SupportEmailCaptureCubit(service);

  group('initial state', () {
    test('emits $SupportEmailCaptureInitial', () {
      expect(build().state, isA<SupportEmailCaptureInitial>());
    });
  });

  group('submit', () {
    blocTest<SupportEmailCaptureCubit, SupportEmailCaptureState>(
      'emailRegistered → Loading → Success',
      setUp: () => when(() => service.registerEmail(any())).thenAnswer(
        (_) async => RegistrationEmailStatus.emailRegistered,
      ),
      build: build,
      act: (c) => c.submit('a@b.com'),
      expect: () => const [
        SupportEmailCaptureLoading(),
        SupportEmailCaptureSuccess(),
      ],
      verify: (_) {
        verify(() => service.registerEmail('a@b.com')).called(1);
      },
    );

    blocTest<SupportEmailCaptureCubit, SupportEmailCaptureState>(
      'mergeRequested → Loading → MergeRequested',
      setUp: () => when(() => service.registerEmail(any())).thenAnswer(
        (_) async => RegistrationEmailStatus.mergeRequested,
      ),
      build: build,
      act: (c) => c.submit('a@b.com'),
      expect: () => const [
        SupportEmailCaptureLoading(),
        SupportEmailCaptureMergeRequested(),
      ],
    );

    blocTest<SupportEmailCaptureCubit, SupportEmailCaptureState>(
      'verificationCodeSent → Loading → CodeSent carrying the submitted email',
      setUp: () => when(() => service.registerEmail(any())).thenAnswer(
        (_) async => RegistrationEmailStatus.verificationCodeSent,
      ),
      build: build,
      act: (c) => c.submit('a@b.com'),
      expect: () => const [
        SupportEmailCaptureLoading(),
        SupportEmailCaptureCodeSent('a@b.com'),
      ],
    );

    test('CodeSent props pin the email', () {
      expect(const SupportEmailCaptureCodeSent('a@b.com'), const SupportEmailCaptureCodeSent('a@b.com'));
      expect(const SupportEmailCaptureCodeSent('a@b.com'), isNot(const SupportEmailCaptureCodeSent('c@d.com')));
    });

    blocTest<SupportEmailCaptureCubit, SupportEmailCaptureState>(
      'ApiException → Failure carrying the api message',
      setUp: () => when(() => service.registerEmail(any())).thenAnswer(
        (_) async => throw const ApiException(
          code: 'SOMETHING_ELSE',
          message: 'rejected by server',
        ),
      ),
      build: build,
      act: (c) => c.submit('a@b.com'),
      expect: () => [
        const SupportEmailCaptureLoading(),
        isA<SupportEmailCaptureFailure>()
            .having((s) => s.message, 'message', 'rejected by server'),
      ],
    );

    blocTest<SupportEmailCaptureCubit, SupportEmailCaptureState>(
      'non-Api exception → Failure carrying e.toString()',
      setUp: () => when(() => service.registerEmail(any())).thenAnswer(
        (_) async => throw Exception('socket down'),
      ),
      build: build,
      act: (c) => c.submit('a@b.com'),
      expect: () => [
        const SupportEmailCaptureLoading(),
        isA<SupportEmailCaptureFailure>()
            .having((s) => s.message, 'message', contains('socket down')),
      ],
    );
  });

  group('timeout', () {
    blocTest<SupportEmailCaptureCubit, SupportEmailCaptureState>(
      'a request timeout is TimedOut, not a failure with the exception text',
      setUp: () => when(() => service.registerEmail(any())).thenThrow(const RequestTimeoutException(Duration(seconds: 20))),
      build: build,
      act: (c) => c.submit('a@b.com'),
      expect: () => const [
        SupportEmailCaptureLoading(),
        SupportEmailCaptureTimedOut(),
      ],
    );
  });

  test('a second submit while register/email runs is ignored', () async {
    final pending = Completer<RegistrationEmailStatus>();
    when(() => service.registerEmail(any())).thenAnswer((_) => pending.future);
    final cubit = build();

    final first = cubit.submit('a@b.com');
    final second = cubit.submit('a@b.com');
    pending.complete(RegistrationEmailStatus.verificationCodeSent);
    await Future.wait([first, second]);

    verify(() => service.registerEmail('a@b.com')).called(1);
    await cubit.close();
  });

  blocTest<SupportEmailCaptureCubit, SupportEmailCaptureState>(
    'a sign-in timeout before the request is not reported as a server timeout',
    setUp: () => when(() => service.registerEmail(any())).thenThrow(TimeoutException('signature')),
    build: build,
    act: (c) => c.submit('a@b.com'),
    expect: () => [
      const SupportEmailCaptureLoading(),
      isA<SupportEmailCaptureFailure>(),
    ],
  );

  group('closed while register/email is in flight', () {
    for (final outcome in ['status', 'api error', 'other error']) {
      test('a late $outcome does not emit or throw', () async {
        final pending = Completer<RegistrationEmailStatus>();
        when(() => service.registerEmail(any())).thenAnswer((_) => pending.future);
        final cubit = build();
        final states = <SupportEmailCaptureState>[];
        final sub = cubit.stream.listen(states.add);

        final call = cubit.submit('a@b.com');
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
        expect(states, const [SupportEmailCaptureLoading()]);
        await sub.cancel();
      });
    }
  });
}
