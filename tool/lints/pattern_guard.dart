// High-pattern guard — a lightweight static check for the three recurring
// HIGH-severity defect shapes the Big Brother audit (#657) surfaced and that
// PR #663 named as `custom_lint` follow-ups. `custom_lint` itself cannot be
// added today: its current release pins `analyzer: ^8`, while this repo
// overrides `analyzer: ^10` for the strict-inference gate, so the two cannot
// co-resolve. This guard reaches the same goal with the `analyzer` package the
// repo already depends on — purely syntactic (`parseFile`, no element model),
// so it stays fast and version-tolerant.
//
// Run:   dart run tool/lints/pattern_guard.dart
// CI:    the `High-Pattern Guard` job in .github/workflows/pull-request.yaml
//        fails the build on any non-allowlisted hit.
//
// Suppressing a site (use sparingly, always with a reason on the same line or
// the line directly above):
//   // realunit-lint:ignore <rule-id> — <reason>
//
// Rule ids:
//   hardcoded_swiss_tax_residence     a `swissTaxResidence:` argument passed a
//                                     `true`/`false` literal instead of a value
//                                     derived from the user's actual residence.
//   fixed_index_address_substring     `.substring(<int>, <int>)` with two
//                                     constant indices — assumes a fixed string
//                                     length and throws RangeError on a shorter
//                                     one (the audit's qr_address_widget crash).
//   cross_flow_brokerbot_endpoint     a sell-flow file calling a buy-price/-
//                                     shares brokerbot method (or vice versa).

import 'dart:io';

import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/source/line_info.dart';

class Finding {
  Finding(this.rule, this.path, this.line, this.message);
  final String rule;
  final String path;
  final int line;
  final String message;
}

const _buyMethods = {'getBuyPrice', 'getBuyShares'};
const _sellMethods = {'getSellPrice', 'getSellShares'};

/// Scans a single Dart source for the three high-pattern violations, honouring
/// `// realunit-lint:ignore <rule-id>` markers. `path` drives the buy/sell flow
/// heuristic (rule C). Exposed for the unit test in
/// `test/tool/pattern_guard_test.dart`.
List<Finding> scanDartSource(String path, String content) {
  final result = parseString(content: content, path: path, throwIfDiagnostics: false);
  final visitor = _PatternVisitor(path, result.unit.lineInfo, content.split('\n'));
  result.unit.accept(visitor);
  return visitor.findings;
}

void main() {
  final root = Directory('lib');
  if (!root.existsSync()) {
    stderr.writeln('pattern_guard: run from the repo root (no lib/ here)');
    exit(2);
  }

  final findings = <Finding>[];
  final files = root
      .listSync(recursive: true)
      .whereType<File>()
      .where((f) => f.path.endsWith('.dart'))
      // Generated code is tool output, not developer code.
      .where((f) => !f.path.endsWith('.g.dart'))
      .where((f) => !f.path.startsWith('lib/generated/'))
      .toList()
    ..sort((a, b) => a.path.compareTo(b.path));

  for (final file in files) {
    findings.addAll(scanDartSource(file.path, file.readAsStringSync()));
  }

  if (findings.isEmpty) {
    stdout.writeln('pattern_guard: OK — no high-pattern violations in lib/.');
    return;
  }

  findings.sort((a, b) {
    final p = a.path.compareTo(b.path);
    return p != 0 ? p : a.line.compareTo(b.line);
  });
  for (final f in findings) {
    stdout.writeln('${f.path}:${f.line} • ${f.rule} • ${f.message}');
  }
  stderr.writeln('\npattern_guard: ${findings.length} violation(s). '
      'Fix them, or add `// realunit-lint:ignore <rule-id> — <reason>`.');
  exit(1);
}

class _PatternVisitor extends RecursiveAstVisitor<void> {
  _PatternVisitor(this.path, this.lineInfo, this.lines);

  final String path;
  final LineInfo lineInfo;
  final List<String> lines;
  final List<Finding> findings = [];

  bool get _isSellFile => path.contains('/sell/') || path.contains('/sell_');
  bool get _isBuyFile =>
      (path.contains('/buy/') || path.contains('/buy_')) && !_isSellFile;

  int _lineOf(int offset) => lineInfo.getLocation(offset).lineNumber;

  // A hit is suppressed by a `// realunit-lint:ignore <rule-id> — <reason>`
  // marker on the hit line itself or anywhere in the contiguous block of
  // comment lines directly above it (multi-line reasons are fine).
  bool _suppressed(int line, String rule) {
    bool has(String s) =>
        s.contains('realunit-lint:ignore') &&
        (s.contains(rule) || s.contains('realunit-lint:ignore-all'));
    if (line >= 1 && line <= lines.length && has(lines[line - 1])) return true;
    var i = line - 1; // index of the line above the hit (0-based: line-2 + 1)
    while (i >= 1 && lines[i - 1].trimLeft().startsWith('//')) {
      if (has(lines[i - 1])) return true;
      i--;
    }
    return false;
  }

  void _report(String rule, int offset, String message) {
    final line = _lineOf(offset);
    if (_suppressed(line, rule)) return;
    findings.add(Finding(rule, path, line, message));
  }

  @override
  void visitNamedExpression(NamedExpression node) {
    if (node.name.label.name == 'swissTaxResidence' &&
        node.expression is BooleanLiteral) {
      _report('hardcoded_swiss_tax_residence', node.offset,
          'swissTaxResidence passed a boolean literal; derive it from the '
          "user's residence instead of hardcoding.");
    }
    super.visitNamedExpression(node);
  }

  @override
  void visitMethodInvocation(MethodInvocation node) {
    final name = node.methodName.name;

    // Rule B: fixed-index address substring — both indices constant AND the
    // end index is >= 6, i.e. the call assumes a meaningfully long string
    // (an address/hash/id). A trivial peek like `substring(0, 1)` is below the
    // threshold and not flagged.
    if (name == 'substring') {
      final args = node.argumentList.arguments;
      if (args.length >= 2 &&
          args[0] is IntegerLiteral &&
          args[1] is IntegerLiteral &&
          ((args[1] as IntegerLiteral).value ?? 0) >= 6) {
        _report('fixed_index_address_substring', node.methodName.offset,
            'substring() with two constant indices assumes a fixed length; '
            'guard the length or compute indices to avoid RangeError.');
      }
    }

    // Rule C: cross-flow brokerbot endpoint.
    if (_isSellFile && _buyMethods.contains(name)) {
      _report('cross_flow_brokerbot_endpoint', node.methodName.offset,
          'sell-flow file calls $name (a buy-side brokerbot endpoint).');
    } else if (_isBuyFile && _sellMethods.contains(name)) {
      _report('cross_flow_brokerbot_endpoint', node.methodName.offset,
          'buy-flow file calls $name (a sell-side brokerbot endpoint).');
    }

    super.visitMethodInvocation(node);
  }
}
