import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:realunit_wallet/widgets/info_row.dart';

void main() {
  group('$InfoRow', () {
    testWidgets('renders the leading label with a trailing colon', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: InfoRow(leading: 'IBAN', trailing: 'CH...'),
          ),
        ),
      );

      // The leading label gets a ":" appended.
      expect(find.text('IBAN:'), findsOneWidget);
      // The trailing value is rendered verbatim.
      expect(find.text('CH...'), findsOneWidget);
    });

    testWidgets('default padding is 5 top + 5 bottom', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: InfoRow(leading: 'A', trailing: 'B'),
          ),
        ),
      );

      final padding = tester.widget<Padding>(find.byType(Padding).first);
      expect(
        padding.padding,
        const EdgeInsets.only(top: 5, bottom: 5),
      );
    });

    testWidgets('custom padding overrides the default', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: InfoRow(
              leading: 'A',
              trailing: 'B',
              padding: EdgeInsets.all(20),
            ),
          ),
        ),
      );

      final padding = tester.widget<Padding>(find.byType(Padding).first);
      expect(padding.padding, const EdgeInsets.all(20));
    });
  });
}
