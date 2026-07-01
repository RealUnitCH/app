import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:realunit_wallet/widgets/form/birthday_field.dart';
import 'package:realunit_wallet/widgets/form/dropdown_field.dart';

import '../../helper/pump_app.dart';

Widget _host(Widget child) => Scaffold(
  body: SingleChildScrollView(
    child: Padding(padding: const EdgeInsets.all(16), child: child),
  ),
);

void main() {
  group('$BirthdayField', () {
    testWidgets('renders three dropdowns for an unset birthday', (tester) async {
      await tester.pumpApp(
        _host(BirthdayField(controller: ValueNotifier<String?>(null))),
      );

      expect(find.byType(DropdownField<String>), findsNWidgets(3));
    });

    testWidgets('seeds day/month/year from a "yyyy-MM-dd" birthday', (tester) async {
      final year = '${DateTime.now().year - 30}';
      await tester.pumpApp(
        _host(BirthdayField(controller: ValueNotifier<String?>('$year-05-15'))),
      );

      expect(find.text(year), findsOneWidget);
      expect(find.text('05'), findsOneWidget);
      expect(find.text('15'), findsOneWidget);
    });

    testWidgets('does not throw when the birthday has no separators', (tester) async {
      // The backend can return a present-but-empty birthday (""), whose
      // `split('-')` yields a single element. Reading `parts[1]`/`parts[2]`
      // used to throw RangeError during initState and blank the screen.
      await tester.pumpApp(
        _host(BirthdayField(controller: ValueNotifier<String?>(''))),
      );

      expect(tester.takeException(), isNull);
      expect(find.byType(DropdownField<String>), findsNWidgets(3));
    });
  });
}
