import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:mocktail/mocktail.dart';
import 'package:realunit_wallet/generated/i18n.dart';
import 'package:realunit_wallet/packages/service/dfx/models/registration/registration_email_status.dart';
import 'package:realunit_wallet/packages/service/dfx/real_unit_registration_service.dart';
import 'package:realunit_wallet/screens/kyc/steps/email/cubits/email_code/kyc_email_code_cubit.dart';
import 'package:realunit_wallet/screens/kyc/steps/email/subpages/kyc_email_code_page.dart';

import '../../../../helper/pump_app.dart';

class _MockKycEmailCodeCubit extends MockCubit<KycEmailCodeState> implements KycEmailCodeCubit {}

class _MockRegistrationService extends Mock implements RealUnitRegistrationService {}

void main() {
  late _MockKycEmailCodeCubit cubit;

  setUp(() {
    cubit = _MockKycEmailCodeCubit();
    when(() => cubit.state).thenReturn(const KycEmailCodeInitial());
    when(() => cubit.email).thenReturn('a@b.com');
    when(() => cubit.verify(any())).thenAnswer((_) async {});
    when(() => cubit.resend()).thenAnswer((_) async {});
  });

  Widget buildSubject() => BlocProvider<KycEmailCodeCubit>.value(
    value: cubit,
    child: const KycEmailCodeView(),
  );

  Finder nextButton() => find.widgetWithText(FilledButton, S.current.next);

  Finder resendButton() => find.widgetWithText(TextButton, S.current.twoFaResendCode);

  group('$KycEmailCodePage', () {
    setUp(() => GetIt.instance.registerSingleton<RealUnitRegistrationService>(_MockRegistrationService()));
    tearDown(() async => GetIt.instance.reset());

    testWidgets('provides a cubit for the given address', (tester) async {
      await tester.pumpApp(const KycEmailCodePage(email: 'x@y.com'));

      expect(find.byType(KycEmailCodeView), findsOne);
      final element = tester.element(find.byType(KycEmailCodeView));
      expect(element.read<KycEmailCodeCubit>().email, 'x@y.com');
    });
  });

  group('$KycEmailCodeView', () {
    testWidgets('names the address the code was sent to', (tester) async {
      await tester.pumpApp(buildSubject());

      expect(find.text(S.current.registerEmailCode), findsOne);
      expect(find.text(S.current.registerEmailCodeTitle), findsOne);
      expect(find.text(S.current.registerEmailCodeDescription('a@b.com')), findsOne);
    });

    testWidgets('an empty code is refused before any call', (tester) async {
      await tester.pumpApp(buildSubject());

      await tester.tap(nextButton());
      await tester.pump();

      expect(find.text(S.current.twoFaCodeRequired), findsOne);
      verifyNever(() => cubit.verify(any()));
    });

    testWidgets('a code with letters is refused', (tester) async {
      await tester.pumpApp(buildSubject());

      await tester.enterText(find.byType(TextFormField), '12a456');
      await tester.tap(nextButton());
      await tester.pump();

      expect(find.text(S.current.registerPhoneNumberOnlyDigits), findsOne);
      verifyNever(() => cubit.verify(any()));
    });

    testWidgets('a code shorter than six digits is refused', (tester) async {
      await tester.pumpApp(buildSubject());

      await tester.enterText(find.byType(TextFormField), '123');
      await tester.tap(nextButton());
      await tester.pump();

      expect(find.text(S.current.twoFaCodeTooShort), findsOne);
      verifyNever(() => cubit.verify(any()));
    });

    testWidgets('a six-digit code is confirmed', (tester) async {
      await tester.pumpApp(buildSubject());

      await tester.enterText(find.byType(TextFormField), '123456');
      await tester.tap(nextButton());
      await tester.pump();

      verify(() => cubit.verify('123456')).called(1);
    });

    testWidgets('resend calls register/email again through the cubit', (tester) async {
      await tester.pumpApp(buildSubject());

      await tester.tap(resendButton());
      await tester.pump();

      verify(() => cubit.resend()).called(1);
    });

    testWidgets('while verifying both buttons are disabled', (tester) async {
      when(() => cubit.state).thenReturn(const KycEmailCodeVerifying());

      await tester.pumpApp(buildSubject());

      expect(tester.widget<FilledButton>(find.bySubtype<FilledButton>()).onPressed, isNull);
      expect(tester.widget<TextButton>(resendButton()).onPressed, isNull);
    });

    testWidgets('while resending the resend label says sending and both buttons are disabled', (
      tester,
    ) async {
      when(() => cubit.state).thenReturn(const KycEmailCodeResending());

      await tester.pumpApp(buildSubject());

      final sending = find.widgetWithText(TextButton, '${S.current.sending}...');
      expect(sending, findsOne);
      expect(tester.widget<TextButton>(sending).onPressed, isNull);
      expect(tester.widget<FilledButton>(find.bySubtype<FilledButton>()).onPressed, isNull);
    });

    testWidgets('a new code clears the field and says so', (tester) async {
      final controller = StreamController<KycEmailCodeState>();
      whenListen(cubit, controller.stream, initialState: const KycEmailCodeInitial());

      await tester.pumpApp(buildSubject());
      await tester.enterText(find.byType(TextFormField), '111111');
      controller.add(const KycEmailCodeResent());
      await tester.pump();

      expect(find.text(S.current.registerEmailCodeResent), findsOne);
      expect(find.text('111111'), findsNothing);
      await controller.close();
    });

    testWidgets('a wrong or expired code shows the code error', (tester) async {
      whenListen(
        cubit,
        Stream.value(const KycEmailCodeFailure(KycEmailCodeError.invalidCode)),
        initialState: const KycEmailCodeInitial(),
      );

      await tester.pumpApp(buildSubject());
      await tester.pump();

      expect(find.text(S.current.registerEmailCodeInvalid), findsOne);
    });

    testWidgets('another failure shows the API message', (tester) async {
      whenListen(
        cubit,
        Stream.value(const KycEmailCodeFailure(KycEmailCodeError.unknown, message: 'Too many requests')),
        initialState: const KycEmailCodeInitial(),
      );

      await tester.pumpApp(buildSubject());
      await tester.pump();

      expect(find.text('Too many requests'), findsOne);
    });

    testWidgets('a failure without API text shows the generic message', (tester) async {
      whenListen(
        cubit,
        Stream.value(const KycEmailCodeFailure(KycEmailCodeError.unknown)),
        initialState: const KycEmailCodeInitial(),
      );

      await tester.pumpApp(buildSubject());
      await tester.pump();

      expect(find.text(S.current.registerEmailCodeFailed), findsOne);
    });

    for (final status in [RegistrationEmailStatus.emailRegistered, RegistrationEmailStatus.mergeRequested]) {
      testWidgets('pops with ${status.name} when the email step is finished', (tester) async {
        whenListen(
          cubit,
          Stream.value(KycEmailCodeCompleted(status)),
          initialState: const KycEmailCodeInitial(),
        );
        RegistrationEmailStatus? result;

        await tester.pumpApp(
          Builder(
            builder: (context) => TextButton(
              onPressed: () async {
                result = await Navigator.of(context).push<RegistrationEmailStatus>(
                  MaterialPageRoute(builder: (_) => buildSubject()),
                );
              },
              child: const Text('open'),
            ),
          ),
        );
        await tester.tap(find.text('open'));
        await tester.pumpAndSettle();

        expect(result, status);
        expect(find.byType(KycEmailCodeView), findsNothing);
      });
    }

    testWidgets('a completion after the user left does not pop the route below', (tester) async {
      final controller = StreamController<KycEmailCodeState>();
      whenListen(cubit, controller.stream, initialState: const KycEmailCodeInitial());
      Object? result = 'unset';

      await tester.pumpApp(
        Builder(
          builder: (context) => TextButton(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (context) => Scaffold(
                  body: TextButton(
                    onPressed: () async {
                      result = await Navigator.of(context).push<RegistrationEmailStatus>(
                        MaterialPageRoute(builder: (_) => buildSubject()),
                      );
                    },
                    child: const Text('middle'),
                  ),
                ),
              ),
            ),
            child: const Text('open'),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('middle'));
      await tester.pumpAndSettle();

      // The user backs out while the request is in flight; the exit animation
      // still runs when the late completion arrives.
      Navigator.of(tester.element(find.byType(KycEmailCodeView))).pop();
      await tester.pump(const Duration(milliseconds: 50));
      expect(find.byType(KycEmailCodeView), findsOne);
      controller.add(const KycEmailCodeCompleted(RegistrationEmailStatus.emailRegistered));
      await tester.pumpAndSettle();

      expect(result, isNull);
      expect(find.text('middle'), findsOne);
      expect(find.byType(KycEmailCodeView), findsNothing);
      await controller.close();
    });
  });
}
