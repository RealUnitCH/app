import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:realunit_wallet/screens/home/bloc/home_bloc.dart';
import 'package:realunit_wallet/screens/kyc/steps/email/cubits/email_verification/kyc_email_verification_cubit.dart';
import 'package:realunit_wallet/screens/kyc/steps/email/subpages/kyc_email_verification_page.dart';

import '../../../helper/helper.dart';

class _MockKycEmailVerificationCubit extends MockCubit<KycEmailVerificationState>
    implements KycEmailVerificationCubit {}

void main() {

  late _MockKycEmailVerificationCubit verificationCubit;
  late MockHomeBloc homeBloc;

  setUp(() {
    verificationCubit = _MockKycEmailVerificationCubit();
    homeBloc = MockHomeBloc();

    when(() => verificationCubit.state).thenReturn(
      const KycEmailVerificationInitial(),
    );
    when(() => homeBloc.state).thenReturn(const HomeState());
  });

  group('$KycEmailVerificationView', () {
    goldenTest(
      'initial state',
      fileName: 'kyc_email_verification_page_default',
      constraints: phoneConstraints,
      builder: () => wrapForGolden(
        MultiBlocProvider(
          providers: [
            BlocProvider<KycEmailVerificationCubit>.value(
              value: verificationCubit,
            ),
            BlocProvider<HomeBloc>.value(value: homeBloc),
          ],
          child: const KycEmailVerificationView(),
        ),
      ),
    );
  });
}
