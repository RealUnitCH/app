import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:realunit_wallet/widgets/text_link_span.dart';

void main() {
  group('$TextLinkSpan.link', () {
    testWidgets('returns a TextSpan carrying the text and a TapGestureRecognizer',
        (tester) async {
      late TextSpan span;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                span = TextLinkSpan.link(
                  context,
                  text: 'click me',
                  uri: Uri.parse('https://example.com'),
                );
                return Text.rich(span);
              },
            ),
          ),
        ),
      );

      expect(span.text, 'click me');
      expect(span.recognizer, isA<TapGestureRecognizer>());
    });

    testWidgets('defaults to an underlined style when no style is given',
        (tester) async {
      late TextSpan span;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                span = TextLinkSpan.link(
                  context,
                  text: 'click me',
                  uri: Uri.parse('https://example.com'),
                );
                return Text.rich(span);
              },
            ),
          ),
        ),
      );

      expect(span.style!.decoration, TextDecoration.underline);
    });

    testWidgets('honours a custom style override', (tester) async {
      const customStyle = TextStyle(color: Colors.red, fontSize: 18);
      late TextSpan span;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                span = TextLinkSpan.link(
                  context,
                  text: 'click me',
                  uri: Uri.parse('https://example.com'),
                  style: customStyle,
                );
                return Text.rich(span);
              },
            ),
          ),
        ),
      );

      expect(span.style, customStyle);
      // No default underline when a custom style is given.
      expect(span.style!.decoration, isNull);
    });
  });
}
