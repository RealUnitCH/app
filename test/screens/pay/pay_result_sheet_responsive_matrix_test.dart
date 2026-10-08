// Responsive matrix for PayResultSheet.
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:realunit_wallet/generated/i18n.dart';
import 'package:realunit_wallet/screens/pay/widgets/pay_result_sheet.dart';
import 'package:realunit_wallet/styles/themes.dart';
import 'package:realunit_wallet/widgets/buttons/app_filled_button.dart';

import '../../helper/helper.dart';

void main() {
  /// Pumps a sheet the way production shows it: real [showModalBottomSheet]
  /// with [isScrollControlled] matching the pay-result call site (true).
  Future<void> pumpModalSheet(
    WidgetTester tester,
    MatrixCell cell, {
    required WidgetBuilder sheetBuilder,
  }) async {
    await tester.binding.setSurfaceSize(cell.device.size);
    addTearDown(() async => await tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MediaQuery(
        data: cell.mediaQuery,
        child: MaterialApp(
          theme: realUnitTheme,
          locale: const Locale('de'),
          localizationsDelegates: const [
            S.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
          ],
          supportedLocales: S.delegate.supportedLocales,
          home: Scaffold(
            body: Center(
              child: Builder(
                builder: (context) => ElevatedButton(
                  onPressed: () {
                    showModalBottomSheet<void>(
                      isScrollControlled: true,
                      context: context,
                      builder: sheetBuilder,
                    );
                  },
                  child: const Text('open-sheet'),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    await tester.tap(find.text('open-sheet'));
    await tester.pumpAndSettle();
  }

  group('PayResultSheet close-only responsive matrix (full device × textScale)', () {
    for (final cell in kFullResponsiveMatrix) {
      testWidgets(cell.id, (tester) async {
        await withTargetPlatform(cell.device.platform, () async {
          await expectNoLayoutOverflow(
            tester,
            () async {
              await pumpModalSheet(
                tester,
                cell,
                sheetBuilder: (context) => PayResultSheet(
                  icon: Icons.error_rounded,
                  title: S.of(context).payFailureTitle,
                  description: S.of(context).payFailureGeneric,
                  closeLabel: S.of(context).close,
                  onClose: () {},
                ),
              );
            },
            reason: 'overflow on PayResultSheet close-only / ${cell.label}',
          );

          await expectFullyTappable(
            tester,
            find.byType(AppFilledButton),
            within: find.byType(PayResultSheet),
            reason: 'PayResultSheet close-only / ${cell.label}: CTA not tappable',
          );
        });
      });
    }
  });

  group('PayResultSheet close+retry responsive matrix (full device × textScale)', () {
    for (final cell in kFullResponsiveMatrix) {
      testWidgets(cell.id, (tester) async {
        await withTargetPlatform(cell.device.platform, () async {
          Widget retrySheet(BuildContext context) => PayResultSheet(
            icon: Icons.replay_rounded,
            title: S.of(context).payRetryTitle,
            description: S.of(context).payRetryTransient,
            closeLabel: S.of(context).close,
            onClose: () {},
            primaryLabel: S.of(context).payRetryButton,
            onPrimary: () {},
          );

          await expectNoLayoutOverflow(
            tester,
            () async {
              await pumpModalSheet(
                tester,
                cell,
                sheetBuilder: retrySheet,
              );
            },
            reason: 'overflow on PayResultSheet close+retry / ${cell.label}',
          );

          expect(
            find.byType(AppFilledButton),
            findsNWidgets(2),
            reason: 'PayResultSheet close+retry / ${cell.label}: expected 2 CTAs',
          );

          await expectFullyTappable(
            tester,
            find.widgetWithText(AppFilledButton, S.current.close),
            within: find.byType(PayResultSheet),
            reason:
                'PayResultSheet close+retry / ${cell.label}: Close CTA not tappable',
          );

          // expectFullyTappable taps for real — reopen before asserting the
          // second button, as ForgotPinBottomSheet does.
          await expectNoLayoutOverflow(
            tester,
            () async {
              await pumpModalSheet(
                tester,
                cell,
                sheetBuilder: retrySheet,
              );
            },
            reason: 'PayResultSheet re-open overflow / ${cell.label}',
          );

          await expectFullyTappable(
            tester,
            find.widgetWithText(AppFilledButton, S.current.payRetryButton),
            within: find.byType(PayResultSheet),
            reason:
                'PayResultSheet close+retry / ${cell.label}: Retry CTA not tappable',
          );
        });
      });
    }
  });
}
