import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:realunit_wallet/screens/verify_seed/cubit/verify_seed_cubit.dart';
import 'package:realunit_wallet/screens/verify_seed/widgets/verify_seed_button.dart';
import 'package:realunit_wallet/widgets/buttons/app_filled_button.dart';

import '../../../helper/helper.dart';

class _MockVerifySeedCubit extends MockCubit<VerifySeedState>
    implements VerifySeedCubit {}

Widget _host(VerifySeedCubit cubit) => BlocProvider<VerifySeedCubit>.value(
      value: cubit,
      child: const VerifySeedButton(),
    );

void main() {
  late _MockVerifySeedCubit cubit;

  setUp(() {
    cubit = _MockVerifySeedCubit();
  });

  AppFilledButton button(WidgetTester tester) =>
      tester.widget<AppFilledButton>(find.byType(AppFilledButton));

  group('$VerifySeedButton', () {
    testWidgets('hasError: renders the error-variant AppFilledButton',
        (tester) async {
      when(() => cubit.state).thenReturn(const VerifySeedState(hasError: true));

      await tester.pumpApp(_host(cubit));

      expect(button(tester).state, FilledButtonState.error);
    });

    testWidgets('isVerified: renders the success-variant AppFilledButton with a check icon',
        (tester) async {
      when(() => cubit.state).thenReturn(const VerifySeedState(isVerified: true));

      await tester.pumpApp(_host(cubit));

      final b = button(tester);
      expect(b.state, FilledButtonState.success);
      expect(b.icon, Icons.check);
    });

    testWidgets(
      'idle + canVerify=false: idle button with onPressed: null',
      (tester) async {
        when(() => cubit.state).thenReturn(const VerifySeedState());

        await tester.pumpApp(_host(cubit));

        final b = button(tester);
        expect(b.state, FilledButtonState.idle);
        expect(b.onPressed, isNull);
      },
    );

    testWidgets(
      'idle + canVerify=true: idle button with a non-null onPressed callback',
      (tester) async {
        when(() => cubit.state).thenReturn(const VerifySeedState(
          wordIndices: [1, 2, 3, 4],
          enteredWords: ['a', 'b', 'c', 'd'],
        ));

        await tester.pumpApp(_host(cubit));

        final b = button(tester);
        expect(b.state, FilledButtonState.idle);
        expect(b.onPressed, isNotNull);
      },
    );

    testWidgets(
      'isVerifying: renders the loading-variant AppFilledButton',
      (tester) async {
        when(() => cubit.state)
            .thenReturn(const VerifySeedState(isVerifying: true));

        await tester.pumpApp(_host(cubit));

        expect(button(tester).state, FilledButtonState.loading);
      },
    );

    testWidgets(
      'commitFailed: renders a tappable retry button that calls verify()',
      (tester) async {
        when(() => cubit.state)
            .thenReturn(const VerifySeedState(commitFailed: true));
        when(() => cubit.verify()).thenAnswer((_) async => false);

        await tester.pumpApp(_host(cubit));

        final b = button(tester);
        // `.idle` keeps `onPressed` wired — the `.error` variant hard-nulls
        // it, which would make the retry affordance untappable.
        expect(b.state, FilledButtonState.idle);
        expect(b.icon, Icons.refresh);
        expect(b.onPressed, isNotNull);

        b.onPressed!();
        verify(() => cubit.verify()).called(1);
      },
    );
  });
}
