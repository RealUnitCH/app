import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:realunit_wallet/screens/kyc/steps/email/cubits/email_code/kyc_email_code_cubit.dart';
import 'package:realunit_wallet/screens/kyc/steps/email/subpages/kyc_email_code_page.dart';

import '../../../helper/helper.dart';

class _MockKycEmailCodeCubit extends MockCubit<KycEmailCodeState> implements KycEmailCodeCubit {}

void main() {
  // `KycEmailCodeView` (`kyc_email_code_page.dart`): the idle form, the two
  // in-flight states and every SnackBar its BlocListener shows.
  //
  // Documented skip — the code-field validation messages (`twoFaCodeRequired`
  // / `registerPhoneNumberOnlyDigits` / `twoFaCodeTooShort`) render only after
  // the Next button runs `_formKey.currentState!.validate()`. The `Form` has no
  // `autovalidateMode` and no state mirrors the validator output, so the
  // message is purely interaction-driven with no State seam — a text-field
  // validate() error, skipped per the golden-states convention (same as
  // `kyc_2fa_states_golden_test.dart`).
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

    // unknown with API text → red SnackBar showing that text as-is.
    goldenTest(
      'other failure — red snackbar with the API message',
      fileName: 'kyc_email_code_page_error_snackbar',
      constraints: phoneConstraints,
      pumpBeforeTest: settleSnackBar,
      builder: () {
        emit(
          const KycEmailCodeFailure(
            KycEmailCodeError.unknown,
            message: 'ThrottlerException: Too Many Requests',
          ),
        );
        return buildSubject();
      },
    );

    // unknown without API text → red `registerEmailCodeFailed` SnackBar.
    goldenTest(
      'other failure without API text — red generic snackbar',
      fileName: 'kyc_email_code_page_failed_snackbar',
      constraints: phoneConstraints,
      pumpBeforeTest: settleSnackBar,
      builder: () {
        emit(const KycEmailCodeFailure(KycEmailCodeError.unknown));
        return buildSubject();
      },
    );
  });
}
