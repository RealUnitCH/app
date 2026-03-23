import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

/// Enables a part of the String `text` to be differently styled.
class TextSubstringHighlighting extends StatelessWidget {
  final String text;
  final String highlightedText;
  final TextStyle? style;
  final TextStyle? highlightedStyle;
  final TextAlign textAlign;
  final int? maxLines;
  final TextOverflow overflow;
  final VoidCallback? onHighlightedTap;

  const TextSubstringHighlighting({
    super.key,
    required this.text,
    required this.highlightedText,
    this.style,
    this.highlightedStyle,
    this.textAlign = .start,
    this.maxLines,
    this.overflow = .visible,
    this.onHighlightedTap,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveStyle = style ?? DefaultTextStyle.of(context).style;
    final effectiveHighlightedStyle =
        highlightedStyle ?? effectiveStyle.copyWith(fontWeight: .bold);

    final startIndex = text.indexOf(highlightedText);

    // just return plain text if substring not found.
    if (startIndex == -1) {
      return Text(
        text,
        style: effectiveStyle,
        textAlign: textAlign,
        maxLines: maxLines,
        overflow: overflow,
      );
    }

    final before = text.substring(0, startIndex);
    final after = text.substring(startIndex + highlightedText.length);

    return RichText(
      textAlign: textAlign,
      maxLines: maxLines,
      overflow: overflow,
      text: TextSpan(
        style: effectiveStyle,
        children: [
          TextSpan(text: before),
          TextSpan(
            text: highlightedText,
            style: effectiveHighlightedStyle,
            recognizer: onHighlightedTap != null
                ? (TapGestureRecognizer()..onTap = onHighlightedTap)
                : null,
          ),
          TextSpan(text: after),
        ],
      ),
    );
  }
}
