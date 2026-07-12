import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:realunit_wallet/screens/legal/cubit/legal_disclaimer_cubit.dart';

void main() {
  group('$LegalDisclaimerCubit', () {
    test('initial state is step 0', () {
      final cubit = LegalDisclaimerCubit();

      expect(cubit.state.currentStep, 0);
      expect(cubit.state.canGoBack, isFalse);
      expect(cubit.state.isLastStep, isFalse);
      // 5 steps total → step 0 == 1/5 = 0.2.
      expect(cubit.state.progress, closeTo(0.2, 1e-9));
    });

    blocTest<LegalDisclaimerCubit, LegalDisclaimerState>(
      'nextStep advances by one when not on the last step',
      build: LegalDisclaimerCubit.new,
      act: (cubit) => cubit.nextStep(),
      expect: () => [
        const LegalDisclaimerState(currentStep: 1),
      ],
    );

    blocTest<LegalDisclaimerCubit, LegalDisclaimerState>(
      'nextStep walks from 0 all the way to the last step',
      build: LegalDisclaimerCubit.new,
      act: (cubit) {
        for (var i = 0; i < LegalDisclaimerState.totalSteps - 1; i++) {
          cubit.nextStep();
        }
      },
      expect: () => [
        const LegalDisclaimerState(currentStep: 1),
        const LegalDisclaimerState(currentStep: 2),
        const LegalDisclaimerState(currentStep: 3),
        const LegalDisclaimerState(currentStep: 4),
      ],
      verify: (cubit) {
        expect(cubit.state.isLastStep, isTrue);
        expect(cubit.state.progress, 1.0);
      },
    );

    test('nextStep on the last step invokes onComplete and does not emit', () async {
      final cubit = LegalDisclaimerCubit();
      for (var i = 0; i < LegalDisclaimerState.totalSteps - 1; i++) {
        cubit.nextStep();
      }
      final emitted = <LegalDisclaimerState>[];
      final sub = cubit.stream.listen(emitted.add);

      var completed = false;
      cubit.nextStep(onComplete: () => completed = true);
      await Future<void>.delayed(Duration.zero);
      await sub.cancel();

      expect(completed, isTrue);
      expect(emitted, isEmpty);
      expect(cubit.state.currentStep, LegalDisclaimerState.totalSteps - 1);
    });

    test('nextStep on the last step without onComplete is a no-op', () async {
      final cubit = LegalDisclaimerCubit();
      for (var i = 0; i < LegalDisclaimerState.totalSteps - 1; i++) {
        cubit.nextStep();
      }
      final emitted = <LegalDisclaimerState>[];
      final sub = cubit.stream.listen(emitted.add);

      cubit.nextStep();
      await Future<void>.delayed(Duration.zero);
      await sub.cancel();

      expect(emitted, isEmpty);
      expect(cubit.state.currentStep, LegalDisclaimerState.totalSteps - 1);
    });

    blocTest<LegalDisclaimerCubit, LegalDisclaimerState>(
      'previousStep moves back when canGoBack is true',
      build: LegalDisclaimerCubit.new,
      seed: () => const LegalDisclaimerState(currentStep: 2),
      act: (cubit) => cubit.previousStep(),
      expect: () => [const LegalDisclaimerState(currentStep: 1)],
    );

    blocTest<LegalDisclaimerCubit, LegalDisclaimerState>(
      'previousStep at step 0 is a no-op (cannot go below zero)',
      build: LegalDisclaimerCubit.new,
      act: (cubit) => cubit.previousStep(),
      expect: () => [],
    );
  });
}
