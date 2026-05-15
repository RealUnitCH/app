import 'package:flutter_test/flutter_test.dart';
import 'package:realunit_wallet/packages/utils/svg_parser.dart';

void main() {
  group('$SvgParser', () {
    test('converts integer mm values to px at 96 DPI (≈3.7795 px/mm)', () {
      const svg = '<svg width="10mm" height="20mm"/>';

      final out = SvgParser.normalize(svg);

      // 10mm → 37.7952755... → rounded to 2 dp = 37.80; 20mm → 75.59.
      expect(out, '<svg width="37.80px" height="75.59px"/>');
    });

    test('converts decimal mm values', () {
      const svg = '<rect width="1.5mm"/>';

      final out = SvgParser.normalize(svg);

      // 1.5 × 3.7795275591 = 5.66929... → 5.67.
      expect(out, '<rect width="5.67px"/>');
    });

    test('leaves non-mm units untouched', () {
      const svg = '<svg width="10px" height="100%"/>';

      final out = SvgParser.normalize(svg);

      expect(out, svg);
    });

    test('replaces every mm occurrence in the string', () {
      const svg = '<svg width="1mm"><path d="M2mm 3mm"/></svg>';

      final out = SvgParser.normalize(svg);

      // No 'mm' substring should remain.
      expect(out.contains('mm'), isFalse);
    });

    test('preserves the rest of the SVG markup verbatim', () {
      const svg = '<svg xmlns="http://www.w3.org/2000/svg" width="5mm"/>';

      final out = SvgParser.normalize(svg);

      expect(out.contains('xmlns="http://www.w3.org/2000/svg"'), isTrue);
      expect(out.contains('width="18.90px"'), isTrue);
    });
  });
}
