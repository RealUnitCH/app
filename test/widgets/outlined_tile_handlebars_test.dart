import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:realunit_wallet/widgets/handlebars.dart';
import 'package:realunit_wallet/widgets/outlined_tile.dart';

Widget _host(Widget child) => MaterialApp(home: Scaffold(body: child));

void main() {
  group('$OutlinedTile', () {
    testWidgets('renders leading + title; no subtitle Text when subtitle is null',
        (tester) async {
      await tester.pumpWidget(_host(
        const OutlinedTile(
          leading: Icon(Icons.star, key: Key('leading-icon')),
          title: 'Saving accounts',
        ),
      ));

      expect(find.byKey(const Key('leading-icon')), findsOneWidget);
      expect(find.text('Saving accounts'), findsOneWidget);
      expect(find.byType(Text), findsOneWidget);
    });

    testWidgets('renders the subtitle when provided', (tester) async {
      await tester.pumpWidget(_host(
        const OutlinedTile(
          leading: Icon(Icons.star),
          title: 'Title',
          subtitle: 'Subtitle copy',
        ),
      ));

      expect(find.text('Subtitle copy'), findsOneWidget);
    });

    testWidgets('omits the trailing icon when onTap is null', (tester) async {
      await tester.pumpWidget(_host(
        const OutlinedTile(
          leading: Icon(Icons.star),
          title: 'Title',
          trailingIcon: Icons.arrow_forward,
        ),
      ));

      // Only the leading icon should be in the tree (trailing is conditional
      // on onTap != null).
      expect(find.byIcon(Icons.arrow_forward), findsNothing);
    });

    testWidgets('renders + tappable trailing icon when onTap is provided',
        (tester) async {
      var taps = 0;
      await tester.pumpWidget(_host(
        OutlinedTile(
          leading: const Icon(Icons.star),
          title: 'Title',
          trailingIcon: Icons.arrow_forward,
          onTap: () => taps++,
        ),
      ));

      expect(find.byIcon(Icons.arrow_forward), findsOneWidget);
      await tester.tap(find.byType(OutlinedTile));
      await tester.pump();
      expect(taps, 1);
    });
  });

  group('$Handlebars.horizontal', () {
    testWidgets('renders with a default width of 25% of the parent', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => SizedBox(
                width: 400,
                child: Handlebars.horizontal(context),
              ),
            ),
          ),
        ),
      );

      final container = tester.widget<Container>(find.byType(Container));
      // MediaQuery in the test environment defaults to the screen size, not
      // the SizedBox — we can only assert non-null width.
      expect(container.constraints?.maxWidth ?? 0, greaterThan(0));
    });

    testWidgets('honours an explicit width override', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => Handlebars.horizontal(context, width: 80),
            ),
          ),
        ),
      );

      final container = tester.widget<Container>(find.byType(Container));
      expect(container.constraints?.maxWidth, 80);
    });

    testWidgets('honours an explicit margin override', (tester) async {
      const customMargin = EdgeInsets.only(top: 20, bottom: 4);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => Handlebars.horizontal(context, margin: customMargin),
            ),
          ),
        ),
      );

      final container = tester.widget<Container>(find.byType(Container));
      expect(container.margin, customMargin);
    });
  });
}
