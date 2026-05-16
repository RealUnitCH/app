import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:realunit_wallet/widgets/date_picker_field.dart';

Widget _host(Widget child) => MaterialApp(home: Scaffold(body: child));

void main() {
  final today = DateTime(2026, 5, 16);
  final firstDate = DateTime(2020, 1, 1);
  final lastDate = DateTime(2030, 12, 31);

  group('$DatePickerField', () {
    testWidgets('omits the label Padding when label is null', (tester) async {
      await tester.pumpWidget(_host(
        DatePickerField(
          initialDate: today,
          firstDate: firstDate,
          lastDate: lastDate,
        ),
      ));

      // No 'X' label rendered — only the dd.MM.yyyy date.
      expect(find.text('Birthday'), findsNothing);
      // dd.MM.yyyy → '16.05.2026'.
      expect(find.text('16.05.2026'), findsOneWidget);
    });

    testWidgets('renders the label when provided', (tester) async {
      await tester.pumpWidget(_host(
        DatePickerField(
          label: 'Birthday',
          initialDate: today,
          firstDate: firstDate,
          lastDate: lastDate,
        ),
      ));

      expect(find.text('Birthday'), findsOneWidget);
    });

    testWidgets('renders the date in dd.MM.yyyy format', (tester) async {
      await tester.pumpWidget(_host(
        DatePickerField(
          initialDate: DateTime(2026, 3, 5),
          firstDate: firstDate,
          lastDate: lastDate,
        ),
      ));

      expect(find.text('05.03.2026'), findsOneWidget);
    });

    testWidgets('renders the calendar icon', (tester) async {
      await tester.pumpWidget(_host(
        DatePickerField(
          initialDate: today,
          firstDate: firstDate,
          lastDate: lastDate,
        ),
      ));

      expect(find.byIcon(Icons.calendar_today_outlined), findsOneWidget);
    });
  });
}
