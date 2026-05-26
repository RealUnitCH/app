import 'dart:async';

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
import 'package:realunit_wallet/packages/service/dfx/dfx_kyc_service.dart';
import 'package:realunit_wallet/screens/support/cubits/support_page/support_page_cubit.dart';
import 'package:realunit_wallet/screens/support/support_page.dart';
import 'package:realunit_wallet/setup/routing/routes/support_routes.dart';
import 'package:realunit_wallet/widgets/outlined_tile.dart';

class _MockSupportPageCubit extends MockCubit<SupportPageState> implements SupportPageCubit {}

class _MockKycService extends Mock implements DfxKycService {}

/// Records every routes pushed via `pushNamed`. Each child route mounts a
/// trivial placeholder + optionally pops with a configured value so the
/// listener can chain the next push.
class _RouteSpy {
  final List<String> pushedNames = [];
  bool? emailCapturePopValue;

  /// When non-null, the email-capture route does NOT auto-pop on mount.
  /// Instead it parks and completes this future with the configured pop
  /// value when the test signals so manually. Lets a test resolve the
  /// `pushNamed<bool>()` future at a precise moment — e.g. AFTER
  /// unmounting the SupportView — to exercise the
  /// `context.mounted == false` early-return in the listener.
  Completer<bool?>? emailCaptureCompleter;
}

class _Placeholder extends StatelessWidget {
  const _Placeholder(this.label);
  final String label;

  @override
  Widget build(BuildContext context) => Scaffold(body: Text(label));
}

