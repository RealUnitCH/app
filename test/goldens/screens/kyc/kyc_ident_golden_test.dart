import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:realunit_wallet/screens/kyc/cubits/kyc/kyc_cubit.dart';
import 'package:realunit_wallet/screens/kyc/steps/ident/cubits/kyc_ident/kyc_ident_cubit.dart';
import 'package:realunit_wallet/screens/kyc/steps/ident/kyc_ident_page.dart';
import 'package:realunit_wallet/screens/settings/bloc/settings_bloc.dart';

import '../../../helper/helper.dart';

class _MockKycIdentCubit extends MockCubit<KycIdentState>
    implements KycIdentCubit {}

class _MockKycCubit extends MockCubit<KycState> implements KycCubit {}

void main() {

  late _MockKycIdentCubit kycIdentCubit;
  late _MockKycCubit kycCubit;
  late MockSettingsBloc settingsBloc;

  setUp(() {
    kycIdentCubit = _MockKycIdentCubit();
    kycCubit = _MockKycCubit();
    settingsBloc = MockSettingsBloc();

    when(() => kycIdentCubit.state).thenReturn(const KycIdentInitial());
    when(() => kycCubit.state).thenReturn(const KycInitial());
    when(() => settingsBloc.state).thenReturn(const SettingsState());
  });

  group('$KycIdentView', () {
    goldenTest(
      'initial state',
      fileName: 'kyc_ident_page_default',
      constraints: phoneConstraints,
      builder: () => wrapForGolden(
        MultiBlocProvider(
          providers: [
            BlocProvider<KycIdentCubit>.value(value: kycIdentCubit),
            BlocProvider<KycCubit>.value(value: kycCubit),
            BlocProvider<SettingsBloc>.value(value: settingsBloc),
          ],
          child: const KycIdentView(accessToken: 'fake-token'),
        ),
      ),
    );
  });
}
