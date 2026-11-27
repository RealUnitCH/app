// Responsive matrix for the email code page: no overflow, and both sticky
// actions (Next and "Send code again") stay fully tappable in the idle,
// verifying and resending states.
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:realunit_wallet/generated/i18n.dart';
import 'package:realunit_wallet/screens/kyc/steps/email/cubits/email_code/kyc_email_code_cubit.dart';
import 'package:realunit_wallet/screens/kyc/steps/email/subpages/kyc_email_code_page.dart';
import 'package:realunit_wallet/styles/themes.dart';
import 'package:realunit_wallet/widgets/buttons/app_filled_button.dart';
import 'package:realunit_wallet/widgets/buttons/app_text_button.dart';

import '../../../../helper/helper.dart';

class _MockKycEmailCodeCubit extends MockCubit<KycEmailCodeState> implements KycEmailCodeCubit {}

Future<void> _pumpMatrixPage(
  WidgetTester tester, {
  required Widget widget,
  required MatrixCell cell,
}) async {
  await tester.binding.setSurfaceSize(cell.device.size);
  addTearDown(() async => tester.binding.setSurfaceSize(null));

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
        home: widget,
      ),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 50));
}

void main() {
  const states = <String, KycEmailCodeState>{
    'idle': KycEmailCodeInitial(),
    'verifying': KycEmailCodeVerifying(),
    'resending': KycEmailCodeResending(),
  };

  for (final entry in states.entries) {
    group('$KycEmailCodeView ${entry.key} responsive matrix (full device × textScale)', () {
      late _MockKycEmailCodeCubit cubit;

      setUp(() {
        cubit = _MockKycEmailCodeCubit();
        when(() => cubit.state).thenReturn(entry.value);
        when(() => cubit.email).thenReturn('max.mustermann@example.com');
        when(() => cubit.verify(any())).thenAnswer((_) async {});
        when(() => cubit.resend()).thenAnswer((_) async {});
      });

      Widget buildSubject() => BlocProvider<KycEmailCodeCubit>.value(
        value: cubit,
        child: const KycEmailCodeView(),
      );

      for (final cell in kFullResponsiveMatrix) {
        testWidgets('email_code_${entry.key} · ${cell.id}', (tester) async {
          await withTargetPlatform(cell.device.platform, () async {
            await expectNoLayoutOverflow(
              tester,
              () async {
                await _pumpMatrixPage(tester, widget: buildSubject(), cell: cell);
              },
              reason: 'overflow on email_code_${entry.key} / ${cell.label}',
            );

            await expectFullyTappable(
              tester,
              find.byType(AppFilledButton),
              within: find.byType(KycEmailCodeView),
              reason: 'email_code_${entry.key} / ${cell.label}: Next not tappable',
            );
            await expectFullyTappable(
              tester,
              find.byType(AppTextButton),
              within: find.byType(KycEmailCodeView),
              reason: 'email_code_${entry.key} / ${cell.label}: resend not tappable',
            );
          });
        });
      }
    });
  }
}