GoRouter _routerFor(_RouteSpy spy, Widget child) {
  return GoRouter(
    initialLocation: '/support',
    routes: [
      GoRoute(
        path: '/support',
        name: SupportRoutes.support,
        builder: (_, _) => child,
        routes: [
          GoRoute(
            path: 'create',
            name: SupportRoutes.createTicket,
            builder: (_, _) {
              spy.pushedNames.add(SupportRoutes.createTicket);
              return const _Placeholder('create');
            },
          ),
          GoRoute(
            path: 'tickets',
            name: SupportRoutes.tickets,
            builder: (_, _) {
              spy.pushedNames.add(SupportRoutes.tickets);
              return const _Placeholder('tickets');
            },
          ),
          GoRoute(
            path: 'email',
            name: SupportRoutes.emailCapture,
            builder: (context, _) {
              spy.pushedNames.add(SupportRoutes.emailCapture);
              final manual = spy.emailCaptureCompleter;
              if (manual != null) {
                // Test owns the pop: wait until the completer resolves
                // (which the test triggers after manipulating the tree),
                // then pop with the supplied value if the route is
                // still mounted.
                unawaited(
                  manual.future.then((value) {
                    if (context.mounted) {
                      context.pop<bool>(value);
                    }
                  }),
                );
              } else {
                // Schedule the pop on the next frame so the page mounts
                // first — matches how the real email-capture page pops
                // on a successful Success state emission.
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (context.mounted) {
                    context.pop<bool>(spy.emailCapturePopValue);
                  }
                });
              }
              return const _Placeholder('email');
            },
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
  late _MockSupportPageCubit cubit;

  setUp(() {
    cubit = _MockSupportPageCubit();
    when(() => cubit.state).thenReturn(const SupportPageIdle());
  });

  setUpAll(() {
    GetIt.instance.registerSingleton<DfxKycService>(_MockKycService());
  });

  Widget buildSubject() => BlocProvider<SupportPageCubit>.value(
    value: cubit,
    child: const SupportView(),
  );

  group('$SupportPage', () {
    testWidgets('SupportPage builds SupportView wrapped in BlocProvider', (tester) async {
      // The real DI-backed page resolves DfxKycService from getIt — the
      // setUpAll above registers a mock for that. Pumping the production
      // entry-point therefore exercises the BlocProvider create lambda.
      final spy = _RouteSpy();
      final router = _routerFor(spy, const SupportPage());
      addTearDown(router.dispose);
      await tester.pumpWidget(_harness(router));
      expect(find.byType(SupportView), findsOne);
    });
  });

  group('$SupportView', () {
    testWidgets('renders both tiles in Idle state, both tappable', (tester) async {
      final spy = _RouteSpy();
      final router = _routerFor(spy, buildSubject());
      addTearDown(router.dispose);

      await tester.pumpWidget(_harness(router));

      final tiles = tester.widgetList<OutlinedTile>(find.byType(OutlinedTile)).toList();
      expect(tiles, hasLength(2));
      // Both onTaps must be wired in Idle — Mail-gate happens after tap.
      expect(tiles[0].onTap, isNotNull);
      expect(tiles[1].onTap, isNotNull);
      expect(find.byType(CupertinoActivityIndicator), findsNothing);
    });

    testWidgets('tapping Create-Ticket tile invokes requestCreateTicket', (tester) async {
      when(() => cubit.requestCreateTicket()).thenAnswer((_) async {});

      final spy = _RouteSpy();
      final router = _routerFor(spy, buildSubject());
      addTearDown(router.dispose);

      await tester.pumpWidget(_harness(router));
      await tester.tap(find.byIcon(Icons.format_list_bulleted_add));
      await tester.pump();

      verify(() => cubit.requestCreateTicket()).called(1);
      // Tap must NOT push createTicket directly — that decision is the
      // cubit's job after it has resolved the user's mail status.
      expect(spy.pushedNames, isEmpty);
    });

    testWidgets('tapping My-Tickets tile pushes SupportRoutes.tickets directly', (tester) async {
      final spy = _RouteSpy();
      final router = _routerFor(spy, buildSubject());
      addTearDown(router.dispose);

      await tester.pumpWidget(_harness(router));
      await tester.tap(find.byIcon(Icons.format_list_bulleted_outlined));
      await tester.pumpAndSettle();

      // My-Tickets bypasses the mail gate by design — see SupportView
      // comment block.
      expect(spy.pushedNames, [SupportRoutes.tickets]);
      verifyNever(() => cubit.requestCreateTicket());
    });

    testWidgets('Navigating state disables tile taps and shows activity indicator', (tester) async {
      when(() => cubit.state).thenReturn(const SupportPageNavigating());

      final spy = _RouteSpy();
      final router = _routerFor(spy, buildSubject());
      addTearDown(router.dispose);

      await tester.pumpWidget(_harness(router));

      final tiles = tester.widgetList<OutlinedTile>(find.byType(OutlinedTile)).toList();
      expect(tiles, hasLength(2));
      expect(tiles[0].onTap, isNull);
      expect(tiles[1].onTap, isNull);
      expect(find.byType(CupertinoActivityIndicator), findsOne);
    });

    testWidgets('NavigateToCreate listener pushes createTicket and acknowledges', (tester) async {
      when(() => cubit.acknowledge()).thenAnswer((_) {});
      whenListen(
        cubit,
        Stream.fromIterable([const SupportPageNavigateToCreate()]),
        initialState: const SupportPageIdle(),
      );

      final spy = _RouteSpy();
      final router = _routerFor(spy, buildSubject());
      addTearDown(router.dispose);

      await tester.pumpWidget(_harness(router));
      await tester.pumpAndSettle();

      expect(spy.pushedNames, [SupportRoutes.createTicket]);
      verify(() => cubit.acknowledge()).called(1);
    });

    testWidgets(
      'NavigateToEmailThenCreate listener pushes emailCapture then createTicket on pop(true)',
      (tester) async {
        when(() => cubit.acknowledge()).thenAnswer((_) {});
        whenListen(
          cubit,
          Stream.fromIterable([const SupportPageNavigateToEmailThenCreate()]),
          initialState: const SupportPageIdle(),
        );

        final spy = _RouteSpy()..emailCapturePopValue = true;
        final router = _routerFor(spy, buildSubject());
        addTearDown(router.dispose);

        await tester.pumpWidget(_harness(router));
        await tester.pumpAndSettle();

        expect(
          spy.pushedNames,
          [SupportRoutes.emailCapture, SupportRoutes.createTicket],
        );
        verify(() => cubit.acknowledge()).called(1);
      },
    );

    testWidgets('NavigateToEmailThenCreate with pop(null) does NOT push createTicket', (
      tester,
    ) async {
      when(() => cubit.acknowledge()).thenAnswer((_) {});
      whenListen(
        cubit,
        Stream.fromIterable([const SupportPageNavigateToEmailThenCreate()]),
        initialState: const SupportPageIdle(),
      );

      // emailCapturePopValue stays null — simulates the user backing out
      // of the email-capture page without saving.
      final spy = _RouteSpy();
      final router = _routerFor(spy, buildSubject());
      addTearDown(router.dispose);

      await tester.pumpWidget(_harness(router));
      await tester.pumpAndSettle();

      expect(spy.pushedNames, [SupportRoutes.emailCapture]);
      verify(() => cubit.acknowledge()).called(1);
    });

    testWidgets(
      'NavigateToEmailThenCreate followed by SupportView unmount does NOT '
      'push createTicket and does NOT crash on context.mounted == false',
      (tester) async {
        // Pins the early-return at support_page.dart:`if (!context.mounted)
        // return;` after the awaited `pushNamed<bool>(emailCapture)`.
        // Sequence:
        //   1. Listener fires NavigateToEmailThenCreate, awaits the
        //      emailCapture push.
        //   2. We unmount the entire tree by pumping an empty
        //      MaterialApp; this disposes the SupportView and its
        //      BlocProvider, so `context.mounted` becomes false.
        //   3. The parked emailCapture completer resolves with `true`,
        //      releasing the `await pushNamed`.
        //   4. The listener must early-return WITHOUT calling
        //      acknowledge() (cubit is disposed) and WITHOUT trying to
        //      push createTicket. Neither must crash the test.
        when(() => cubit.acknowledge()).thenAnswer((_) {});
        whenListen(
          cubit,
          Stream.fromIterable([const SupportPageNavigateToEmailThenCreate()]),
          initialState: const SupportPageIdle(),
        );

        final spy = _RouteSpy()..emailCaptureCompleter = Completer<bool?>();
        final router = _routerFor(spy, buildSubject());
        addTearDown(router.dispose);

        await tester.pumpWidget(_harness(router));
        await tester.pumpAndSettle();

        // The emailCapture route is now sitting on top of the stack and
        // its pop is parked on the completer. SupportView is still
        // mounted underneath. The pushedNames log proves we got that
        // far.
        expect(spy.pushedNames, [SupportRoutes.emailCapture]);

        // Unmount the whole tree — this disposes the GoRouter
        // subscription that hosts SupportView. After this pump the
        // listener's captured `context` no longer satisfies
        // `context.mounted`.
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pump();

        // Release the pushNamed<bool>() future. If the early-return
        // were missing, the listener would either:
        //   - call cubit.acknowledge() on a disposed/detached cubit, or
        //   - call context.pushNamed(createTicket) on a defunct router.
        // Both would surface as a thrown exception in this pump cycle.
        spy.emailCaptureCompleter!.complete(true);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 50));

        // No createTicket push must have happened — the early-return
        // must have skipped both the acknowledge and the chained push.
        expect(spy.pushedNames, [SupportRoutes.emailCapture]);
        // acknowledge() must NOT have been invoked after unmount, since
        // the listener returns BEFORE touching the cubit.
        verifyNever(() => cubit.acknowledge());
        // takeException() is null when no exception has been silently
        // captured by the test framework — proves the unmount path is
        // crash-free.
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets('NavigationFailure listener shows a SnackBar with the message', (tester) async {
      when(() => cubit.acknowledge()).thenAnswer((_) {});
      whenListen(
        cubit,
        Stream.fromIterable([
          const SupportPageNavigationFailure(message: 'getUser blew up'),
        ]),
        initialState: const SupportPageIdle(),
      );

      final spy = _RouteSpy();
      final router = _routerFor(spy, buildSubject());
      addTearDown(router.dispose);

      await tester.pumpWidget(_harness(router));
      await tester.pump();

      expect(find.text('getUser blew up'), findsOne);
      verify(() => cubit.acknowledge()).called(1);
      expect(spy.pushedNames, isEmpty);
    });
  });
}
