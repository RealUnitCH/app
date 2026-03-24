class SvgParser {
  /// Converts SVG with mm units to pixels for flutter_svg compatibility.
  /// 1mm ≈ 3.7795275591 pixels at 96 DPI.
  static String normalize(String svg) {
    const mmToPixel = 3.7795275591;
    return svg.replaceAllMapped(
      RegExp(r'(\d+\.?\d*)mm'),
      (match) {
        final mmValue = double.parse(match.group(1)!);
        final pxValue = (mmValue * mmToPixel).toStringAsFixed(2);
        return '${pxValue}px';
      },
    );
  }
}
