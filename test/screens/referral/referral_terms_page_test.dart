import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:realunit_wallet/generated/i18n.dart';
import 'package:realunit_wallet/packages/service/dfx/models/referral/dto/referral_summary_dto.dart';
import 'package:realunit_wallet/packages/service/dfx/models/referral/dto/referral_terms_dto.dart';
import 'package:realunit_wallet/packages/service/dfx/real_unit_referral_service.dart';
import 'package:realunit_wallet/screens/referral/cubit/referral_cubit.dart';
import 'package:realunit_wallet/screens/referral/referral_error_message.dart';
import 'package:realunit_wallet/screens/referral/referral_terms_page.dart';
import 'package:realunit_wallet/screens/settings/bloc/settings_bloc.dart';
import 'package:realunit_wallet/screens/web_view/web_view_page.dart';
import 'package:realunit_wallet/setup/routing/routes/app_routes.dart';
import 'package:realunit_wallet/styles/language.dart';
import 'package:realunit_wallet/styles/themes.dart';
import 'package:realunit_wallet/widgets/buttons/app_filled_button.dart';

class _MockReferralCubit extends MockCubit<ReferralState> implements ReferralCubit {}

class _MockSettingsBloc extends MockBloc<SettingsEvent, SettingsState> implements SettingsBloc {}

const _summary = ReferralSummaryDto(
  eligible: true,
  termsAccepted: false,
  openCount: 0,
  creditedCount: 0,
  realuSum: 0,
  chfSum: 0,
);

