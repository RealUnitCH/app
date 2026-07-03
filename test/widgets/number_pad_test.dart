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

    testWidgets('biometric icon rendered only when both callback and icon are provided',
        (tester) async {
      await tester.pumpWidget(_host(
        NumberPad(onNumberPressed: (_) {}, onDeletePressed: () {}),
      ));
      expect(find.byIcon(Icons.fingerprint), findsNothing);

      await tester.pumpWidget(_host(
        NumberPad(
          onNumberPressed: (_) {},
          onDeletePressed: () {},
          onBiometricPressed: () {},
          biometricIcon: const Icon(Icons.fingerprint),
        ),
      ));
      expect(find.byIcon(Icons.fingerprint), findsOneWidget);
    });

    testWidgets('tapping the biometric button fires onBiometricPressed', (tester) async {
      var biometrics = 0;
      await tester.pumpWidget(_host(
        NumberPad(
          onNumberPressed: (_) {},
          onDeletePressed: () {},
          onBiometricPressed: () => biometrics++,
          biometricIcon: const Icon(Icons.fingerprint),
        ),
      ));

      await tester.tap(find.byIcon(Icons.fingerprint));
      await tester.pump();

      expect(biometrics, 1);
    });

    testWidgets('inputEnabled=false makes digits and delete inert', (tester) async {
      final pressed = <int>[];
      var deletes = 0;
      await tester.pumpWidget(_host(
        NumberPad(
          onNumberPressed: pressed.add,
          onDeletePressed: () => deletes++,
          inputEnabled: false,
        ),
      ));

      await tester.tap(find.text('1'));
      await tester.tap(find.text('0'));
      await tester.tap(find.byIcon(Icons.arrow_back_ios_new));
      await tester.pump();

      expect(pressed, isEmpty);
      expect(deletes, 0);
    });

    testWidgets('biometric button stays active while inputEnabled is false', (tester) async {
      var biometrics = 0;
      await tester.pumpWidget(_host(
        NumberPad(
          onNumberPressed: (_) {},
          onDeletePressed: () {},
          inputEnabled: false,
          onBiometricPressed: () => biometrics++,
          biometricIcon: const Icon(Icons.fingerprint),
        ),
      ));

      await tester.tap(find.byIcon(Icons.fingerprint));
      await tester.pump();

      expect(biometrics, 1);
    });
  });
}
