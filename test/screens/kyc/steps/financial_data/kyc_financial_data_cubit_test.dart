import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:realunit_wallet/packages/service/dfx/dfx_kyc_service.dart';
import 'package:realunit_wallet/packages/service/dfx/models/kyc/dto/kyc_financial_data_dto.dart';
import 'package:realunit_wallet/screens/kyc/steps/financial_data/cubits/kyc_financial_data_cubit.dart';
import 'package:realunit_wallet/styles/language.dart';

class _MockKycService extends Mock implements DfxKycService {}

const _q1 = KycFinancialQuestion(
  key: 'q1',
  type: QuestionType.singleChoice,
  title: 'Currency?',
);

const _q2 = KycFinancialQuestion(
  key: 'q2',
  type: QuestionType.text,
  title: 'Comment?',
);

// q3 is only visible when q1 == 'a'.
const _q3Conditional = KycFinancialQuestion(
  key: 'q3',
  type: QuestionType.text,
  title: 'Why?',
  conditions: [KycFinancialCondition(question: 'q1', response: 'a')],
);

void main() {
  setUpAll(() {
    registerFallbackValue(Language.de);
  });

  late _MockKycService service;

  setUp(() {
    service = _MockKycService();
  });

  KycFinancialDataCubit build() => KycFinancialDataCubit(service);

  group('initial state', () {
    test('emits KycFinancialDataInitial', () {
      expect(build().state, isA<KycFinancialDataInitial>());
    });
  });

  group('loadQuestions', () {
    blocTest<KycFinancialDataCubit, KycFinancialDataState>(
      'success: emits Loading then LoadedSuccess with currentIndex=0',
      setUp: () => when(
        () => service.getFinancialData('url', language: Language.en),
      ).thenAnswer(
        (_) async => const KycFinancialOutData(questions: [_q1, _q2], responses: []),
      ),
      build: build,
      act: (c) => c.loadQuestions('url', language: Language.en),
      expect: () => [
        isA<KycFinancialDataLoading>(),
        isA<KycFinancialDataLoadedSuccess>()
            .having((s) => s.currentIndex, 'currentIndex', 0)
            .having((s) => s.visibleQuestions, 'visibleQuestions', [_q1, _q2])
            .having((s) => s.url, 'url', 'url')
            .having((s) => s.responses, 'responses', isEmpty),
      ],
    );

    blocTest<KycFinancialDataCubit, KycFinancialDataState>(
      'filters questions whose conditions are not satisfied',
      setUp: () => when(
        () => service.getFinancialData(any(), language: any(named: 'language')),
      ).thenAnswer(
        (_) async => const KycFinancialOutData(
          questions: [_q1, _q3Conditional],
          // q3 requires q1=='a' — not set, so q3 must be filtered out.
          responses: [],
        ),
      ),
      build: build,
      act: (c) => c.loadQuestions('url'),
      verify: (c) {
        final state = c.state as KycFinancialDataLoadedSuccess;
        expect(state.allQuestions, [_q1, _q3Conditional]);
        expect(state.visibleQuestions, [_q1]);
      },
    );

    blocTest<KycFinancialDataCubit, KycFinancialDataState>(
      'failure: emits Loading then Failure',
      setUp: () => when(
        () => service.getFinancialData(any(), language: any(named: 'language')),
      ).thenAnswer((_) async => throw Exception('boom')),
      build: build,
      act: (c) => c.loadQuestions('url'),
      expect: () => [
        isA<KycFinancialDataLoading>(),
        isA<KycFinancialDataFailure>(),
      ],
    );
  });

  group('answerQuestion', () {
    test('no-ops outside LoadedSuccess', () async {
      final cubit = build();
      cubit.answerQuestion('q1', 'a');
      expect(cubit.state, isA<KycFinancialDataInitial>());
    });

    blocTest<KycFinancialDataCubit, KycFinancialDataState>(
      'in LoadedSuccess: stores the answer and re-runs the visibility filter',
      setUp: () => when(
        () => service.getFinancialData(any(), language: any(named: 'language')),
      ).thenAnswer(
        (_) async => const KycFinancialOutData(
          questions: [_q1, _q3Conditional],
          responses: [],
        ),
      ),
      build: build,
      act: (c) async {
        await c.loadQuestions('url');
        c.answerQuestion('q1', 'a');
      },
      skip: 2, // Loading + initial LoadedSuccess
      verify: (c) {
        final state = c.state as KycFinancialDataLoadedSuccess;
        expect(state.responses, {'q1': 'a'});
        // q3's condition is now satisfied — it becomes visible.
        expect(state.visibleQuestions, [_q1, _q3Conditional]);
      },
    );
  });

  group('submitAndNext', () {
    blocTest<KycFinancialDataCubit, KycFinancialDataState>(
      'on a non-last question increments currentIndex',
      setUp: () => when(
        () => service.getFinancialData(any(), language: any(named: 'language')),
      ).thenAnswer(
        (_) async => const KycFinancialOutData(questions: [_q1, _q2], responses: []),
      ),
      build: build,
      act: (c) async {
        await c.loadQuestions('url');
        await c.submitAndNext();
      },
      skip: 2,
      verify: (c) {
        final state = c.state as KycFinancialDataLoadedSuccess;
        expect(state.currentIndex, 1);
      },
    );

    blocTest<KycFinancialDataCubit, KycFinancialDataState>(
      'on the last question submits and emits SubmitSuccess',
      setUp: () {
        when(
          () => service.getFinancialData(any(), language: any(named: 'language')),
        ).thenAnswer(
          (_) async => const KycFinancialOutData(questions: [_q1], responses: []),
        );
        when(() => service.setFinancialData(any(), any())).thenAnswer((_) async {});
      },
      build: build,
      act: (c) async {
        await c.loadQuestions('url');
        await c.submitAndNext();
      },
      skip: 2,
      expect: () => [
        isA<KycFinancialDataSubmitting>(),
        isA<KycFinancialDataSubmitSuccess>(),
      ],
      verify: (_) => verify(() => service.setFinancialData('url', any())).called(1),
    );

    blocTest<KycFinancialDataCubit, KycFinancialDataState>(
      'submit failure surfaces a Failure state',
      setUp: () {
        when(
          () => service.getFinancialData(any(), language: any(named: 'language')),
        ).thenAnswer(
          (_) async => const KycFinancialOutData(questions: [_q1], responses: []),
        );
        when(() => service.setFinancialData(any(), any()))
            .thenAnswer((_) async => throw Exception('network'));
      },
      build: build,
      act: (c) async {
        await c.loadQuestions('url');
        await c.submitAndNext();
      },
      skip: 2,
      expect: () => [
        isA<KycFinancialDataSubmitting>(),
        isA<KycFinancialDataFailure>(),
      ],
    );

    test('no-ops outside LoadedSuccess', () async {
      final cubit = build();
      await cubit.submitAndNext();
      expect(cubit.state, isA<KycFinancialDataInitial>());
    });
  });

  group('goBack', () {
    blocTest<KycFinancialDataCubit, KycFinancialDataState>(
      'from index 1: decrements currentIndex',
      setUp: () => when(
        () => service.getFinancialData(any(), language: any(named: 'language')),
      ).thenAnswer(
        (_) async => const KycFinancialOutData(questions: [_q1, _q2], responses: []),
      ),
      build: build,
      act: (c) async {
        await c.loadQuestions('url');
        await c.submitAndNext();
        c.goBack();
      },
      skip: 3,
      verify: (c) {
        final state = c.state as KycFinancialDataLoadedSuccess;
        expect(state.currentIndex, 0);
      },
    );

    test('at index 0: no emit', () async {
      when(
        () => service.getFinancialData(any(), language: any(named: 'language')),
      ).thenAnswer(
        (_) async => const KycFinancialOutData(questions: [_q1], responses: []),
      );
      final cubit = build();
      await cubit.loadQuestions('url');
      final before = cubit.state;
      cubit.goBack();
      expect(cubit.state, same(before));
    });

    test('no-ops outside LoadedSuccess', () {
      final cubit = build();
      cubit.goBack();
      expect(cubit.state, isA<KycFinancialDataInitial>());
    });
  });

  group('$KycFinancialDataLoadedSuccess helpers', () {
    const state = KycFinancialDataLoadedSuccess(
      allQuestions: [_q1, _q2],
      visibleQuestions: [_q1, _q2],
      responses: {'q1': 'a'},
      currentIndex: 0,
      url: 'url',
    );

    test('currentQuestion picks visibleQuestions[currentIndex]', () {
      expect(state.currentQuestion, _q1);
    });

    test('isFirstQuestion / isLastQuestion', () {
      expect(state.isFirstQuestion, isTrue);
      expect(state.isLastQuestion, isFalse);
    });

    test('currentResponse + hasAnswer reflect the responses map', () {
      expect(state.currentResponse, 'a');
      expect(state.hasAnswer, isTrue);
    });

    test('hasAnswer is false on an empty string response', () {
      const empty = KycFinancialDataLoadedSuccess(
        allQuestions: [_q1],
        visibleQuestions: [_q1],
        responses: {'q1': ''},
        currentIndex: 0,
        url: 'url',
      );

      expect(empty.hasAnswer, isFalse);
    });
  });
}