void main() {
  late _MockReferralCubit cubit;

  setUp(() {
    cubit = _MockReferralCubit();
    when(() => cubit.state).thenReturn(const ReferralNeedsTerms(summary: _summary));
    whenListen(
      cubit,
      const Stream<ReferralState>.empty(),
      initialState: const ReferralNeedsTerms(summary: _summary),
    );
    when(() => cubit.acceptTerms(version: any(named: 'version'))).thenAnswer((_) async {});
  });

  testWidgets(
    'create-invite CTA stays disabled until the accepted-terms checkbox is on',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: realUnitTheme,
          locale: const Locale('de'),
          localizationsDelegates: const [
            S.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
          ],
          supportedLocales: S.delegate.supportedLocales,
          home: BlocProvider<ReferralCubit>.value(
            value: cubit,
            child: const ReferralTermsPage(
              initialMarkdownContent: '# Teilnahmebedingungen',
            ),
          ),
        ),
      );
      await tester.pump();

      expect(
        find.text('Teilnahmebedingungen Referral-Programm'),
        findsOneWidget,
      );
      expect(tester.widget<MarkdownBody>(find.byType(MarkdownBody)).selectable, isTrue);
      expect(tester.widget<MarkdownBody>(find.byType(MarkdownBody)).onTapLink, isNotNull);

      final button = tester.widget<AppFilledButton>(find.byType(AppFilledButton));
      expect(button.onPressed, isNull);

      await tester.tap(find.byType(CheckboxListTile));
      await tester.pump();

      final enabled = tester.widget<AppFilledButton>(find.byType(AppFilledButton));
      expect(enabled.onPressed, isNotNull);

      await tester.tap(find.byType(AppFilledButton));
      await tester.pump();
      verify(
        () => cubit.acceptTerms(version: ReferralTermsDto.bundledVersion),
      ).called(1);
    },
  );

  testWidgets(
    'read-only after accept hides the checkbox and create CTA',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: realUnitTheme,
          locale: const Locale('de'),
          localizationsDelegates: const [
            S.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
          ],
          supportedLocales: S.delegate.supportedLocales,
          home: const ReferralTermsPage(
            readOnly: true,
            initialMarkdownContent: '# Teilnahmebedingungen',
          ),
        ),
      );
      await tester.pump();

      expect(find.textContaining('Teilnahmebedingungen'), findsWidgets);
      expect(find.byType(CheckboxListTile), findsNothing);
      expect(find.byType(AppFilledButton), findsNothing);
    },
  );

  testWidgets(
    'read-only loads assets via loadAsset',
    (tester) async {
      final service = _MockReferralService();
      when(() => service.getTerms()).thenAnswer(
        (_) async => const ReferralTermsDto(
          version: '2026-09-01',
          markdown: '# API TB must not show',
          markdownEn: '# API EN',
        ),
      );
      GetIt.instance.registerSingleton<RealUnitReferralService>(service);
      addTearDown(() async {
        await GetIt.instance.reset();
      });

      await tester.pumpWidget(
        MaterialApp(
          theme: realUnitTheme,
          locale: const Locale('de'),
          localizationsDelegates: const [
            S.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
          ],
          supportedLocales: S.delegate.supportedLocales,
          home: ReferralTermsPage(
            readOnly: true,
            loadAsset: (path) async {
              expect(path, 'assets/legal/referral_terms_de.md');
              return '# Asset TB after accept';
            },
          ),
        ),
      );
      await tester.pump();
      await tester.pump();

      expect(find.textContaining('Asset TB after accept'), findsOneWidget);
      expect(find.textContaining('API TB must not show'), findsNothing);
      expect(find.byType(CheckboxListTile), findsNothing);
      verifyNever(() => service.getTerms());
    },
  );

  testWidgets('shows the API error from a failed terms accept', (tester) async {
    when(() => cubit.state).thenReturn(
      const ReferralNeedsTerms(
        summary: _summary,
        errorMessage: referralUnavailableMessage,
      ),
    );
    whenListen(
      cubit,
      const Stream<ReferralState>.empty(),
      initialState: const ReferralNeedsTerms(
        summary: _summary,
        errorMessage: referralUnavailableMessage,
      ),
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: realUnitTheme,
        locale: const Locale('de'),
        localizationsDelegates: const [
          S.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
        ],
        supportedLocales: S.delegate.supportedLocales,
        home: BlocProvider<ReferralCubit>.value(
          value: cubit,
          child: const ReferralTermsPage(
            initialMarkdownContent: '# Teilnahmebedingungen',
          ),
        ),
      ),
    );
    await tester.pump();

    expect(
      find.text('Wir konnten den Code gerade nicht prüfen. Bitte versuche es später erneut.'),
      findsOneWidget,
    );
    expect(
      find.ancestor(
        of: find.text(
          'Wir konnten den Code gerade nicht prüfen. Bitte versuche es später erneut.',
        ),
        matching: find.byWidgetPredicate(
          (widget) => widget is Semantics && widget.properties.liveRegion == true,
        ),
      ),
      findsOneWidget,
    );
    expect(
      tester.widget<AppFilledButton>(find.byType(AppFilledButton)).autofocus,
      isFalse,
    );
    await tester.tap(find.byType(CheckboxListTile));
    await tester.pump();
    expect(
      tester.widget<AppFilledButton>(find.byType(AppFilledButton)).autofocus,
      isTrue,
    );
    expect(
      tester.widget<AppFilledButton>(find.byType(AppFilledButton)).onPressed,
      isNotNull,
    );
  });

  testWidgets('accepting announces a live region', (tester) async {
    when(() => cubit.state).thenReturn(
      const ReferralTermsAccepting(summary: _summary),
    );
    whenListen(
      cubit,
      const Stream<ReferralState>.empty(),
      initialState: const ReferralTermsAccepting(summary: _summary),
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: realUnitTheme,
        locale: const Locale('de'),
        localizationsDelegates: const [
          S.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
        ],
        supportedLocales: S.delegate.supportedLocales,
        home: BlocProvider<ReferralCubit>.value(
          value: cubit,
          child: const ReferralTermsPage(
            initialMarkdownContent: '# Teilnahmebedingungen',
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Teilnahmebedingungen werden akzeptiert…'), findsOneWidget);
    expect(
      find.ancestor(
        of: find.text('Teilnahmebedingungen werden akzeptiert…'),
        matching: find.byWidgetPredicate(
          (widget) => widget is Semantics && widget.properties.liveRegion == true,
        ),
      ),
      findsOneWidget,
    );
    final tile = tester.widget<CheckboxListTile>(find.byType(CheckboxListTile));
    expect(tile.onChanged, isNull);
  });

  testWidgets(
    'keeps the accept error while the retry PUT is in flight',
    (tester) async {
      when(() => cubit.state).thenReturn(
        const ReferralTermsAccepting(
          summary: _summary,
          errorMessage: referralUnavailableMessage,
        ),
      );
      whenListen(
        cubit,
        const Stream<ReferralState>.empty(),
        initialState: const ReferralTermsAccepting(
          summary: _summary,
          errorMessage: referralUnavailableMessage,
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: realUnitTheme,
          locale: const Locale('de'),
          localizationsDelegates: const [
            S.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
          ],
          supportedLocales: S.delegate.supportedLocales,
          home: BlocProvider<ReferralCubit>.value(
            value: cubit,
            child: const ReferralTermsPage(
              initialMarkdownContent: '# Teilnahmebedingungen',
            ),
          ),
        ),
      );
      await tester.pump();

      expect(
        find.text(
          'Wir konnten den Code gerade nicht prüfen. Bitte versuche es später erneut.',
        ),
        findsOneWidget,
      );
      expect(
        find.text('Teilnahmebedingungen werden akzeptiert…'),
        findsNothing,
      );
      expect(
        tester.widget<AppFilledButton>(find.byType(AppFilledButton)).state,
        FilledButtonState.loading,
      );
    },
  );

  testWidgets(
    'throwing getTerms still shows asset text if loadAsset is provided',
    (tester) async {
      final service = _MockReferralService();
      when(() => service.getTerms()).thenThrow(Exception('down'));
      GetIt.instance.registerSingleton<RealUnitReferralService>(service);
      addTearDown(() async {
        await GetIt.instance.reset();
      });

      await tester.pumpWidget(
        MaterialApp(
          theme: realUnitTheme,
          locale: const Locale('de'),
          localizationsDelegates: const [
            S.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
          ],
          supportedLocales: S.delegate.supportedLocales,
          home: BlocProvider<ReferralCubit>.value(
            value: cubit,
            child: ReferralTermsPage(
              loadAsset: (_) async => '# Asset TB 26.08',
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump();

      expect(find.textContaining('Asset TB 26.08'), findsOneWidget);
      expect(find.text('Wiederholen'), findsNothing);
      expect(find.byType(MarkdownBody), findsOneWidget);
      verifyNever(() => service.getTerms());
    },
  );

  testWidgets(
    'shows Retry when loadAsset throws',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: realUnitTheme,
          locale: const Locale('de'),
          localizationsDelegates: const [
            S.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
          ],
          supportedLocales: S.delegate.supportedLocales,
          home: BlocProvider<ReferralCubit>.value(
            value: cubit,
            child: ReferralTermsPage(
              loadAsset: (_) async => throw Exception('missing asset'),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pumpAndSettle();

      expect(find.textContaining('Dokument konnte nicht geladen'), findsOneWidget);
      expect(find.text('Wiederholen'), findsOneWidget);
      expect(find.byType(MarkdownBody), findsNothing);
    },
  );

  testWidgets('checkbox is hidden until the TB markdown has loaded', (
    tester,
  ) async {
    final pendingAsset = Completer<String>();
    await tester.pumpWidget(
      MaterialApp(
        theme: realUnitTheme,
        locale: const Locale('de'),
        localizationsDelegates: const [
          S.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
        ],
        supportedLocales: S.delegate.supportedLocales,
        home: BlocProvider<ReferralCubit>.value(
          value: cubit,
          child: ReferralTermsPage(
            loadAsset: (_) => pendingAsset.future,
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.byType(CheckboxListTile), findsNothing);
    final button = tester.widget<AppFilledButton>(find.byType(AppFilledButton));
    expect(button.onPressed, isNull);
    expect(find.text('Teilnahmebedingungen werden geladen…'), findsOneWidget);
    expect(
      find.ancestor(
        of: find.text('Teilnahmebedingungen werden geladen…'),
        matching: find.byWidgetPredicate(
          (widget) => widget is Semantics && widget.properties.liveRegion == true,
        ),
      ),
      findsOneWidget,
    );
  });

  testWidgets(
    'terms Retry ignores a second tap while markdown is reloading',
    (tester) async {
      var calls = 0;
      final retryAsset = Completer<String>();

      await tester.pumpWidget(
        MaterialApp(
          theme: realUnitTheme,
          locale: const Locale('de'),
          localizationsDelegates: const [
            S.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
          ],
          supportedLocales: S.delegate.supportedLocales,
          home: BlocProvider<ReferralCubit>.value(
            value: cubit,
            child: ReferralTermsPage(
              loadAsset: (_) async {
                calls += 1;
                if (calls == 1) throw Exception('down');
                return retryAsset.future;
              },
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump();
      expect(find.text('Wiederholen'), findsOneWidget);
      expect(calls, 1);

      final retry = find.widgetWithText(AppFilledButton, 'Wiederholen');
      await tester.tap(retry);
      await tester.tap(retry);
      await tester.pump();
      expect(calls, 2);
      expect(find.text('Wiederholen'), findsOneWidget);
      expect(
        find.textContaining('Dokument konnte nicht geladen'),
        findsOneWidget,
      );
      expect(
        tester
            .widget<AppFilledButton>(
              find.widgetWithText(AppFilledButton, 'Wiederholen'),
            )
            .state,
        FilledButtonState.loading,
      );
    },
  );

  testWidgets(
    'ignores a stale terms load after a later load of another language',
    (tester) async {
      final first = Completer<String>();
      final second = Completer<String>();
      final paths = <String>[];

      final locale = ValueNotifier(const Locale('de'));
      addTearDown(locale.dispose);

      await tester.pumpWidget(
        ValueListenableBuilder<Locale>(
          valueListenable: locale,
          builder: (context, value, _) {
            return MaterialApp(
              theme: realUnitTheme,
              locale: value,
              localizationsDelegates: const [
                S.delegate,
                GlobalMaterialLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
              ],
              supportedLocales: S.delegate.supportedLocales,
              home: BlocProvider<ReferralCubit>.value(
                value: cubit,
                child: ReferralTermsPage(
                  loadAsset: (path) {
                    paths.add(path);
                    if (path.endsWith('referral_terms_en.md')) {
                      return second.future;
                    }
                    return first.future;
                  },
                ),
              ),
            );
          },
        ),
      );
      await tester.pump();
      expect(paths, ['assets/legal/referral_terms_de.md']);

      locale.value = const Locale('en');
      await tester.pump();
      expect(paths, [
        'assets/legal/referral_terms_de.md',
        'assets/legal/referral_terms_en.md',
      ]);

      second.complete('# New EN terms');
      await tester.pump();
      expect(find.textContaining('New EN terms'), findsOneWidget);

      first.complete('# Stale DE');
      await tester.pump();
      expect(find.textContaining('New EN terms'), findsOneWidget);
      expect(find.textContaining('Stale DE'), findsNothing);
    },
  );

  test('only http(s) terms links open in the in-app browser', () {
    expect(
      referralTermsOpensInApp('https://realunit.ch/downloads/'),
      isTrue,
    );
    expect(referralTermsOpensInApp('http://example.com/tb'), isTrue);
    expect(referralTermsOpensInApp('mailto:info@realunit.ch'), isFalse);
    expect(referralTermsOpensInApp('javascript:alert(1)'), isFalse);
    expect(referralTermsOpensInApp('info@realunit.ch'), isFalse);
    expect(referralTermsOpensInApp('realunit-wallet://invite/AB12CD'), isFalse);
    expect(referralTermsOpensInApp(null), isFalse);
    expect(referralTermsOpensInApp(''), isFalse);
    expect(referralTermsOpensInApp('/downloads/'), isTrue);
    expect(
      referralTermsInAppUri('/downloads/prospekt.pdf'),
      Uri.parse('https://realunit.ch/downloads/prospekt.pdf'),
    );
    expect(
      referralTermsInAppUri('https://realunit.ch/downloads/'),
      Uri.parse('https://realunit.ch/downloads/'),
    );
    expect(referralTermsInAppUri('mailto:info@realunit.ch'), isNull);
    expect(referralTermsInAppUri('../secret'), isNull);
    expect(
      referralTermsInAppUri('//realunit.ch/downloads/'),
      Uri.parse('https://realunit.ch/downloads/'),
    );
    expect(
      referralTermsInAppUri('//docs.dfx.swiss/de/tnc.html'),
      Uri.parse('https://docs.dfx.swiss/de/tnc.html'),
    );
  });

  testWidgets(
    'loads assets in the SettingsBloc language, not the widget locale',
    (tester) async {
      final settings = _MockSettingsBloc();
      const settingsState = SettingsState(language: Language.de);
      when(() => settings.state).thenReturn(settingsState);
      GetIt.instance.registerSingleton<SettingsBloc>(settings);
      addTearDown(() async {
        await GetIt.instance.reset();
      });

      await tester.pumpWidget(
        MaterialApp(
          theme: realUnitTheme,
          locale: const Locale('en'),
          localizationsDelegates: const [
            S.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
          ],
          supportedLocales: S.delegate.supportedLocales,
          home: BlocProvider<ReferralCubit>.value(
            value: cubit,
            child: ReferralTermsPage(
              loadAsset: (path) async {
                if (path.endsWith('referral_terms_de.md')) {
                  return '# DE-ASSET-FROM-BLOC';
                }
                if (path.endsWith('referral_terms_en.md')) {
                  return '# EN-ASSET-FROM-LOCALE';
                }
                throw Exception('unexpected $path');
              },
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump();

      expect(find.textContaining('DE-ASSET-FROM-BLOC'), findsOneWidget);
      expect(find.textContaining('EN-ASSET-FROM-LOCALE'), findsNothing);

      await tester.tap(find.byType(CheckboxListTile));
      await tester.pump();
      await tester.tap(find.byType(AppFilledButton));
      verify(
        () => cubit.acceptTerms(version: ReferralTermsDto.bundledVersion),
      ).called(1);
    },
  );

  testWidgets('http(s) terms links open the in-app web view', (tester) async {
    late WebViewRouteParams params;
    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (_, _) => BlocProvider<ReferralCubit>.value(
            value: cubit,
            child: const ReferralTermsPage(
              initialMarkdownContent: '[Prospekt](https://realunit.ch/downloads/p.pdf)',
            ),
          ),
        ),
        GoRoute(
          name: AppRoutes.webView,
          path: '/webView',
          builder: (_, state) {
            params = state.extra! as WebViewRouteParams;
            return const Scaffold(body: Text('WEB'));
          },
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      MaterialApp.router(
        theme: realUnitTheme,
        locale: const Locale('de'),
        localizationsDelegates: const [
          S.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
        ],
        supportedLocales: S.delegate.supportedLocales,
        routerConfig: router,
      ),
    );
    await tester.pump();

    tester.widget<MarkdownBody>(find.byType(MarkdownBody)).onTapLink!(
      'Prospekt',
      'https://realunit.ch/downloads/p.pdf',
      '',
    );
    await tester.pump();
    await tester.pump();

    expect(find.text('WEB'), findsOneWidget);
    expect(params.title, 'Prospekt');
    expect(params.url, Uri.parse('https://realunit.ch/downloads/p.pdf'));
  });

  testWidgets('mailto terms links stay on the terms page', (tester) async {
    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (_, _) => BlocProvider<ReferralCubit>.value(
            value: cubit,
            child: const ReferralTermsPage(
              initialMarkdownContent: '[Mail](mailto:info@realunit.ch)',
            ),
          ),
        ),
        GoRoute(
          name: AppRoutes.webView,
          path: '/webView',
          builder: (_, _) => const Scaffold(body: Text('WEB')),
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      MaterialApp.router(
        theme: realUnitTheme,
        locale: const Locale('de'),
        localizationsDelegates: const [
          S.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
        ],
        supportedLocales: S.delegate.supportedLocales,
        routerConfig: router,
      ),
    );
    await tester.pump();

    tester.widget<MarkdownBody>(find.byType(MarkdownBody)).onTapLink!(
      'Mail',
      'mailto:info@realunit.ch',
      '',
    );
    await tester.pump();

    expect(find.text('WEB'), findsNothing);
    expect(
      find.text('Teilnahmebedingungen Referral-Programm'),
      findsOneWidget,
    );
  });
}

class _MockReferralService extends Mock implements RealUnitReferralService {}
