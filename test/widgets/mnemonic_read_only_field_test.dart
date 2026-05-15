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

    testWidgets('lays out the words in two columns (left col holds words 1-6)',
        (tester) async {
      await tester.pumpWidget(_host(
        MnemonicReadOnlyField(seedWords: _seed),
      ));

      // Indexing inside _MnemonicFieldBase is `rowIndex + colIndex * rows`
      // (rows=6, cols=2), so the first 6 words live in the left column.
      // Pinning two adjacent words in the left column proves the column-first
      // layout is in effect.
      final firstWord = tester.getTopLeft(find.text('abandon'));
      final secondWord = tester.getTopLeft(find.text('ability'));
      // abandon (index 0) is at row 0, ability (index 1) is at row 1 in
      // the same column → same x, larger y.
      expect(secondWord.dx, firstWord.dx);
      expect(secondWord.dy, greaterThan(firstWord.dy));
    });
  });
}
