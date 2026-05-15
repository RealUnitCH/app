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
      (highlightedSpan.recognizer as TapGestureRecognizer).onTap!();
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
  });
}
