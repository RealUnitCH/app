import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:realunit_wallet/screens/kyc/subpages/kyc_failure_page.dart';
import 'package:realunit_wallet/styles/colors.dart';

import '../../../helper/helper.dart';

void main() {
  final message = 'something went wrong';

  group('$KycFailurePage', () {
    testWidgets('is initially rendered correctly', (tester) async {
      await tester.pumpApp(KycFailurePage(message: message));

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
        find.byWidgetPredicate(
          (widget) =>
              widget is Text &&
              widget.style ==
                  const TextStyle(
                    color: RealUnitColors.neutral500,
                    fontSize: 14,
                    height: 18 / 14,
                    letterSpacing: 0.0,
                  ),
        ),
        findsOne,
      );
    });
  });
}
