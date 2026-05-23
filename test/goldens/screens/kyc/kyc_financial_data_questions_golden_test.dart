import 'package:alchemist/alchemist.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:realunit_wallet/packages/service/dfx/models/kyc/dto/kyc_financial_data_dto.dart';
import 'package:realunit_wallet/screens/kyc/steps/financial_data/cubits/kyc_financial_data_cubit.dart';
import 'package:realunit_wallet/screens/kyc/steps/financial_data/subpages/kyc_financial_data_questions_page.dart';

import '../../../helper/helper.dart';

class _MockKycFinancialDataCubit extends MockCubit<KycFinancialDataState>
    implements KycFinancialDataCubit {}

void main() {
  const phoneConstraints = BoxConstraints.tightFor(width: 390, height: 844);

  late _MockKycFinancialDataCubit financialDataCubit;

  const question = KycFinancialQuestion(
    key: 'q1',
    type: QuestionType.text,
    title: 'What is your annual income?',
    description: 'Please provide a rough estimate.',
  );

  const loadedState = KycFinancialDataLoadedSuccess(
    allQuestions: [question],
    visibleQuestions: [question],
    responses: {},
    currentIndex: 0,
    url: 'https://example.com',
  );

  setUp(() {
    financialDataCubit = _MockKycFinancialDataCubit();
    when(() => financialDataCubit.state).thenReturn(loadedState);
  });

  group('$KycFinancialDataQuestionsPage', () {
    goldenTest(
      'text question, empty response',
      fileName: 'kyc_financial_data_questions_page_default',
      constraints: phoneConstraints,
      builder: () => wrapForGolden(
        BlocProvider<KycFinancialDataCubit>.value(
          value: financialDataCubit,
          child: const KycFinancialDataQuestionsPage(loadedState),
        ),
      ),
    );
  });
}
