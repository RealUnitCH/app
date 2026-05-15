import 'package:flutter_test/flutter_test.dart';
import 'package:realunit_wallet/packages/service/dfx/models/kyc/dto/kyc_financial_data_dto.dart';
import 'package:realunit_wallet/packages/service/dfx/models/kyc/dto/kyc_level_dto.dart';
import 'package:realunit_wallet/packages/service/dfx/models/kyc/kyc_level.dart';

void main() {
  group('$QuestionType.fromValue', () {
    test('parses each documented wire value', () {
      expect(QuestionTypeExtension.fromValue('Confirmation'), QuestionType.checkbox);
      expect(QuestionTypeExtension.fromValue('SingleChoice'), QuestionType.singleChoice);
      expect(QuestionTypeExtension.fromValue('MultipleChoice'), QuestionType.multipleChoice);
      expect(QuestionTypeExtension.fromValue('Text'), QuestionType.text);
    });

    test('throws ArgumentError on unknown wire values', () {
      expect(
        () => QuestionTypeExtension.fromValue('Dropdown'),
        throwsA(isA<ArgumentError>()),
      );
    });
  });

  group('$KycFinancialOption.fromJson', () {
    test('parses key + text', () {
      final dto = KycFinancialOption.fromJson({'key': 'a', 'text': 'Option A'});

      expect(dto.key, 'a');
      expect(dto.text, 'Option A');
    });
  });

  group('$KycFinancialCondition.fromJson', () {
    test('parses question + response', () {
      final dto = KycFinancialCondition.fromJson({
        'question': 'q1',
        'response': 'yes',
      });

      expect(dto.question, 'q1');
      expect(dto.response, 'yes');
    });
  });

  group('$KycFinancialQuestion.fromJson', () {
    test('parses every field on the happy path', () {
      final dto = KycFinancialQuestion.fromJson({
        'key': 'q1',
        'type': 'SingleChoice',
        'title': 'Which currency?',
        'description': 'Pick one',
        'options': [
          {'key': 'a', 'text': 'CHF'},
          {'key': 'b', 'text': 'EUR'},
        ],
        'conditions': [
          {'question': 'q0', 'response': 'yes'},
        ],
      });

      expect(dto.key, 'q1');
      expect(dto.type, QuestionType.singleChoice);
      expect(dto.title, 'Which currency?');
      expect(dto.description, 'Pick one');
      expect(dto.options, hasLength(2));
      expect(dto.conditions, hasLength(1));
    });

    test('description / options / conditions are all optional', () {
      final dto = KycFinancialQuestion.fromJson({
        'key': 'q2',
        'type': 'Text',
        'title': 'Comment?',
      });

      expect(dto.description, isNull);
      expect(dto.options, isNull);
      expect(dto.conditions, isNull);
    });
  });

  group('$KycFinancialResponse', () {
    test('fromJson + toJson round-trip', () {
      const json = {'key': 'q1', 'value': 'a'};
      final dto = KycFinancialResponse.fromJson(json);

      expect(dto.key, 'q1');
      expect(dto.value, 'a');
      expect(dto.toJson(), json);
    });
  });

  group('$KycFinancialOutData.fromJson', () {
    test('parses questions + responses', () {
      final dto = KycFinancialOutData.fromJson({
        'questions': [
          {
            'key': 'q1',
            'type': 'Text',
            'title': 'Comment?',
          },
        ],
        'responses': [
          {'key': 'q1', 'value': 'hi'},
        ],
      });

      expect(dto.questions, hasLength(1));
      expect(dto.responses, hasLength(1));
      expect(dto.responses.first.value, 'hi');
    });

    test('absent responses defaults to empty list', () {
      final dto = KycFinancialOutData.fromJson({
        'questions': <Map<String, dynamic>>[],
      });

      expect(dto.responses, isEmpty);
    });
  });

  group('$KycLevelDto.fromJson', () {
    test('parses kycLevel + kycSteps list', () {
      final dto = KycLevelDto.fromJson({
        'kycLevel': 30,
        'kycSteps': [
          {
            'name': 'ContactData',
            'status': 'Completed',
            'sequenceNumber': 0,
            'isCurrent': false,
          },
        ],
      });

      expect(dto.kycLevel, KycLevel.level30);
      expect(dto.kycSteps, hasLength(1));
      expect(dto.kycSteps.first.name, KycStepName.contactData);
    });
  });
}
