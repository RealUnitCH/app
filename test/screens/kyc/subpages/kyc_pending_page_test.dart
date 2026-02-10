import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:realunit_wallet/screens/kyc/cubits/kyc/kyc_cubit.dart';
import 'package:realunit_wallet/screens/kyc/subpages/kyc_pending_page.dart';
import 'package:realunit_wallet/widgets/text_substring_highlighting.dart';

import '../../../helper/helper.dart';

void main() {
  final KycStep pendingStep = KycStep.ident;

  group('$KycPendingPage', () {
    testWidgets('is initially rendered correctly', (tester) async {
      await tester.pumpApp(KycPendingPage(pendingStep: pendingStep));

      expect(
        find.byWidgetPredicate(
          (widget) =>
              widget is Text &&
              widget.style ==
                  const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w700,
                    height: 30 / 26,
                    letterSpacing: -0.52,
                  ),
        ),
        findsOne,
      );
      expect(
        find.byType(TextSubstringHighlighting),
        findsOne,
      );
      expect(find.byType(FilledButton), findsOne);
    });
  });
}
