enum QuestionType { checkbox, singleChoice, multipleChoice, text }

extension QuestionTypeExtension on QuestionType {
  static QuestionType fromValue(String value) {
    switch (value) {
      case 'Confirmation':
        return QuestionType.checkbox;
      case 'SingleChoice':
        return QuestionType.singleChoice;
      case 'MultipleChoice':
        return QuestionType.multipleChoice;
      case 'Text':
        return QuestionType.text;
      default:
        throw ArgumentError('Unknown QuestionType: $value');
    }
  }
}

class KycFinancialOption {
  final String key;
  final String text;

  const KycFinancialOption({
    required this.key,
    required this.text,
  });

  factory KycFinancialOption.fromJson(Map<String, dynamic> json) {
    return KycFinancialOption(
      key: json['key'] as String,
      text: json['text'] as String,
    );
  }
}

class KycFinancialCondition {
  final String question;
  final String response;

  const KycFinancialCondition({
    required this.question,
    required this.response,
  });

  factory KycFinancialCondition.fromJson(Map<String, dynamic> json) {
    return KycFinancialCondition(
      question: json['question'] as String,
      response: json['response'] as String,
    );
  }
}

class KycFinancialQuestion {
  final String key;
  final QuestionType type;
  final String title;
  final String? description;
  final List<KycFinancialOption>? options;
  final List<KycFinancialCondition>? conditions;

  const KycFinancialQuestion({
    required this.key,
    required this.type,
    required this.title,
    this.description,
    this.options,
    this.conditions,
  });

  factory KycFinancialQuestion.fromJson(Map<String, dynamic> json) {
    return KycFinancialQuestion(
      key: json['key'] as String,
      type: QuestionTypeExtension.fromValue(json['type'] as String),
      title: json['title'] as String,
      description: json['description'] as String?,
      options: (json['options'] as List<dynamic>?)
          ?.map((e) => KycFinancialOption.fromJson(e as Map<String, dynamic>))
          .toList(),
      conditions: (json['conditions'] as List<dynamic>?)
          ?.map((e) => KycFinancialCondition.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class KycFinancialResponse {
  final String key;
  final String value;

  const KycFinancialResponse({
    required this.key,
    required this.value,
  });

  Map<String, dynamic> toJson() => {'key': key, 'value': value};

  factory KycFinancialResponse.fromJson(Map<String, dynamic> json) {
    return KycFinancialResponse(
      key: json['key'] as String,
      value: json['value'] as String,
    );
  }
}

class KycFinancialOutData {
  final List<KycFinancialQuestion> questions;
  final List<KycFinancialResponse> responses;

  const KycFinancialOutData({
    required this.questions,
    required this.responses,
  });

  factory KycFinancialOutData.fromJson(Map<String, dynamic> json) {
    return KycFinancialOutData(
      questions: (json['questions'] as List<dynamic>)
          .map((e) => KycFinancialQuestion.fromJson(e as Map<String, dynamic>))
          .toList(),
      responses:
          (json['responses'] as List<dynamic>?)
              ?.map((e) => KycFinancialResponse.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}
