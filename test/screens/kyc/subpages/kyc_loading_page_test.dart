import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:realunit_wallet/screens/kyc/subpages/kyc_loading_page.dart';

void main() {
  group('$KycLoadingPage', () {
    testWidgets('renders an AppBar + centered CupertinoActivityIndicator',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: KycLoadingPage()),
      );

      expect(find.byType(AppBar), findsOneWidget);
      expect(find.byType(CupertinoActivityIndicator), findsOneWidget);
      // The spinner sits inside a Center so it remains visible across screen
      // sizes.
      expect(
        find.descendant(
          of: find.byType(Center),
          matching: find.byType(CupertinoActivityIndicator),
        ),
        findsOneWidget,
      );
    });
  });
}
