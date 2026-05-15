import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:realunit_wallet/widgets/action_button.dart';

void main() {
  group('$ActionButton', () {
    testWidgets('renders icon + label when not loading', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ActionButton(
              icon: Icon(Icons.arrow_upward),
              label: 'Send',
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.arrow_upward), findsOneWidget);
      expect(find.text('Send'), findsOneWidget);
      expect(find.byType(CupertinoActivityIndicator), findsNothing);
    });

    testWidgets('renders the activity indicator and hides icon + label when isLoading=true',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ActionButton(
              icon: Icon(Icons.arrow_upward),
              label: 'Send',
              isLoading: true,
            ),
          ),
        ),
      );

      expect(find.byType(CupertinoActivityIndicator), findsOneWidget);
      expect(find.byIcon(Icons.arrow_upward), findsNothing);
      expect(find.text('Send'), findsNothing);
    });

    testWidgets('tap fires onPressed when enabled', (tester) async {
      var tapped = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ActionButton(
              icon: const Icon(Icons.arrow_upward),
              label: 'Send',
              onPressed: () => tapped++,
            ),
          ),
        ),
      );

      await tester.tap(find.byType(ActionButton));
      await tester.pump();

      expect(tapped, 1);
    });

    testWidgets('tap is disabled while loading', (tester) async {
      var tapped = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ActionButton(
              icon: const Icon(Icons.arrow_upward),
              label: 'Send',
              isLoading: true,
              onPressed: () => tapped++,
            ),
          ),
        ),
      );

      await tester.tap(find.byType(ActionButton));
      await tester.pump();

      // The InkWell receives onTap: null while loading, so the callback never
      // fires — pinned via the counter staying at 0.
      expect(tapped, 0);
    });
  });
}
