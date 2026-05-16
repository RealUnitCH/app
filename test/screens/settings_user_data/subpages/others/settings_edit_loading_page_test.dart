import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:realunit_wallet/screens/settings_user_data/subpages/others/settings_edit_loading_page.dart';

void main() {
  group('$SettingsEditLoadingPage', () {
    testWidgets('renders the title in the AppBar', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: SettingsEditLoadingPage(title: 'Edit address')),
      );

      expect(find.text('Edit address'), findsOneWidget);
    });

    testWidgets('renders a centered CupertinoActivityIndicator', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: SettingsEditLoadingPage(title: 'X')),
      );

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
