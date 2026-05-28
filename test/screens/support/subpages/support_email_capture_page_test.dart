import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:realunit_wallet/generated/i18n.dart';
import 'package:realunit_wallet/packages/service/dfx/real_unit_registration_service.dart';
import 'package:realunit_wallet/screens/support/cubits/support_email_capture/support_email_capture_cubit.dart';
import 'package:realunit_wallet/screens/support/subpages/support_email_capture_page.dart';
import 'package:realunit_wallet/widgets/form/labeled_text_field.dart';

class _MockSupportEmailCaptureCubit extends MockCubit<SupportEmailCaptureState>
    implements SupportEmailCaptureCubit {}

class _MockRegistrationService extends Mock implements RealUnitRegistrationService {}

void main() {
  late SupportEmailCaptureCubit cubit;

  setUpAll(() {
    final getIt = GetIt.instance;
    if (!getIt.isRegistered<RealUnitRegistrationService>()) {
      getIt.registerSingleton<RealUnitRegistrationService>(
        _MockRegistrationService(),
      );
    }
  });

  setUp(() {
    cubit = _MockSupportEmailCaptureCubit();
    when(() => cubit.state).thenReturn(const SupportEmailCaptureInitial());
  });

  Widget pumpView() {
    return MaterialApp(
      localizationsDelegates: [
        S.delegate,
        GlobalMaterialLocalizations.delegate,
      ],
      supportedLocales: S.delegate.supportedLocales,
      home: BlocProvider<SupportEmailCaptureCubit>.value(
        value: cubit,
        child: const SupportEmailCaptureView(),
      ),
    );
  }

  group('$SupportEmailCapturePage', () {
    testWidgets('builds the view via BlocProvider create', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: [
            S.delegate,
            GlobalMaterialLocalizations.delegate,
          ],
          supportedLocales: S.delegate.supportedLocales,
          home: const SupportEmailCapturePage(),
        ),
      );

      expect(find.byType(SupportEmailCaptureView), findsOne);
    });
  });

  group('$SupportEmailCaptureView form', () {
    testWidgets('renders title, description, email field, and continue button', (tester) async {
      await tester.pumpWidget(pumpView());

      expect(find.text(S.current.supportEmailCaptureTitle), findsOne);
      expect(find.text(S.current.supportEmailCaptureDescription), findsOne);
      expect(find.byType(LabeledTextField), findsOne);
      expect(find.text(S.current.supportEmailCaptureContinue), findsOne);
    });

    testWidgets('empty email shows the required validator message', (tester) async {
      await tester.pumpWidget(pumpView());

      await tester.tap(find.text(S.current.supportEmailCaptureContinue));
      await tester.pumpAndSettle();

      expect(find.text(S.current.registerEmailRequired), findsOne);
      verifyNever(() => cubit.submit(any()));
    });

    testWidgets('invalid email shows the invalid validator message', (tester) async {
      await tester.pumpWidget(pumpView());

      await tester.enterText(find.byType(TextFormField), 'not-an-email');
      await tester.tap(find.text(S.current.supportEmailCaptureContinue));
      await tester.pumpAndSettle();

      expect(find.text(S.current.registerEmailInvalid), findsOne);
      verifyNever(() => cubit.submit(any()));
    });

    testWidgets('valid email submits to the cubit', (tester) async {
      when(() => cubit.submit(any())).thenAnswer((_) async {});

      await tester.pumpWidget(pumpView());

      await tester.enterText(find.byType(TextFormField), 'a@b.com');
      await tester.tap(find.text(S.current.supportEmailCaptureContinue));
      await tester.pumpAndSettle();

      verify(() => cubit.submit('a@b.com')).called(1);
    });

    testWidgets('Loading state renders the activity indicator', (tester) async {
      when(() => cubit.state).thenReturn(const SupportEmailCaptureLoading());

      await tester.pumpWidget(pumpView());

      expect(find.byType(CupertinoActivityIndicator), findsOne);
    });
  });

  group('$SupportEmailCaptureView pop & snackbar behavior', () {
    testWidgets('Success state pops the route with true', (tester) async {
      // Wire the view inside a GoRouter so the page's
      // `Navigator.pop(true)` is observable via the parent
      // recording the result.
      Object? popResult;
      final router = GoRouter(
        initialLocation: '/',
        routes: [
          GoRoute(
            path: '/',
            builder: (_, _) => _LauncherPage(
              onLaunch: (ctx) async {
                popResult = await ctx.push('/capture');
              },
            ),
          ),
          GoRoute(
            path: '/capture',
            builder: (_, _) => BlocProvider<SupportEmailCaptureCubit>.value(
              value: cubit,
              child: const SupportEmailCaptureView(),
            ),
          ),
        ],
      );
      addTearDown(router.dispose);
      whenListen(
        cubit,
        Stream.fromIterable(const [SupportEmailCaptureSuccess()]),
        initialState: const SupportEmailCaptureInitial(),
      );

      await tester.pumpWidget(
        MaterialApp.router(
          routerConfig: router,
          localizationsDelegates: [
            S.delegate,
            GlobalMaterialLocalizations.delegate,
          ],
          supportedLocales: S.delegate.supportedLocales,
        ),
      );
      await tester.pumpAndSettle();

      // Trigger the navigation that pushes the capture page.
      await tester.tap(find.text('LAUNCH'));
      await tester.pumpAndSettle();

      expect(popResult, isTrue);
    });

    testWidgets('Failure with mergeRequested shows the merge-required snackbar', (tester) async {
      whenListen(
        cubit,
        Stream.fromIterable(const [
          SupportEmailCaptureFailure(
            error: SupportEmailCaptureError.mergeRequested,
            message: '',
          ),
        ]),
        initialState: const SupportEmailCaptureInitial(),
      );

      await tester.pumpWidget(pumpView());
      await tester.pump();
      await tester.pump();

      expect(
        find.text(S.current.supportEmailMergeRequiresVerification),
        findsOne,
      );
    });

    testWidgets('Failure with unknown error shows the raw error message', (tester) async {
      whenListen(
        cubit,
        Stream.fromIterable(const [
          SupportEmailCaptureFailure(
            error: SupportEmailCaptureError.unknown,
            message: 'something broke',
          ),
        ]),
        initialState: const SupportEmailCaptureInitial(),
      );

      await tester.pumpWidget(pumpView());
      await tester.pump();
      await tester.pump();

      expect(find.text('something broke'), findsOne);
    });
  });
}

/// Helper page that lets a test trigger a navigation push and capture
/// the result of `pop()`.
class _LauncherPage extends StatelessWidget {
  final Future<void> Function(BuildContext) onLaunch;
  const _LauncherPage({required this.onLaunch});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: TextButton(
          onPressed: () => onLaunch(context),
          child: const Text('LAUNCH'),
        ),
      ),
    );
  }
}
