import 'package:alchemist/alchemist.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:realunit_wallet/screens/kyc/cubits/kyc/kyc_cubit.dart';
import 'package:realunit_wallet/screens/kyc/steps/financial_data/cubits/kyc_financial_data_cubit.dart';
import 'package:realunit_wallet/screens/kyc/steps/financial_data/kyc_financial_data_page.dart';

import '../../../helper/helper.dart';

class _MockKycFinancialDataCubit extends MockCubit<KycFinancialDataState>
    implements KycFinancialDataCubit {}

class _MockKycCubit extends MockCubit<KycState> implements KycCubit {}

void main() {

  late _MockKycFinancialDataCubit financialDataCubit;
  late _MockKycCubit kycCubit;

  setUp(() {
    financialDataCubit = _MockKycFinancialDataCubit();
    kycCubit = _MockKycCubit();

    when(() => financialDataCubit.state)
        .thenReturn(const KycFinancialDataLoading());
    when(() => kycCubit.state).thenReturn(const KycInitial());
  });

  group('$KycFinancialDataView', () {
    goldenTest(
      'loading state',
      fileName: 'kyc_financial_data_page_default',
      // CircularProgressIndicator never settles; pump once to capture the
      // initial frame instead of letting pumpAndSettle hang.
      pumpBeforeTest: pumpOnce,
      constraints: phoneConstraints,
      builder: () => wrapForGolden(
        MultiBlocProvider(
          providers: [
            BlocProvider<KycFinancialDataCubit>.value(value: financialDataCubit),
            BlocProvider<KycCubit>.value(value: kycCubit),
          ],
          child: const KycFinancialDataView(),
        ),
      ),
    );
  });
}
