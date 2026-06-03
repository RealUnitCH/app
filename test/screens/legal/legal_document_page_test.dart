import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:realunit_wallet/generated/i18n.dart';
import 'package:realunit_wallet/screens/legal/subpages/legal_document_page.dart';
import 'package:realunit_wallet/screens/settings/bloc/settings_bloc.dart';
import 'package:realunit_wallet/styles/language.dart';

import '../../helper/helper.dart';

void main() {
  late MockSettingsBloc settingsBloc;

  setUp(() {
    // The page loads its document from rootBundle, which caches results per
    // asset path. Clear it between tests so a missing-asset load fails fresh
    // each time instead of returning a sibling test's cached future.
    rootBundle.clear();
    settingsBloc = MockSettingsBloc();
    when(() => settingsBloc.state).thenReturn(const SettingsState(language: Language.en));
  });

  Widget host({
    String assetBaseName = 'terms',
    String? initialMarkdownContent,
  }) => BlocProvider<SettingsBloc>.value(
    value: settingsBloc,
    child: LegalDocumentPage(
      params: LegalDocumentParams(
        title: 'Terms',
        assetBaseName: assetBaseName,
      ),
      initialMarkdownContent: initialMarkdownContent,
    ),
  );

  group('$LegalDocumentPage', () {
    testWidgets(
      'shows an error with a retry action when the document asset fails to load '
      '(regression for #19: silent blank page)',
      (tester) async {
        // No bundled asset for this base name -> rootBundle.loadString throws.
        await tester.pumpApp(host(assetBaseName: 'missing_legal_asset_test'));
        await tester.pumpAndSettle();

        expect(
          find.byKey(const ValueKey('legalDocumentLoadError')),
          findsOneWidget,
          reason: 'a failed asset load must surface an error state, not a blank page',
        );
        expect(
          find.byKey(const ValueKey('legalDocumentRetryButton')),
          findsOneWidget,
          reason: 'the error state must offer a retry affordance',
        );
        expect(
          find.byIcon(Icons.error_outline),
          findsOneWidget,
          reason: 'the error state should render the standard error icon',
        );
        expect(
          find.text(S.current.legalDocumentLoadFailedDescription),
          findsOneWidget,
          reason: 'the error state should explain what went wrong',
        );
      },
    );

    testWidgets('renders the markdown body when content is provided', (tester) async {
      await tester.pumpApp(host(initialMarkdownContent: '# Hello'));
      await tester.pumpAndSettle();

      expect(find.byType(Markdown), findsOneWidget);
      expect(find.byKey(const ValueKey('legalDocumentLoadError')), findsNothing);
    });

    testWidgets('retry re-runs the load and stays in the error state while the asset is missing', (
      tester,
    ) async {
      await tester.pumpApp(host(assetBaseName: 'missing_legal_asset_test'));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('legalDocumentRetryButton')));
      await tester.pumpAndSettle();

      // The asset is still missing, so we expect the error state to persist
      // without throwing — exercising the retry path.
      expect(find.byKey(const ValueKey('legalDocumentLoadError')), findsOneWidget);
    });

    testWidgets('retry recovers and renders the document once the asset loads', (
      tester,
    ) async {
      const baseName = 'recoverable_legal_asset_test';
      const assetKey = 'assets/legal/${baseName}_en.md';
      var failNext = true;

      // Mock the asset channel so the first load fails and, after retry, the
      // second load succeeds — exercising the full error -> retry -> loaded path.
      final messenger = tester.binding.defaultBinaryMessenger;
      messenger.setMockMessageHandler('flutter/assets', (ByteData? message) async {
        final key = utf8.decode(
          message!.buffer.asUint8List(message.offsetInBytes, message.lengthInBytes),
        );
        if (key == assetKey && !failNext) {
          return ByteData.sublistView(Uint8List.fromList(utf8.encode('# Recovered')));
        }
        return null; // missing asset -> loadString throws
      });
      addTearDown(() => messenger.setMockMessageHandler('flutter/assets', null));

      await tester.pumpApp(host(assetBaseName: baseName));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('legalDocumentLoadError')), findsOneWidget);

      failNext = false;
      await tester.tap(find.byKey(const ValueKey('legalDocumentRetryButton')));
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('legalDocumentLoadError')), findsNothing);
      expect(find.byType(Markdown), findsOneWidget);
    });
  });
}
