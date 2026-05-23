import 'package:alchemist/alchemist.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
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
  const phoneConstraints = BoxConstraints.tightFor(width: 390, height: 844);

  late _MockKycEmailStepCubit emailStepCubit;
  late _MockKycCubit kycCubit;

  setUp(() {
    emailStepCubit = _MockKycEmailStepCubit();
    kycCubit = _MockKycCubit();

    when(() => emailStepCubit.state).thenReturn(const KycEmailStepInitial());
    when(() => kycCubit.state).thenReturn(const KycInitial());
  });

  group('$KycEmailView', () {
    goldenTest(
      'initial empty state',
      fileName: 'kyc_email_page_default',
      constraints: phoneConstraints,
      builder: () => wrapForGolden(
        MultiBlocProvider(
          providers: [
            BlocProvider<KycEmailStepCubit>.value(value: emailStepCubit),
            BlocProvider<KycCubit>.value(value: kycCubit),
          ],
          child: const KycEmailView(),
        ),
      ),
    );
  });
}
