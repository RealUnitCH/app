import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:mocktail/mocktail.dart';
import 'package:realunit_wallet/packages/service/wallet_service.dart';
import 'package:realunit_wallet/packages/wallet/wallet.dart';
import 'package:realunit_wallet/screens/home/bloc/home_bloc.dart';
import 'package:realunit_wallet/screens/verify_seed/cubit/verify_seed_cubit.dart';
import 'package:realunit_wallet/screens/verify_seed/verify_seed_page.dart';
import 'package:realunit_wallet/screens/verify_seed/widgets/verify_seed_button.dart';
import 'package:realunit_wallet/screens/verify_seed/widgets/verify_seed_input_field.dart';
import 'package:realunit_wallet/styles/colors.dart';

import '../../helper/pump_app.dart';
import '../../test_utils/fake_wallet_isolate.dart';

class MockVerifySeedCubit extends MockCubit<VerifySeedState> implements VerifySeedCubit {}

class MockHomeBloc extends MockBloc<HomeEvent, HomeState> implements HomeBloc {}

class MockWalletService extends Mock implements WalletService {}

class MockWallet extends Mock implements SoftwareWallet {}

void main() {
  late VerifySeedCubit verifySeedCubit;
  late HomeBloc homeBloc;

  setUp(() {
    verifySeedCubit = MockVerifySeedCubit();
    homeBloc = MockHomeBloc();

    when(() => verifySeedCubit.state).thenReturn(const VerifySeedState());
  });

  void setupDependencyInjection() {
    final getIt = GetIt.instance;
    getIt.registerSingleton<WalletService>(MockWalletService());
  }

  setUpAll(() {
    setupDependencyInjection();
  });

  tearDownAll(() async => await GetIt.instance.reset());

  Widget buildSubject(Widget child) {
    return MultiBlocProvider(
      providers: [
        BlocProvider.value(value: homeBloc),
        BlocProvider.value(value: verifySeedCubit),
      ],
      child: child,
    );
  }

  group('$VerifySeedPage', () {
    testWidgets('renders $VerifySeedView', (tester) async {
      final draft = SeedDraft(
        'cheese trigger cannon mention judge hire snack sustain annual predict illness celery',
      );

      await tester.pumpApp(
        VerifySeedPage(draft: draft),
      );

      expect(find.byType(VerifySeedView), findsOne);
    });
  });

  group('$VerifySeedView', () {
    testWidgets('renders initially correctly', (tester) async {
      when(
        () => verifySeedCubit.state,
      ).thenReturn(
        const VerifySeedState(
          wordIndices: [1, 3, 5, 7],
          enteredWords: ['', '', '', ''],
        ),
      );

      await tester.pumpApp(buildSubject(const VerifySeedView()));

      expect(
        find.byWidgetPredicate((widget) => widget is SvgPicture && widget.width == 124),
        findsOne,
      );
      expect(find.byType(VerifySeedInputField), findsOne);
      expect(find.byType(VerifySeedButton), findsOne);
    });

    group('$VerifySeedButton', () {
      testWidgets('is correctly rendered when entered words are incomplete', (tester) async {
        when(
          () => verifySeedCubit.state,
        ).thenReturn(
          const VerifySeedState(
            wordIndices: [1, 3, 5, 7],
            enteredWords: ['ah', '', '', ''],
          ),
        );

        await tester.pumpApp(buildSubject(const VerifySeedView()));

        expect(
          find.byWidgetPredicate(
            (Widget widget) =>
                widget is FilledButton &&
                widget.enabled == false &&
                widget.child.runtimeType == Text,
          ),
          findsOne,
        );
      });

      testWidgets('is correctly rendered when entered words are complete', (tester) async {
        when(() => verifySeedCubit.state).thenReturn(
          const VerifySeedState(
            wordIndices: [1, 3, 5, 7],
            enteredWords: ['ah', 'bee', 'cee', 'dee'],
          ),
        );

        await tester.pumpApp(buildSubject(const VerifySeedView()));

        expect(
          find.byWidgetPredicate(
            (Widget widget) =>
                widget is FilledButton &&
                widget.enabled == true &&
                widget.child.runtimeType == Text,
          ),
          findsOne,
        );
      });

      testWidgets('is correctly rendered when entered words are invalid', (tester) async {
        when(() => verifySeedCubit.state).thenReturn(
          const VerifySeedState(
            wordIndices: [1, 3, 5, 7],
            enteredWords: ['ah', 'bee', 'cee', 'dee'],
            hasError: true,
          ),
        );

        await tester.pumpApp(buildSubject(const VerifySeedView()));

        expect(
          find.byWidgetPredicate(
            (Widget widget) =>
                widget is FilledButton &&
                widget.enabled == false &&
                widget.style?.backgroundColor?.resolve({}) == RealUnitColors.status.red600,
          ),
          findsOne,
        );
      });

      testWidgets('is correctly rendered when entered words are verified', (tester) async {
        when(() => verifySeedCubit.state).thenReturn(
          const VerifySeedState(
            wordIndices: [1, 3, 5, 7],
            enteredWords: ['ah', 'bee', 'cee', 'dee'],
            isVerified: true,
          ),
        );

        await tester.pumpApp(buildSubject(const VerifySeedView()));

        expect(
          find.byWidgetPredicate(
            (Widget widget) =>
                widget is FilledButton &&
                widget.enabled == false &&
                widget.style?.backgroundColor?.resolve({}) == RealUnitColors.green,
          ),
          findsOne,
        );
      });
    });

    group('$BlocListener', () {
      testWidgets('sends $LoadWalletEvent with the committed wallet when verified',
          (tester) async {
        // The committed wallet `verify()` produced — a persisted row with a
        // real id (42), not the draft's `0` sentinel.
        final committed = SoftwareWallet(
          42,
          'Main',
          '0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266',
          FakeWalletIsolate(),
        );
        whenListen(
          verifySeedCubit,
          Stream.fromIterable([
            VerifySeedState(isVerified: true, committedWallet: committed),
          ]),
          initialState: const VerifySeedState(),
        );

        await tester.pumpApp(buildSubject(const VerifySeedView()));
        await tester.pump();
        await tester.pump(const Duration(seconds: 2));

        // The page must dispatch `LoadWalletEvent` (so `HomeBloc` sets
        // `hasWallet: true` and `main.dart` routes onboarding forward) with
        // the *committed* wallet — not the draft (`id == 0`).
        verify(() => homeBloc.add(LoadWalletEvent(committed))).called(1);
      });
    });
  });
}
