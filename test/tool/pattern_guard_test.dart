// Unit test for the high-pattern guard (tool/lints/pattern_guard.dart).
// Verifies each rule fires on a known-bad snippet, stays silent on a
// known-good one, and that `// realunit-lint:ignore <rule>` suppresses a hit.
@TestOn('vm')
library;

import 'package:flutter_test/flutter_test.dart';

import '../../tool/lints/pattern_guard.dart';

List<String> _rules(String path, String src) =>
    scanDartSource(path, src).map((f) => f.rule).toList();

void main() {
  group('hardcoded_swiss_tax_residence', () {
    test('fires on a boolean literal', () {
      final hits = _rules('lib/x.dart', '''
void f() {
  register(swissTaxResidence: true);
}
''');
      expect(hits, contains('hardcoded_swiss_tax_residence'));
    });

    test('silent when passed a value', () {
      final hits = _rules('lib/x.dart', '''
void f(bool resident) {
  register(swissTaxResidence: resident);
}
''');
      expect(hits, isNot(contains('hardcoded_swiss_tax_residence')));
    });
  });

  group('fixed_index_address_substring', () {
    test('fires on two constant indices with end >= 6', () {
      final hits = _rules('lib/x.dart', 'void f(String a) => a.substring(0, 6);');
      expect(hits, contains('fixed_index_address_substring'));
    });

    test('silent on a trivial peek (end < 6)', () {
      final hits = _rules('lib/x.dart', 'void f(String a) => a.substring(0, 1);');
      expect(hits, isNot(contains('fixed_index_address_substring')));
    });

    test('silent on a single dynamic index', () {
      final hits = _rules('lib/x.dart', 'void f(String a) => a.substring(2);');
      expect(hits, isNot(contains('fixed_index_address_substring')));
    });
  });

  group('cross_flow_brokerbot_endpoint', () {
    test('fires when a sell file calls a buy endpoint', () {
      final hits = _rules(
        'lib/screens/sell/cubits/sell_converter_cubit.dart',
        "void f(s) => s.getBuyPrice('1', c);",
      );
      expect(hits, contains('cross_flow_brokerbot_endpoint'));
    });

    test('fires when a buy file calls a sell endpoint', () {
      final hits = _rules(
        'lib/screens/buy/cubits/buy_converter_cubit.dart',
        "void f(s) => s.getSellPrice('1', c);",
      );
      expect(hits, contains('cross_flow_brokerbot_endpoint'));
    });

    test('silent when a sell file calls a sell endpoint', () {
      final hits = _rules(
        'lib/screens/sell/cubits/sell_converter_cubit.dart',
        "void f(s) => s.getSellPrice('1', c);",
      );
      expect(hits, isNot(contains('cross_flow_brokerbot_endpoint')));
    });
  });

  group('suppression', () {
    test('// realunit-lint:ignore on the line above silences the hit', () {
      final hits = _rules('lib/x.dart', '''
void f() {
  // realunit-lint:ignore hardcoded_swiss_tax_residence — test
  register(swissTaxResidence: true);
}
''');
      expect(hits, isEmpty);
    });

    test('ignore for a different rule does not silence', () {
      final hits = _rules('lib/x.dart', '''
void f() {
  // realunit-lint:ignore fixed_index_address_substring — wrong rule
  register(swissTaxResidence: true);
}
''');
      expect(hits, contains('hardcoded_swiss_tax_residence'));
    });
  });
}
