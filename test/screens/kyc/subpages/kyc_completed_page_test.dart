import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:realunit_wallet/screens/kyc/subpages/kyc_completed_page.dart';

import '../../../helper/helper.dart';

void main() {
  group('$KycCompletedPage', () {
    testWidgets('is initially rendered correctly', (tester) async {
      await tester.pumpApp(const KycCompletedPage());

      expect(
        find.byWidgetPredicate(
          (widget) =>
              widget is Text &&
              widget.style ==
                  const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 26,
                    letterSpacing: 26 * -0.02,
                    height: 30 / 26,
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
                    fontSize: 14,
                    height: 18 / 14,
                    letterSpacing: 0.0,
                  ),
        ),
        findsOne,
      );
      expect(find.byType(FilledButton), findsOne);
    });
  });
}
