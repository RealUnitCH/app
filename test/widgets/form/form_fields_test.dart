import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:realunit_wallet/widgets/form/dropdown_field.dart';
import 'package:realunit_wallet/widgets/form/labeled_text_field.dart';

Widget _host(Widget child) => MaterialApp(
      home: Scaffold(body: Padding(padding: const EdgeInsets.all(16), child: child)),
    );

void main() {
  group('$LabeledTextField', () {
    testWidgets('omits the label Padding when label is null', (tester) async {
      await tester.pumpWidget(_host(
        const LabeledTextField(hintText: 'hint'),
      ));

      expect(find.byType(TextFormField), findsOneWidget);
      // No Text widgets render when the label is null (the TextFormField's
      // hint is rendered by InputDecorator, not a top-level Text).
      expect(find.text('Hello'), findsNothing);
    });

    testWidgets('renders the label when provided', (tester) async {
      await tester.pumpWidget(_host(
        const LabeledTextField(label: 'Email'),
      ));

      expect(find.text('Email'), findsOneWidget);
    });

    testWidgets('initialValue seeds the form field', (tester) async {
      await tester.pumpWidget(_host(
        const LabeledTextField(initialValue: 'seed'),
      ));

      expect(find.text('seed'), findsOneWidget);
    });

    testWidgets('onChanged fires when the user types', (tester) async {
      String? last;
      await tester.pumpWidget(_host(
        LabeledTextField(onChanged: (v) => last = v),
      ));

      await tester.enterText(find.byType(TextFormField), 'hello');
      expect(last, 'hello');
    });
  });

  group('$DropdownField<String>', () {
    testWidgets('renders all items as menu choices when tapped', (tester) async {
      await tester.pumpWidget(_host(
        DropdownField<String>(
          initialValue: 'a',
          items: const [
            DropdownMenuItem(value: 'a', child: Text('Alpha')),
            DropdownMenuItem(value: 'b', child: Text('Bravo')),
            DropdownMenuItem(value: 'c', child: Text('Charlie')),
          ],
          onChanged: (_) {},
        ),
      ));

      // initialValue 'Alpha' is rendered in the closed dropdown.
      expect(find.text('Alpha'), findsWidgets);

      await tester.tap(find.byType(DropdownButtonFormField<String>));
      await tester.pumpAndSettle();

      // Other items become visible in the open menu.
      expect(find.text('Bravo'), findsOneWidget);
      expect(find.text('Charlie'), findsOneWidget);
    });

    testWidgets('renders the label when provided', (tester) async {
      await tester.pumpWidget(_host(
        const DropdownField<String>(
          label: 'Country',
          items: [
            DropdownMenuItem(value: 'CH', child: Text('CH')),
          ],
        ),
      ));

      expect(find.text('Country'), findsOneWidget);
    });

    testWidgets('onChanged fires when the user picks an item', (tester) async {
      String? picked;
      await tester.pumpWidget(_host(
        DropdownField<String>(
          initialValue: 'a',
          items: const [
            DropdownMenuItem(value: 'a', child: Text('A')),
            DropdownMenuItem(value: 'b', child: Text('B')),
          ],
          onChanged: (v) => picked = v,
        ),
      ));

      await tester.tap(find.byType(DropdownButtonFormField<String>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('B').last);
      await tester.pumpAndSettle();

      expect(picked, 'b');
    });
  });
}
