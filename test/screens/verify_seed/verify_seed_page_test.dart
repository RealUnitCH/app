import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
      final wallet = MockWallet();
      when(() => wallet.seed).thenReturn(
        'cheese trigger cannon mention judge hire snack sustain annual predict illness celery',
      );

      await tester.pumpApp(
        VerifySeedPage(wallet: wallet),
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

    // Regression for issue #612 S1: the verify-seed screen (where the user
    // re-enters real seed words) had no screenshot protection, unlike the
    // sibling seed screens. It must disable screenshots on init and re-enable
    // on dispose so it never lands in the app-switcher snapshot / a recording.
    testWidgets('disables screenshots on init and re-enables on dispose',
        (tester) async {
      const channel = MethodChannel('com.flutterplaza.no_screenshot_methods');
      final calls = <String>[];
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        channel,
        (call) async {
          calls.add(call.method);
          return true;
        },
      );
      addTearDown(
        () => tester.binding.defaultBinaryMessenger
            .setMockMethodCallHandler(channel, null),
      );

      await tester.pumpApp(buildSubject(const VerifySeedView()));
      expect(calls, contains('screenshotOff'),
          reason: 'seed screen must block screenshots on init');

      // Replace the screen so VerifySeedView is disposed.
      await tester.pumpApp(buildSubject(const SizedBox.shrink()));
      expect(calls, contains('screenshotOn'),
          reason: 'leaving the seed screen must re-enable screenshots');
    });

    group('$BlocListener', () {
      testWidgets('sends $LoadWalletEvent with the committed wallet when verified',
          (tester) async {
        // The committed wallet `verify()` produced — a persisted row with a
        // real id (42), not the draft's `0` sentinel.
        final committed = SoftwareWallet(
          42,
          'Main',
          'cheese trigger cannon mention judge hire snack sustain annual predict illness celery',
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
