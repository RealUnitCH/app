// Unit tests for the high-pattern guard (tool/lints/pattern_guard.dart).
// Verifies its CI/A38 wiring, each rule's bad/good cases, and suppression.
@TestOn('vm')
library;

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../../tool/lints/pattern_guard.dart';

List<String> _rules(String path, String src) =>
    scanDartSource(path, src).map((f) => f.rule).toList();

void main() {
  test('Analyze job runs the fatal High-Pattern Guard after code generation', () {
    final workflow = File('.github/workflows/pull-request.yaml').readAsStringSync();
    final analyzeStart = workflow.indexOf('  analyze:\n');
    final buildStart = workflow.indexOf('\n  build:\n', analyzeStart);

    expect(analyzeStart, greaterThanOrEqualTo(0));
    expect(buildStart, greaterThan(analyzeStart));

    final analyzeJob = workflow.substring(analyzeStart, buildStart);
    final codeGeneration = analyzeJob.indexOf(
      '- run: flutter pub run build_runner build',
    );
    final guard = analyzeJob.indexOf('''- name: High-Pattern Guard
        run: dart run tool/lints/pattern_guard.dart''');
    final flutterAnalyze = analyzeJob.indexOf(
      '- run: flutter analyze --fatal-warnings',
    );

    expect(codeGeneration, greaterThanOrEqualTo(0));
    expect(guard, greaterThan(codeGeneration));
    expect(flutterAnalyze, greaterThan(guard));
    expect(analyzeJob, isNot(contains('continue-on-error: true')));
  });

  test('Analyze & Test job runs the fatal High-Pattern Guard after code generation', () {
    final workflow = File('.github/workflows/pull-request.yaml').readAsStringSync();
    final buildStart = workflow.indexOf('  build:\n');
    final coverageFloorStart = workflow.indexOf('\n  coverage-floor:\n', buildStart);

    expect(buildStart, greaterThanOrEqualTo(0));
    expect(coverageFloorStart, greaterThan(buildStart));

    final buildJob = workflow.substring(buildStart, coverageFloorStart);
    final codeGeneration = buildJob.indexOf(
      '- run: flutter pub run build_runner build',
    );
    final guard = buildJob.indexOf('''- name: High-Pattern Guard
        run: dart run tool/lints/pattern_guard.dart''');
    final flutterAnalyze = buildJob.indexOf(
      '- run: flutter analyze --fatal-warnings',
    );

    expect(codeGeneration, greaterThanOrEqualTo(0));
    expect(guard, greaterThan(codeGeneration));
    expect(flutterAnalyze, greaterThan(guard));
    expect(buildJob, isNot(contains('continue-on-error: true')));
  });

  test('A38 Analyze job runs the High-Pattern Guard before flutter analyze', () {
    final config = jsonDecode(File('.github/a38.json').readAsStringSync())
        as Map<String, dynamic>;
    final jobs = config['jobs'] as List<dynamic>;
    final analyzeJob = jobs.cast<Map<String, dynamic>>().singleWhere(
      (job) => job['id'] == 'analyze',
    );
    final executor = analyzeJob['executor'] as Map<String, dynamic>;
    final executorConfig = executor['config'] as Map<String, dynamic>;
    final steps = (executorConfig['steps'] as List<dynamic>)
        .map((step) => (step as List<dynamic>).cast<String>())
        .toList();
    final commands = steps.map((step) => step.join(' ')).toList();

    final codeGeneration = commands.indexOf(
      'flutter pub run build_runner build',
    );
    final guard = commands.indexOf('dart run tool/lints/pattern_guard.dart');
    final flutterAnalyze = commands.indexOf(
      'flutter analyze --fatal-warnings',
    );

    expect(codeGeneration, greaterThanOrEqualTo(0));
    expect(guard, greaterThan(codeGeneration));
    expect(flutterAnalyze, greaterThan(guard));
  });

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
    test('fires on two integer-literal indices with end >= 6', () {
      final hits = _rules('lib/x.dart', 'void f(String a) => a.substring(0, 6);');
      expect(hits, contains('fixed_index_address_substring'));
    });

    test('does not evaluate constant expressions (literal shape only)', () {
      final hits = _rules(
        'lib/x.dart',
        'void f(String value) => value.substring(0, 5 + 5);',
      );
      expect(hits, isNot(contains('fixed_index_address_substring')));
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
    test('valid marker on the line above silences the hit', () {
      final hits = _rules('lib/x.dart', '''
void f() {
  // realunit-lint:ignore hardcoded_swiss_tax_residence — test
  register(swissTaxResidence: true);
}
''');
      expect(hits, isEmpty);
    });

    test('valid marker on the finding line silences the hit', () {
      final hits = _rules('lib/x.dart', '''
void f() {
  register(swissTaxResidence: true); // realunit-lint:ignore hardcoded_swiss_tax_residence — test
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

    test('partial rule id does not silence', () {
      final hits = _rules('lib/x.dart', '''
void f() {
  // realunit-lint:ignore hardcoded_swiss_tax_residence_extra — wrong rule
  register(swissTaxResidence: true);
}
''');
      expect(hits, contains('hardcoded_swiss_tax_residence'));
    });

    test('marker without a reason does not silence', () {
      final hits = _rules('lib/x.dart', '''
void f() {
  // realunit-lint:ignore hardcoded_swiss_tax_residence —
  register(swissTaxResidence: true);
}
''');
      expect(hits, contains('hardcoded_swiss_tax_residence'));
    });

    test('marker in a string literal does not silence', () {
      final hits = _rules('lib/x.dart', '''
void f() {
  register(swissTaxResidence: true, note: '// realunit-lint:ignore hardcoded_swiss_tax_residence — not a comment');
}
''');
      expect(hits, contains('hardcoded_swiss_tax_residence'));
    });

    test('ignore-all does not silence', () {
      final hits = _rules('lib/x.dart', '''
void f() {
  // realunit-lint:ignore-all — test
  register(swissTaxResidence: true);
}
''');
      expect(hits, contains('hardcoded_swiss_tax_residence'));
    });

    test('ASCII hyphen delimiter does not silence', () {
      final hits = _rules('lib/x.dart', '''
void f() {
  // realunit-lint:ignore hardcoded_swiss_tax_residence - test
  register(swissTaxResidence: true);
}
''');
      expect(hits, contains('hardcoded_swiss_tax_residence'));
    });
  });
}
