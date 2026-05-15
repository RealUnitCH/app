import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:realunit_wallet/packages/service/dfx/models/kyc/dto/kyc_financial_data_dto.dart';
import 'package:realunit_wallet/screens/kyc/steps/financial_data/widgets/kyc_question_single_choice_widget.dart';

Widget _host(Widget child) => MaterialApp(home: Scaffold(body: child));

const _question = KycFinancialQuestion(
  key: 'q1',
  type: QuestionType.singleChoice,
  title: 'Pick one',
  options: [
    KycFinancialOption(key: 'a', text: 'Option A'),
    KycFinancialOption(key: 'b', text: 'Option B'),
    KycFinancialOption(key: 'c', text: 'Option C'),
  ],
);

void main() {
  group('$KycQuestionSingleChoiceWidget', () {
    testWidgets('renders one ListTile per option with the option text',
        (tester) async {
      await tester.pumpWidget(_host(
        KycQuestionSingleChoiceWidget(
          question: _question,
          selectedKey: null,
          onChanged: (_) {},
        ),
      ));

      expect(find.text('Option A'), findsOneWidget);
      expect(find.text('Option B'), findsOneWidget);
      expect(find.text('Option C'), findsOneWidget);
      expect(find.byType(ListTile), findsNWidgets(3));
    });

    testWidgets('no options: renders an empty Column (no ListTiles)',
        (tester) async {
      const noOptions = KycFinancialQuestion(
        key: 'q2',
        type: QuestionType.singleChoice,
        title: 'Empty',
      );

      await tester.pumpWidget(_host(
        KycQuestionSingleChoiceWidget(
          question: noOptions,
          selectedKey: null,
          onChanged: (_) {},
        ),
      ));

      expect(find.byType(ListTile), findsNothing);
    });

    testWidgets('tapping a ListTile fires onChanged with the option key',
        (tester) async {
      String? picked;
      await tester.pumpWidget(_host(
        KycQuestionSingleChoiceWidget(
          question: _question,
          selectedKey: null,
          onChanged: (v) => picked = v,
        ),
      ));

      await tester.tap(find.text('Option B'));
      await tester.pump();

      expect(picked, 'b');
    });
  });
}
