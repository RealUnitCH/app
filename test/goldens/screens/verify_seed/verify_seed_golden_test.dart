import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:realunit_wallet/screens/home/bloc/home_bloc.dart';
import 'package:realunit_wallet/screens/verify_seed/cubit/verify_seed_cubit.dart';
import 'package:realunit_wallet/screens/verify_seed/verify_seed_page.dart';

import '../../../helper/helper.dart';

class _MockVerifySeedCubit extends MockCubit<VerifySeedState>
    implements VerifySeedCubit {}

void main() {
  late _MockVerifySeedCubit verifySeedCubit;
  late MockHomeBloc homeBloc;

  setUp(() {
    verifySeedCubit = _MockVerifySeedCubit();
    homeBloc = MockHomeBloc();
    when(() => verifySeedCubit.state).thenReturn(
      const VerifySeedState(
        wordIndices: [1, 3, 5, 7],
        enteredWords: ['', '', '', ''],
      ),
    );
    when(() => homeBloc.state).thenReturn(const HomeState());
  });

  Widget buildSubject() => MultiBlocProvider(
        providers: [
          BlocProvider<HomeBloc>.value(value: homeBloc),
          BlocProvider<VerifySeedCubit>.value(value: verifySeedCubit),
        ],
        child: const VerifySeedView(),
      );

  group('$VerifySeedView', () {
    goldenTest(
      'default state with word indices',
      fileName: 'verify_seed_page_default',
      constraints: const BoxConstraints.tightFor(width: 390, height: 844),
      builder: () => wrapForGolden(buildSubject()),
    );

    goldenTest(
      'all words entered',
      fileName: 'verify_seed_page_all_entered',
      constraints: const BoxConstraints.tightFor(width: 390, height: 844),
      builder: () {
        when(() => verifySeedCubit.state).thenReturn(
          const VerifySeedState(
            wordIndices: [1, 3, 5, 7],
            enteredWords: ['abandon', 'ability', 'about', 'above'],
          ),
        );
        return wrapForGolden(buildSubject());
      },
    );
  });
}
