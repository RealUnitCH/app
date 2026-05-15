import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:realunit_wallet/widgets/number_pad.dart';

Widget _host(Widget child) => MaterialApp(home: Scaffold(body: child));

void main() {
  group('$NumberPad', () {
    testWidgets('renders digit buttons 0-9 + delete', (tester) async {
      await tester.pumpWidget(_host(
        NumberPad(onNumberPressed: (_) {}, onDeletePressed: () {}),
      ));

      for (var d = 0; d <= 9; d++) {
        expect(find.text('$d'), findsOneWidget);
      }
      expect(find.byIcon(Icons.arrow_back_ios_new), findsOneWidget);
    });

    testWidgets('decimal button rendered only when onDecimalPressed is provided',
        (tester) async {
      await tester.pumpWidget(_host(
        NumberPad(onNumberPressed: (_) {}, onDeletePressed: () {}),
      ));
      expect(find.text('.'), findsNothing);

      await tester.pumpWidget(_host(
        NumberPad(
          onNumberPressed: (_) {},
          onDeletePressed: () {},
          onDecimalPressed: () {},
        ),
      ));
      expect(find.text('.'), findsOneWidget);
    });

    testWidgets('tapping a digit fires onNumberPressed with that digit',
        (tester) async {
      final pressed = <int>[];
      await tester.pumpWidget(_host(
        NumberPad(
          onNumberPressed: pressed.add,
          onDeletePressed: () {},
        ),
      ));

      await tester.tap(find.text('1'));
      await tester.tap(find.text('5'));
      await tester.tap(find.text('0'));
      await tester.pump();

      expect(pressed, [1, 5, 0]);
    });

    testWidgets('tapping delete fires onDeletePressed', (tester) async {
      var deletes = 0;
      await tester.pumpWidget(_host(
        NumberPad(
          onNumberPressed: (_) {},
          onDeletePressed: () => deletes++,
        ),
      ));

      await tester.tap(find.byIcon(Icons.arrow_back_ios_new));
      await tester.pump();

      expect(deletes, 1);
    });

    testWidgets('tapping the decimal fires onDecimalPressed when provided',
        (tester) async {
      var dots = 0;
      await tester.pumpWidget(_host(
        NumberPad(
          onNumberPressed: (_) {},
          onDeletePressed: () {},
          onDecimalPressed: () => dots++,
        ),
      ));

      await tester.tap(find.text('.'));
      await tester.pump();

      expect(dots, 1);
    });
  });
}
