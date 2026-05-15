import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:realunit_wallet/widgets/mnemonic_field.dart';

const _seed = [
  'abandon', 'ability', 'about', 'above', 'absent', 'absorb',
  'abstract', 'absurd', 'abuse', 'access', 'accident', 'account',
];

Widget _host(Widget child) => MaterialApp(home: Scaffold(body: child));

void main() {
  group('$MnemonicReadOnlyField', () {
    testWidgets('renders all 12 seed words exactly once each', (tester) async {
      await tester.pumpWidget(_host(
        MnemonicReadOnlyField(seedWords: _seed),
      ));

      for (final word in _seed) {
        expect(find.text(word), findsOneWidget);
      }
    });

    test('asserts that exactly 12 seed words are passed', () {
      expect(
        () => MnemonicReadOnlyField(seedWords: ['only', 'two']),
        throwsA(isA<AssertionError>()),
      );
    });

    testWidgets('renders 12 cell Text widgets (one per word)', (tester) async {
      await tester.pumpWidget(_host(
        MnemonicReadOnlyField(seedWords: _seed),
      ));

      // Every cell carries a Text widget. The base also wraps the layout in
      // a Container with a border, no extra Text elsewhere.
      expect(find.byType(Text), findsNWidgets(12));
    });
  });
}
