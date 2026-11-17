import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:realunit_wallet/generated/i18n.dart';
import 'package:realunit_wallet/screens/referral/referral_terms_page.dart';
import 'package:realunit_wallet/styles/themes.dart';

void main() {
  Future<void> pump(
    WidgetTester tester, {
    required Future<String?> Function(String languageCode) remoteText,
    required Future<String> Function(String assetPath) loadAsset,
  }) async {
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
          remoteText: remoteText,
          loadAsset: loadAsset,
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('shows remote markdown and does not read the asset', (
    tester,
  ) async {
    var assetCalls = 0;
    await pump(
      tester,
      remoteText: (code) async {
        expect(code, 'de');
        return '# Remote terms';
      },
      loadAsset: (_) async {
        assetCalls += 1;
        return '# Asset terms';
      },
    );

    expect(
      tester.widget<MarkdownBody>(find.byType(MarkdownBody)).data,
      contains('Remote terms'),
    );
    expect(assetCalls, 0);
  });

  testWidgets('falls back to the asset when the remote text is blank', (
    tester,
  ) async {
    await pump(
      tester,
      remoteText: (_) async => '  ',
      loadAsset: (path) async {
        expect(path, 'assets/legal/referral_terms_de.md');
        return '# Asset terms';
      },
    );

    expect(
      tester.widget<MarkdownBody>(find.byType(MarkdownBody)).data,
      contains('Asset terms'),
    );
  });

  testWidgets('falls back to the asset when the remote call throws', (
    tester,
  ) async {
    await pump(
      tester,
      remoteText: (_) async => throw Exception('down'),
      loadAsset: (_) async => '# Asset after error',
    );

    expect(
      tester.widget<MarkdownBody>(find.byType(MarkdownBody)).data,
      contains('Asset after error'),
    );
  });
}
