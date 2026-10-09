import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:realunit_wallet/widgets/text_substring_highlighting.dart';

void main() {
  group('$TextSubstringHighlighting', () {
    testWidgets('returns a plain Text when the substring is not found', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: TextSubstringHighlighting(
              text: 'plain text',
              highlightedText: 'missing',
            ),
          ),
        ),
      );

      // Fallback path: a Text widget (which internally renders a RichText
      // with a single non-children TextSpan), not a directly-built RichText.
      expect(find.byType(Text), findsOneWidget);
      expect(find.text('plain text'), findsOneWidget);

      // The internal RichText has a TextSpan with no children list — that's
      // the marker for the fallback vs the highlighted branch.
      final rich = tester.widget<RichText>(find.byType(RichText));
      expect((rich.text as TextSpan).children, isNull);
    });

    testWidgets('returns a RichText with three spans when the substring is found',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: TextSubstringHighlighting(
              text: 'I accept the Terms here',
              highlightedText: 'Terms',
            ),
          ),
        ),
      );

      final rich = tester.widget<RichText>(find.byType(RichText));
      final root = rich.text as TextSpan;
      final children = root.children!;

      expect(children, hasLength(3));
      expect((children[0] as TextSpan).text, 'I accept the ');
      expect((children[1] as TextSpan).text, 'Terms');
      expect((children[2] as TextSpan).text, ' here');
    });

    testWidgets('highlighted span inherits bold when no highlightedStyle is given',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: TextSubstringHighlighting(
              text: 'I accept the Terms here',
              highlightedText: 'Terms',
              style: TextStyle(fontSize: 14),
            ),
          ),
        ),
      );

      final rich = tester.widget<RichText>(find.byType(RichText));
      final highlightedSpan = (rich.text as TextSpan).children![1] as TextSpan;

      // Default highlightedStyle is base.copyWith(fontWeight: .bold).
      expect(highlightedSpan.style!.fontWeight, FontWeight.bold);
      // The base font size is preserved via copyWith.
      expect(highlightedSpan.style!.fontSize, 14);
    });

    testWidgets('a custom highlightedStyle replaces the default bold', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: TextSubstringHighlighting(
              text: 'I accept the Terms here',
              highlightedText: 'Terms',
              highlightedStyle: TextStyle(color: Colors.red),
            ),
          ),
        ),
      );

      final rich = tester.widget<RichText>(find.byType(RichText));
      final highlightedSpan = (rich.text as TextSpan).children![1] as TextSpan;

      expect(highlightedSpan.style!.color, Colors.red);
      // The custom style does NOT inherit the default bold weight.
      expect(highlightedSpan.style!.fontWeight, isNull);
    });

    testWidgets('attaches a tap recognizer when onHighlightedTap is given',
        (tester) async {
      var taps = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TextSubstringHighlighting(
              text: 'I accept the Terms here',
              highlightedText: 'Terms',
              onHighlightedTap: () => taps++,
            ),
          ),
        ),
      );

      final rich = tester.widget<RichText>(find.byType(RichText));
      final highlightedSpan = (rich.text as TextSpan).children![1] as TextSpan;

      expect(highlightedSpan.recognizer, isA<TapGestureRecognizer>());
      // Fire the recognizer manually since hit-testing a TextSpan in a widget
      // test is fiddly — the gestureRecognizer itself is what would receive
      // the gesture in production.
      (highlightedSpan.recognizer! as TapGestureRecognizer).onTap!();
      expect(taps, 1);
    });

    testWidgets('omits the tap recognizer when no callback is provided',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: TextSubstringHighlighting(
              text: 'I accept the Terms here',
              highlightedText: 'Terms',
            ),
          ),
        ),
      );

      final rich = tester.widget<RichText>(find.byType(RichText));
      final highlightedSpan = (rich.text as TextSpan).children![1] as TextSpan;

      expect(highlightedSpan.recognizer, isNull);
    });

    testWidgets(
      'renders highlighted substring as Semantics(identifier:) when '
      'highlightedSemanticsId + onHighlightedTap are given',
      (tester) async {
        var taps = 0;
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: TextSubstringHighlighting(
                text: 'I accept the Terms here',
                highlightedText: 'Terms',
                highlightedSemanticsId: 'home-terms-link',
                onHighlightedTap: () => taps++,
              ),
            ),
          ),
        );

        // The highlighted chunk is now a WidgetSpan-hosted Semantics node,
        // not a TextSpan with a TapGestureRecognizer. Note: the inner
        // `Text('Terms')` widget also renders its own RichText, so we pick
        // the outer one (descendant of the TextSubstringHighlighting widget
        // with a children-bearing TextSpan).
        final richFinder = find.descendant(
          of: find.byType(TextSubstringHighlighting),
          matching: find.byType(RichText),
        );
        final RichText rich = tester
            .widgetList<RichText>(richFinder)
            .firstWhere((r) => (r.text as TextSpan).children != null);
        final children = (rich.text as TextSpan).children!;
        expect(children[1], isA<WidgetSpan>());

        // The WidgetSpan's child must be a Semantics with the expected
        // identifier (this is what Maestro's `tapOn: id:` matches against
        // via Flutter -> iOS accessibility bridge).
        final widgetSpan = children[1] as WidgetSpan;
        expect(widgetSpan.child, isA<Semantics>());
        final spanSemantics = widgetSpan.child as Semantics;
        expect(spanSemantics.properties.identifier, 'home-terms-link');
        expect(spanSemantics.properties.button, isTrue);

        // The wrapped GestureDetector still fires the callback.
        await tester.tap(find.text('Terms'));
        expect(taps, 1);
      },
    );

    testWidgets(
      'falls back to TextSpan + recognizer when highlightedSemanticsId is '
      'set but onHighlightedTap is null',
      (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: TextSubstringHighlighting(
                text: 'I accept the Terms here',
                highlightedText: 'Terms',
                highlightedSemanticsId: 'home-terms-link',
              ),
            ),
          ),
        );

        // Without a tap callback there's nothing meaningful to attach the
        // Semantics node to, so the original TextSpan path is used.
        final rich = tester.widget<RichText>(find.byType(RichText));
        final children = (rich.text as TextSpan).children!;
        expect(children[1], isA<TextSpan>());
        expect((children[1] as TextSpan).recognizer, isNull);
      },
    );
  });
}
