part of 'kyc_financial_data_cubit.dart';

abstract class KycFinancialDataState extends Equatable {
  const KycFinancialDataState();

  @override
  List<Object?> get props => [];
}

class KycFinancialDataInitial extends KycFinancialDataState {
  const KycFinancialDataInitial();
}

class KycFinancialDataLoading extends KycFinancialDataState {
  const KycFinancialDataLoading();
}

class KycFinancialDataLoadedSuccess extends KycFinancialDataState {
  final List<KycFinancialQuestion> allQuestions;
  final List<KycFinancialQuestion> visibleQuestions;
  final Map<String, String> responses;
  final int currentIndex;
  final String url;

  const KycFinancialDataLoadedSuccess({
    required this.allQuestions,
    required this.visibleQuestions,
    required this.responses,
    required this.currentIndex,
    required this.url,
  });

  KycFinancialQuestion get currentQuestion => visibleQuestions.elementAt(currentIndex);

  bool get isFirstQuestion => currentIndex == 0;

  bool get isLastQuestion => currentIndex >= visibleQuestions.length - 1;

  String? get currentResponse => responses[currentQuestion.key];

  bool get hasAnswer => currentResponse != null && currentResponse!.isNotEmpty;

  @override
  List<Object?> get props => [allQuestions, visibleQuestions, responses, currentIndex, url];
}

/// Submit failed while the collected answers are retained, so the user can
/// retry from the questions UI instead of a dead-end failure page.
class KycFinancialDataSubmitFailure extends KycFinancialDataLoadedSuccess {
  final String message;

  const KycFinancialDataSubmitFailure({
    required this.message,
    required super.allQuestions,
    required super.visibleQuestions,
    required super.responses,
    required super.currentIndex,
    required super.url,
  });

  factory KycFinancialDataSubmitFailure.from(
    KycFinancialDataLoadedSuccess state,
    String message,
  ) => KycFinancialDataSubmitFailure(
        message: message,
        allQuestions: state.allQuestions,
        visibleQuestions: state.visibleQuestions,
        responses: state.responses,
        currentIndex: state.currentIndex,
        url: state.url,
      );

  @override
  List<Object?> get props => [...super.props, message];
}

class KycFinancialDataSubmitting extends KycFinancialDataState {
  const KycFinancialDataSubmitting();
}

class KycFinancialDataSubmitSuccess extends KycFinancialDataState {
  const KycFinancialDataSubmitSuccess();
}

class KycFinancialDataFailure extends KycFinancialDataState {
  final String message;
  const KycFinancialDataFailure(this.message);

  @override
  List<Object?> get props => [message];
}
