import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:realunit_wallet/screens/kyc/cubits/kyc/kyc_cubit.dart';
import 'package:realunit_wallet/screens/kyc/steps/email/cubits/email_step/kyc_email_step_cubit.dart';
import 'package:realunit_wallet/screens/kyc/steps/email/kyc_email_page.dart';

import '../../../helper/helper.dart';

class _MockKycEmailStepCubit extends MockCubit<KycEmailStepState>
    implements KycEmailStepCubit {}

class _MockKycCubit extends MockCubit<KycState> implements KycCubit {}

void main() {

  late _MockKycEmailStepCubit emailStepCubit;
  late _MockKycCubit kycCubit;

  setUp(() {
    emailStepCubit = _MockKycEmailStepCubit();
    kycCubit = _MockKycCubit();

    when(() => emailStepCubit.state).thenReturn(const KycEmailStepInitial());
    when(() => kycCubit.state).thenReturn(const KycInitial());
  });

  Widget buildSubject() => MultiBlocProvider(
        providers: [
          BlocProvider<KycEmailStepCubit>.value(value: emailStepCubit),
          BlocProvider<KycCubit>.value(value: kycCubit),
        ],
        child: const KycEmailView(),
      );

  group('$KycEmailView', () {
    goldenTest(
      'initial empty state',
      fileName: 'kyc_email_page_default',
      constraints: phoneConstraints,
      builder: () => wrapForGolden(buildSubject()),
    );

    goldenTest(
      'loading',
      fileName: 'kyc_email_page_loading',
      constraints: phoneConstraints,
      pumpBeforeTest: pumpOnce,
      builder: () {
        when(() => emailStepCubit.state)
            .thenReturn(const KycEmailStepLoading());
        return wrapForGolden(buildSubject());
      },
    );

    goldenTest(
      'email does not match failure',
      fileName: 'kyc_email_page_does_not_match',
      constraints: phoneConstraints,
      builder: () {
        when(() => emailStepCubit.state).thenReturn(
          const KycEmailStepFailure(
            KycEmailStepError.emailDoesNotMatch,
            'Diese E-Mail-Adresse stimmt nicht überein.',
          ),
        );
        return wrapForGolden(buildSubject());
      },
    );

    goldenTest(
      'unknown failure',
      fileName: 'kyc_email_page_unknown_error',
      constraints: phoneConstraints,
      builder: () {
        when(() => emailStepCubit.state).thenReturn(
          const KycEmailStepFailure(
            KycEmailStepError.unknown,
            'Unbekannter Fehler.',
          ),
        );
        return wrapForGolden(buildSubject());
      },
    );
  });
}
