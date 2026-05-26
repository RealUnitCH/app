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

/// Records pop calls coming up from the email-capture page so the
/// "Success → pop(true)" contract can be asserted without spinning up the
/// full app router.
class _PopSpy {
  final List<Object?> popped = [];
}

GoRouter _routerFor(_PopSpy spy, Widget child) {
  return GoRouter(
    initialLocation: '/host',
    routes: [
      GoRoute(
        path: '/host',
        builder: (context, _) => Scaffold(
          body: Center(
            child: Builder(
              builder: (innerContext) => ElevatedButton(
                onPressed: () async {
                  final result = await innerContext.push<bool>('/host/email');
                  spy.popped.add(result);
                },
                child: const Text('open-email'),
              ),
            ),
          ),
        ),
        routes: [
          GoRoute(
            path: 'email',
            builder: (_, _) => child,
          ),
        ],
      ),
    ],
  );
}

Widget _harness(GoRouter router) {
  return MaterialApp.router(
    routerConfig: router,
    localizationsDelegates: const [
      S.delegate,
      GlobalMaterialLocalizations.delegate,
    ],
    supportedLocales: S.delegate.supportedLocales,
  );
}

void main() {
  late _MockSupportEmailCaptureCubit cubit;

  setUp(() {
    cubit = _MockSupportEmailCaptureCubit();
    when(() => cubit.state).thenReturn(const SupportEmailCaptureInitial());
  });

  setUpAll(() {
    GetIt.instance.registerSingleton<RealUnitRegistrationService>(_MockRegistrationService());
  });

  Widget buildSubject() => BlocProvider<SupportEmailCaptureCubit>.value(
    value: cubit,
    child: const SupportEmailCaptureView(),
  );

  /// Mounts the host page, taps the launcher to push the email-capture
  /// route, and lets the navigation transition settle. Uses [pump] with a
  /// fixed duration rather than [pumpAndSettle] because the Submitting
  /// state mounts a [CupertinoActivityIndicator] whose ticker never
  /// stops — `pumpAndSettle` would hang.
  Future<void> openEmailCapture(WidgetTester tester, GoRouter router) async {
    await tester.pumpWidget(_harness(router));
    await tester.tap(find.text('open-email'));
    // 400ms is enough for the default GoRouter MaterialPage transition.
    for (var i = 0; i < 6; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  group('$SupportEmailCapturePage', () {
    testWidgets('renders SupportEmailCaptureView wrapped in BlocProvider', (tester) async {
      final spy = _PopSpy();
      final router = _routerFor(spy, const SupportEmailCapturePage());
      addTearDown(router.dispose);

      await openEmailCapture(tester, router);

      expect(find.byType(SupportEmailCaptureView), findsOne);
    });
  });

  group('$SupportEmailCaptureView', () {
    testWidgets('renders title, description and an empty email field', (tester) async {
      final spy = _PopSpy();
      final router = _routerFor(spy, buildSubject());
      addTearDown(router.dispose);

      await openEmailCapture(tester, router);

      expect(find.text(S.current.supportEmailCaptureTitle), findsOne);
      expect(find.text(S.current.supportEmailCaptureDescription), findsOne);
      expect(find.byType(LabeledTextField), findsOne);
      final field = tester.widget<TextFormField>(find.byType(TextFormField));
      expect(field.controller?.text, isEmpty);
      expect(find.byType(CupertinoActivityIndicator), findsNothing);
    });

    testWidgets('empty submit shows the "required" validator message', (tester) async {
      final spy = _PopSpy();
      final router = _routerFor(spy, buildSubject());
      addTearDown(router.dispose);

      await openEmailCapture(tester, router);
      await tester.tap(find.bySubtype<FilledButton>());
      await tester.pumpAndSettle();

      expect(find.text(S.current.registerEmailRequired), findsOne);
      verifyNever(() => cubit.submit(any()));
    });

    testWidgets('invalid email submit shows the "invalid" validator message', (tester) async {
      final spy = _PopSpy();
      final router = _routerFor(spy, buildSubject());
      addTearDown(router.dispose);

      await openEmailCapture(tester, router);
      await tester.enterText(find.byType(TextFormField), 'not-an-email');
      await tester.tap(find.bySubtype<FilledButton>());
      await tester.pumpAndSettle();

      expect(find.text(S.current.registerEmailInvalid), findsOne);
      verifyNever(() => cubit.submit(any()));
    });

    testWidgets('valid email submit forwards the trimmed lowercase-input string', (tester) async {
      // The cubit handles `.toLowerCase()` inside the service call —
      // here we only assert the form trims and forwards the raw text.
      when(() => cubit.submit(any())).thenAnswer((_) async {});
      final spy = _PopSpy();
      final router = _routerFor(spy, buildSubject());
      addTearDown(router.dispose);

      await openEmailCapture(tester, router);
      await tester.enterText(find.byType(TextFormField), '  user@example.com  ');
      await tester.tap(find.bySubtype<FilledButton>());
      await tester.pumpAndSettle();

      verify(() => cubit.submit('user@example.com')).called(1);
    });

    testWidgets('Submitting state renders the button in loading mode', (tester) async {
      when(() => cubit.state).thenReturn(const SupportEmailCaptureSubmitting());

      final spy = _PopSpy();
      final router = _routerFor(spy, buildSubject());
      addTearDown(router.dispose);

      await openEmailCapture(tester, router);

      expect(find.byType(CupertinoActivityIndicator), findsOne);
    });

    testWidgets('Success state pops the route with `true`', (tester) async {
      whenListen(
        cubit,
        Stream.fromIterable([const SupportEmailCaptureSuccess()]),
        initialState: const SupportEmailCaptureInitial(),
      );

      final spy = _PopSpy();
      final router = _routerFor(spy, buildSubject());
      addTearDown(router.dispose);

      await openEmailCapture(tester, router);
      await tester.pumpAndSettle();

      expect(spy.popped, [true]);
    });

    testWidgets('Failure state shows a SnackBar with the message', (tester) async {
      whenListen(
        cubit,
        Stream.fromIterable([
          const SupportEmailCaptureFailure(message: 'duplicate email'),
        ]),
        initialState: const SupportEmailCaptureInitial(),
      );

      final spy = _PopSpy();
      final router = _routerFor(spy, buildSubject());
      addTearDown(router.dispose);

      await openEmailCapture(tester, router);
      await tester.pump();

      expect(find.byType(SnackBar), findsOne);
      expect(find.text('duplicate email'), findsOne);
      expect(spy.popped, isEmpty);
    });
  });
}
