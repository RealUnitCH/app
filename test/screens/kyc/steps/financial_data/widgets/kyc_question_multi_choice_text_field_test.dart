import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:realunit_wallet/packages/service/dfx/models/kyc/dto/kyc_financial_data_dto.dart';
import 'package:realunit_wallet/screens/kyc/steps/financial_data/widgets/kyc_question_multiple_choice_widget.dart';
import 'package:realunit_wallet/screens/kyc/steps/financial_data/widgets/kyc_question_text_field_widget.dart';

Widget _host(Widget child) => MaterialApp(home: Scaffold(body: child));

const _multiQuestion = KycFinancialQuestion(
  key: 'q1',
  type: QuestionType.multipleChoice,
  title: 'Pick any',
  options: [
    KycFinancialOption(key: 'a', text: 'Option A'),
    KycFinancialOption(key: 'b', text: 'Option B'),
    KycFinancialOption(key: 'c', text: 'Option C'),
  ],
);

const _textQuestion = KycFinancialQuestion(
  key: 'q2',
  type: QuestionType.text,
  title: 'Tell us why',
);

void main() {
  group('$KycQuestionMultipleChoiceWidget', () {
    testWidgets('renders one CheckboxListTile per option', (tester) async {
      await tester.pumpWidget(_host(
        KycQuestionMultipleChoiceWidget(
          question: _multiQuestion,
          selectedKeys: const {},
          onChanged: (_) {},
        ),
      ));

      expect(find.byType(CheckboxListTile), findsNWidgets(3));
      expect(find.text('Option A'), findsOneWidget);
      expect(find.text('Option B'), findsOneWidget);
      expect(find.text('Option C'), findsOneWidget);
    });

    testWidgets('selectedKeys controls which tiles are checked', (tester) async {
      await tester.pumpWidget(_host(
        KycQuestionMultipleChoiceWidget(
          question: _multiQuestion,
          selectedKeys: const {'b'},
          onChanged: (_) {},
        ),
      ));

      final tiles = tester.widgetList<CheckboxListTile>(find.byType(CheckboxListTile)).toList();
      expect(tiles[0].value, isFalse);
      expect(tiles[1].value, isTrue); // B
      expect(tiles[2].value, isFalse);
    });

    testWidgets('tapping an unchecked tile ADDS the key to the selection',
        (tester) async {
      Set<String>? lastEmitted;
      await tester.pumpWidget(_host(
        KycQuestionMultipleChoiceWidget(
          question: _multiQuestion,
          selectedKeys: const {'a'},
          onChanged: (s) => lastEmitted = s,
        ),
      ));

      await tester.tap(find.text('Option B'));
      await tester.pump();

      expect(lastEmitted, {'a', 'b'});
    });

    testWidgets('tapping a checked tile REMOVES the key from the selection',
        (tester) async {
      Set<String>? lastEmitted;
      await tester.pumpWidget(_host(
        KycQuestionMultipleChoiceWidget(
          question: _multiQuestion,
          selectedKeys: const {'a', 'b'},
          onChanged: (s) => lastEmitted = s,
        ),
      ));

      await tester.tap(find.text('Option A'));
      await tester.pump();

      expect(lastEmitted, {'b'});
    });

    testWidgets('no options: renders empty Column (no CheckboxListTiles)',
        (tester) async {
      const empty = KycFinancialQuestion(
        key: 'q',
        type: QuestionType.multipleChoice,
        title: 't',
      );
      await tester.pumpWidget(_host(
        KycQuestionMultipleChoiceWidget(
          question: empty,
          selectedKeys: const {},
          onChanged: (_) {},
        ),
      ));

      expect(find.byType(CheckboxListTile), findsNothing);
    });
  });

  group('$KycQuestionTextFieldWidget', () {
    testWidgets('initial value seeds the TextField', (tester) async {
      await tester.pumpWidget(_host(
        KycQuestionTextFieldWidget(
          question: _textQuestion,
          value: 'preset answer',
          onChanged: (_) {},
        ),
      ));

      expect(find.text('preset answer'), findsOneWidget);
    });

    testWidgets('typing fires onChanged with the new text', (tester) async {
      String? lastEmitted;
      await tester.pumpWidget(_host(
        KycQuestionTextFieldWidget(
          question: _textQuestion,
          value: '',
          onChanged: (v) => lastEmitted = v,
        ),
      ));

      await tester.enterText(find.byType(TextField), 'because');
      expect(lastEmitted, 'because');
    });

    testWidgets('hintText is the question.title', (tester) async {
      await tester.pumpWidget(_host(
        KycQuestionTextFieldWidget(
          question: _textQuestion,
          value: '',
          onChanged: (_) {},
        ),
      ));

      final field = tester.widget<TextField>(find.byType(TextField));
      expect(field.decoration!.hintText, 'Tell us why');
    });
  });
}
