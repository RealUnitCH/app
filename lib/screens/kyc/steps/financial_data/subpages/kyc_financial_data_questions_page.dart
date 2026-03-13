import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:realunit_wallet/generated/i18n.dart';
import 'package:realunit_wallet/packages/service/dfx/models/kyc/dto/kyc_financial_data_dto.dart';
import 'package:realunit_wallet/screens/kyc/steps/financial_data/constants/kyc_financial_data_links.dart';
import 'package:realunit_wallet/screens/kyc/steps/financial_data/cubits/kyc_financial_data_cubit.dart';
import 'package:realunit_wallet/screens/kyc/steps/financial_data/widgets/kyc_question_checkbox_widget.dart';
import 'package:realunit_wallet/screens/kyc/steps/financial_data/widgets/kyc_question_multiple_choice_widget.dart';
import 'package:realunit_wallet/screens/kyc/steps/financial_data/widgets/kyc_question_single_choice_widget.dart';
import 'package:realunit_wallet/screens/kyc/steps/financial_data/widgets/kyc_question_text_field_widget.dart';
import 'package:realunit_wallet/screens/web_view/web_view_page.dart';
import 'package:realunit_wallet/styles/colors.dart';

class KycFinancialDataQuestionsPage extends StatelessWidget {
  final KycFinancialDataLoadedSuccess state;

  const KycFinancialDataQuestionsPage(this.state, {super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(S.of(context).financialData),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: state.isFirstQuestion
              ? context.pop
              : context.read<KycFinancialDataCubit>().goBack,
        ),
      ),
      body: Padding(
        padding: const .symmetric(horizontal: 20),
        child: LayoutBuilder(
          builder: (context, constraint) {
            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraint.maxHeight,
                ),
                child: IntrinsicHeight(
                  child: SafeArea(
                    child: Column(
                      spacing: 16.0,
                      crossAxisAlignment: .start,
                      children: [
                        Column(
                          spacing: 24.0,
                          crossAxisAlignment: .start,
                          children: [
                            Text(
                              S
                                  .of(context)
                                  .financialDataQuestion(
                                    '${state.currentIndex + 1}',
                                    '${state.visibleQuestions.length}',
                                  ),
                              style:
                                  Theme.of(
                                    context,
                                  ).textTheme.bodyMedium?.copyWith(
                                    color: RealUnitColors.neutral500,
                                  ),
                            ),
                            Column(
                              crossAxisAlignment: .start,
                              spacing: 16.0,
                              children: [
                                Text(
                                  state.currentQuestion.title,
                                  style: Theme.of(
                                    context,
                                  ).textTheme.headlineSmall,
                                ),
                                if (state.currentQuestion.description != null)
                                  _buildDescription(context, state.currentQuestion),
                              ],
                            ),
                          ],
                        ),
                        _buildQuestionWidget(context, state),
                        const Spacer(),
                        Padding(
                          padding: const .symmetric(vertical: 16.0),
                          child: SizedBox(
                            width: .infinity,
                            child: FilledButton(
                              onPressed: state.hasAnswer
                                  ? () => context.read<KycFinancialDataCubit>().submitAndNext()
                                  : null,
                              child: Text(
                                state.isLastQuestion ? S.of(context).complete : S.of(context).next,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildDescription(BuildContext context, KycFinancialQuestion question) {
    final link = question.key == 'tnc'
        ? KycFinancialDataLinks.termsAndConditionsUrl
        : question.key == 'notification_of_changes'
        ? KycFinancialDataLinks.supportUrl
        : null;

    if (link != null) {
      return GestureDetector(
        onTap: () => context.push(
          '/webView',
          extra: WebViewRouteParams(
            title: question.title,
            url: Uri.parse(link),
          ),
        ),
        child: Text(
          question.description ?? '',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: RealUnitColors.realUnitBlue,
            decorationColor: RealUnitColors.realUnitBlue,
            decoration: TextDecoration.underline,
          ),
        ),
      );
    }

    return Text(
      question.description ?? '',
      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
        color: RealUnitColors.neutral500,
      ),
    );
  }

  Widget _buildQuestionWidget(BuildContext context, KycFinancialDataLoadedSuccess state) {
    final question = state.currentQuestion;
    final currentResponse = state.currentResponse;

    switch (question.type) {
      case QuestionType.checkbox:
        final optionKey = question.options?.firstOrNull?.key ?? 'accept';
        return KycQuestionCheckboxWidget(
          question: question,
          value: currentResponse == optionKey,
          onChanged: (value) => context.read<KycFinancialDataCubit>().answerQuestion(
            question.key,
            value ? optionKey : '',
          ),
        );
      case QuestionType.singleChoice:
        return KycQuestionSingleChoiceWidget(
          question: question,
          selectedKey: currentResponse,
          onChanged: (value) =>
              context.read<KycFinancialDataCubit>().answerQuestion(question.key, value),
        );
      case QuestionType.multipleChoice:
        return KycQuestionMultipleChoiceWidget(
          question: question,
          selectedKeys: currentResponse?.split(',').where((s) => s.isNotEmpty).toSet() ?? {},
          onChanged: (values) =>
              context.read<KycFinancialDataCubit>().answerQuestion(question.key, values.join(',')),
        );
      case QuestionType.text:
        return KycQuestionTextFieldWidget(
          question: question,
          value: currentResponse ?? '',
          onChanged: (value) =>
              context.read<KycFinancialDataCubit>().answerQuestion(question.key, value),
        );
    }
  }
}
