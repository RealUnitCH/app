import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:realunit_wallet/screens/kyc/cubits/kyc/kyc_cubit.dart';
import 'package:realunit_wallet/screens/kyc/steps/confirm_email/cubits/kyc_confirm_email_cubit.dart';
import 'package:realunit_wallet/screens/kyc/steps/confirm_email/kyc_confirm_email_page.dart';

import '../../../helper/helper.dart';

class _MockKycConfirmEmailCubit extends MockCubit<KycConfirmEmailState>
    implements KycConfirmEmailCubit {}

class _MockKycCubit extends MockCubit<KycState> implements KycCubit {}

void main() {
  late _MockKycConfirmEmailCubit confirmCubit;
  late _MockKycCubit kycCubit;

  setUp(() {
    confirmCubit = _MockKycConfirmEmailCubit();
    kycCubit = _MockKycCubit();

    when(() => confirmCubit.state).thenReturn(const KycConfirmEmailInitial());
    when(() => kycCubit.state).thenReturn(const KycInitial());
  });

  group('$KycConfirmEmailView', () {
    goldenTest(
      'initial state',
      fileName: 'kyc_confirm_email_page_default',
      constraints: phoneConstraints,
      builder: () => wrapForGolden(
        MultiBlocProvider(
          providers: [
            BlocProvider<KycCubit>.value(value: kycCubit),
            BlocProvider<KycConfirmEmailCubit>.value(value: confirmCubit),
          ],
          child: const KycConfirmEmailView(),
        ),
      ),
    );
  });
}
