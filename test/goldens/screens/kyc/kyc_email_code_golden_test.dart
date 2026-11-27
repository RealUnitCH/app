import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:realunit_wallet/screens/kyc/steps/email/cubits/email_code/kyc_email_code_cubit.dart';
import 'package:realunit_wallet/screens/kyc/steps/email/subpages/kyc_email_code_page.dart';
import 'package:realunit_wallet/widgets/buttons/app_filled_button.dart';

import '../../../helper/helper.dart';

class _MockKycEmailCodeCubit extends MockCubit<KycEmailCodeState> implements KycEmailCodeCubit {}

void main() {
  // `KycEmailCodeView` (`kyc_email_code_page.dart`): the idle form, the two
  // in-flight states, every SnackBar its BlocListener shows, and the three
  // code-field validation messages shown after the Next tap.
  late _MockKycEmailCodeCubit cubit;

  setUp(() {
    cubit = _MockKycEmailCodeCubit();
    when(() => cubit.state).thenReturn(const KycEmailCodeInitial());
    when(() => cubit.email).thenReturn('max@mustermann.ch');
  });

  Widget buildSubject() => wrapForGolden(
    BlocProvider<KycEmailCodeCubit>.value(
      value: cubit,
      child: const KycEmailCodeView(),
    ),
  );

  // Deliver the whenListen emission to the BlocListener (which fires
  // showSnackBar), then run the SnackBar entrance to completion. The 4s
  // auto-dismiss is a Timer, not a scheduled frame, so pumpAndSettle returns
  // with the SnackBar at rest.
  Future<void> settleSnackBar(WidgetTester tester) async {
    await tester.pump();
    await tester.pumpAndSettle();
  }

  void emit(KycEmailCodeState state) => whenListen(
    cubit,
    Stream<KycEmailCodeState>.value(state),
    initialState: const KycEmailCodeInitial(),
  );

  group('$KycEmailCodeView', () {
    goldenTest(
      'idle — code field, next and resend',
      fileName: 'kyc_email_code_page_default',
      constraints: phoneConstraints,
      builder: buildSubject,
    );

    // KycEmailCodeVerifying → the Next button renders its loading variant and
    // resend is disabled. Freeze the spinner on frame 0.
    goldenTest(
      'verify in flight — next button spinner',
      fileName: 'kyc_email_code_page_verifying',
      constraints: phoneConstraints,
      pumpBeforeTest: pumpOnce,
      builder: () {
        when(() => cubit.state).thenReturn(const KycEmailCodeVerifying());
        return buildSubject();
      },
    );

    // KycEmailCodeResending → both buttons disabled, resend shows "Sending…".
    goldenTest(
      'resend in flight — disabled sending label',
      fileName: 'kyc_email_code_page_resending',
      constraints: phoneConstraints,
      builder: () {
        when(() => cubit.state).thenReturn(const KycEmailCodeResending());
        return buildSubject();
      },
    );

    // KycEmailCodeResent → neutral `registerEmailCodeResent` SnackBar.
    goldenTest(
      'new code sent — snackbar',
      fileName: 'kyc_email_code_page_resent_snackbar',
      constraints: phoneConstraints,
      pumpBeforeTest: settleSnackBar,
      builder: () {
        emit(const KycEmailCodeResent());
        return buildSubject();
      },
    );

    // invalidCode (API 403) → red `registerEmailCodeInvalid` SnackBar.
    goldenTest(
      'wrong or expired code — red snackbar',
      fileName: 'kyc_email_code_page_invalid_code_snackbar',
      constraints: phoneConstraints,
      pumpBeforeTest: settleSnackBar,
      builder: () {
        emit(const KycEmailCodeFailure(KycEmailCodeError.invalidCode));
        return buildSubject();
      },
    );

    // unknown (any API or network error) → red `registerEmailCodeFailed`
    // SnackBar; the raw error text is never shown.
    goldenTest(
      'other failure — red generic snackbar',
      fileName: 'kyc_email_code_page_failed_snackbar',
      constraints: phoneConstraints,
      pumpBeforeTest: settleSnackBar,
      builder: () {
        emit(const KycEmailCodeFailure(KycEmailCodeError.unknown));
        return buildSubject();
      },
    );

    // The Next tap runs Form.validate() on the code field; the message shows
    // under the field (hideErrorText is false) and no call reaches the cubit.
    Future<void> Function(WidgetTester) submitCode(String code) => (tester) async {
      await tester.pumpAndSettle();
      if (code.isNotEmpty) {
        await tester.enterText(find.byType(EditableText), code);
      }
      await tester.tap(find.byType(AppFilledButton));
      await tester.pumpAndSettle();
    };

    // Empty field → `twoFaCodeRequired`.
    goldenTest(
      'empty code after Next — required message',
      fileName: 'kyc_email_code_page_code_required',
      constraints: phoneConstraints,
      pumpBeforeTest: submitCode(''),
      builder: buildSubject,
    );

    // A non-digit → `registerPhoneNumberOnlyDigits`.
    goldenTest(
      'code with letters after Next — digits-only message',
      fileName: 'kyc_email_code_page_code_digits_only',
      constraints: phoneConstraints,
      pumpBeforeTest: submitCode('12a456'),
      builder: buildSubject,
    );

    // Fewer than six digits → `twoFaCodeTooShort`.
    goldenTest(
      'short code after Next — six-digits message',
      fileName: 'kyc_email_code_page_code_too_short',
      constraints: phoneConstraints,
      pumpBeforeTest: submitCode('123'),
      builder: buildSubject,
    );
  });
}
