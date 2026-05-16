import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:realunit_wallet/screens/verify_seed/cubit/verify_seed_cubit.dart';
import 'package:realunit_wallet/screens/verify_seed/widgets/verify_seed_input_field.dart';

import '../../../helper/helper.dart';

class _MockVerifySeedCubit extends MockCubit<VerifySeedState>
    implements VerifySeedCubit {}

Widget _host(VerifySeedCubit cubit, Widget child) =>
    BlocProvider<VerifySeedCubit>.value(
      value: cubit,
      child: Scaffold(body: child),
    );

void main() {
  late _MockVerifySeedCubit cubit;

  setUp(() {
    cubit = _MockVerifySeedCubit();
    when(() => cubit.state).thenReturn(const VerifySeedState());
  });

  group('$VerifySeedInputField', () {
    testWidgets('renders 4 TextFields (one per position)', (tester) async {
      await tester.pumpApp(_host(
        cubit,
        VerifySeedInputField(
          wordIndices: const [0, 3, 7, 11],
          enteredWords: const ['', '', '', ''],
        ),
      ));

      expect(find.byType(TextField), findsNWidgets(4));
    });

    testWidgets('asserts that exactly 4 enteredWords are passed', (tester) async {
      expect(
        () => VerifySeedInputField(
          wordIndices: const [0, 1, 2, 3],
          enteredWords: const ['only', 'three', 'here'],
        ),
        throwsA(isA<AssertionError>()),
      );
    });

    testWidgets('initial enteredWords seed each TextField', (tester) async {
      await tester.pumpApp(_host(
        cubit,
        VerifySeedInputField(
          wordIndices: const [0, 3, 7, 11],
          enteredWords: const ['alpha', 'bravo', 'charlie', 'delta'],
        ),
      ));

      expect(find.text('alpha'), findsOneWidget);
      expect(find.text('bravo'), findsOneWidget);
      expect(find.text('charlie'), findsOneWidget);
      expect(find.text('delta'), findsOneWidget);
    });

    testWidgets('typing into a field calls cubit.updateWord(index, value)',
        (tester) async {
      when(() => cubit.updateWord(any(), any())).thenReturn(null);

      await tester.pumpApp(_host(
        cubit,
        VerifySeedInputField(
          wordIndices: const [0, 3, 7, 11],
          enteredWords: const ['', '', '', ''],
        ),
      ));

      // Type into the second TextField (index 1).
      final fields = find.byType(TextField);
      await tester.enterText(fields.at(1), 'typed');

      verify(() => cubit.updateWord(1, 'typed')).called(1);
    });
  });
}
