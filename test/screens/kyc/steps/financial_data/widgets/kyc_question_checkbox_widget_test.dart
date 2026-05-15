import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:realunit_wallet/packages/service/dfx/models/kyc/dto/kyc_financial_data_dto.dart';
import 'package:realunit_wallet/screens/kyc/steps/financial_data/widgets/kyc_question_checkbox_widget.dart';

Widget _host(Widget child) => MaterialApp(home: Scaffold(body: child));

void main() {
  group('$KycQuestionCheckboxWidget', () {
    testWidgets('falls back to question.title when options is null',
        (tester) async {
      const question = KycFinancialQuestion(
        key: 'q1',
        type: QuestionType.checkbox,
        title: 'I confirm the disclosure',
      );

      await tester.pumpWidget(_host(
        KycQuestionCheckboxWidget(
          question: question,
          value: false,
          onChanged: (_) {},
        ),
      ));

      expect(find.text('I confirm the disclosure'), findsOneWidget);
    });

    testWidgets('prefers options.firstOrNull.text over question.title',
        (tester) async {
      const question = KycFinancialQuestion(
        key: 'q1',
        type: QuestionType.checkbox,
        title: 'Generic fallback title',
        options: [
          KycFinancialOption(key: 'a', text: 'I have read the prospectus'),
        ],
      );

      await tester.pumpWidget(_host(
        KycQuestionCheckboxWidget(
          question: question,
          value: false,
          onChanged: (_) {},
        ),
      ));

      expect(find.text('I have read the prospectus'), findsOneWidget);
      // Title is suppressed when the option text wins.
      expect(find.text('Generic fallback title'), findsNothing);
    });

    testWidgets('checkbox value reflects the value prop', (tester) async {
      const question = KycFinancialQuestion(
        key: 'q1',
        type: QuestionType.checkbox,
        title: 'x',
      );

      await tester.pumpWidget(_host(
        KycQuestionCheckboxWidget(
          question: question,
          value: true,
          onChanged: (_) {},
        ),
      ));

      final tile = tester.widget<CheckboxListTile>(find.byType(CheckboxListTile));
      expect(tile.value, isTrue);
    });

    testWidgets('tap toggles onChanged with the new bool', (tester) async {
      bool? lastValue;
      const question = KycFinancialQuestion(
        key: 'q1',
        type: QuestionType.checkbox,
        title: 'tap me',
      );

      await tester.pumpWidget(_host(
        KycQuestionCheckboxWidget(
          question: question,
          value: false,
          onChanged: (v) => lastValue = v,
        ),
      ));

      await tester.tap(find.byType(CheckboxListTile));
      await tester.pump();

      expect(lastValue, isTrue);
    });

    testWidgets('null from the framework is normalised to false', (tester) async {
      bool? lastValue;
      const question = KycFinancialQuestion(
        key: 'q1',
        type: QuestionType.checkbox,
        title: 'tristate',
      );

      await tester.pumpWidget(_host(
        KycQuestionCheckboxWidget(
          question: question,
          value: false,
          onChanged: (v) => lastValue = v,
        ),
      ));

      // Manually invoke the CheckboxListTile.onChanged with null to simulate
      // a tristate clear; the widget normalises to false.
      final tile = tester.widget<CheckboxListTile>(find.byType(CheckboxListTile));
      tile.onChanged!(null);
      expect(lastValue, isFalse);
    });
  });
}
