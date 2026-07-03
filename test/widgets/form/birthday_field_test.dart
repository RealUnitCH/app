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

    testWidgets('seeds only the parts the dropdowns offer for an out-of-range year', (
      tester,
    ) async {
      // The API accepts birthdays older than the now-140 floor of the year
      // dropdown. Seeding an unoffered year trips DropdownButtonFormField's
      // "exactly one item with value" assert and blanks the screen.
      await tester.pumpApp(
        _host(BirthdayField(controller: ValueNotifier<String?>('1850-05-15'))),
      );

      expect(tester.takeException(), isNull);
      expect(find.text('05'), findsOneWidget);
      expect(find.text('15'), findsOneWidget);
      expect(find.text('1850'), findsNothing);
    });

    testWidgets('offers years older than 99 within the now-140 window (#762)', (
      tester,
    ) async {
      // Before #762 the dropdown only spanned ages 18-99, so a 1920 birthday
      // fell outside the offered years and was silently dropped. The window
      // now runs now-140..now, so 1920 must be selectable.
      await tester.pumpApp(
        _host(BirthdayField(controller: ValueNotifier<String?>('1920-05-15'))),
      );

      expect(tester.takeException(), isNull);
      expect(find.text('1920'), findsOneWidget);
      expect(find.text('05'), findsOneWidget);
      expect(find.text('15'), findsOneWidget);
    });

    testWidgets('ignores malformed month/day parts outside the dropdown items', (
      tester,
    ) async {
      // Only the year guard was covered before. A malformed month (13) or day
      // (40) is not an offered item and must be dropped without asserting.
      await tester.pumpApp(
        _host(BirthdayField(controller: ValueNotifier<String?>('1990-13-40'))),
      );

      expect(tester.takeException(), isNull);
      expect(find.text('1990'), findsOneWidget);
      expect(find.text('13'), findsNothing);
      expect(find.text('40'), findsNothing);
    });

    testWidgets('validate() fails for an impossible calendar date', (tester) async {
      final formKey = GlobalKey<FormState>();
      final year = '${DateTime.now().year - 30}';
      await tester.pumpApp(
        _host(
          Form(
            key: formKey,
            child: BirthdayField(controller: ValueNotifier<String?>('$year-02-31')),
          ),
        ),
      );

      expect(formKey.currentState!.validate(), isFalse);
    });

    testWidgets('validate() passes for a valid calendar date', (tester) async {
      final formKey = GlobalKey<FormState>();
      final year = '${DateTime.now().year - 30}';
      await tester.pumpApp(
        _host(
          Form(
            key: formKey,
            child: BirthdayField(controller: ValueNotifier<String?>('$year-02-28')),
          ),
        ),
      );

      expect(formKey.currentState!.validate(), isTrue);
    });

    testWidgets('validate() fails for Feb 29 in a non-leap year', (tester) async {
      // 2003 is not a leap year: DateTime(2003, 2, 29) rolls over to March 1,
      // so the month no longer matches and the date is rejected.
      final formKey = GlobalKey<FormState>();
      await tester.pumpApp(
        _host(
          Form(
            key: formKey,
            child: BirthdayField(controller: ValueNotifier<String?>('2003-02-29')),
          ),
        ),
      );

      expect(formKey.currentState!.validate(), isFalse);
    });

    testWidgets('validate() passes for Feb 29 in a leap year', (tester) async {
      // 2004 is a leap year: DateTime(2004, 2, 29) stays in February.
      final formKey = GlobalKey<FormState>();
      await tester.pumpApp(
        _host(
          Form(
            key: formKey,
            child: BirthdayField(controller: ValueNotifier<String?>('2004-02-29')),
          ),
        ),
      );

      expect(formKey.currentState!.validate(), isTrue);
    });

    testWidgets('selecting day/month/year via the dropdowns writes the controller', (
      tester,
    ) async {
      final controller = ValueNotifier<String?>(null);
      final formKey = GlobalKey<FormState>();
      await tester.pumpApp(
        _host(
          Form(
            key: formKey,
            child: BirthdayField(controller: controller),
          ),
        ),
      );

      Future<void> select(int fieldIndex, String value) async {
        await tester.tap(find.byType(DropdownField<String>).at(fieldIndex));
        await tester.pumpAndSettle();
        // The menu builds its items lazily, so scroll the freshly-opened menu
        // (the last scrollable on screen) until the target item is rendered.
        // While a menu is open its value is unique to that menu.
        await tester.scrollUntilVisible(
          find.text(value),
          50.0,
          scrollable: find.byType(Scrollable).last,
        );
        await tester.pumpAndSettle();
        await tester.tap(find.text(value));
        await tester.pumpAndSettle();
      }

      await select(0, '31'); // day
      await select(1, '02'); // month
      await select(2, '2000'); // year

      // updateBirthday writes once all three parts are set.
      expect(controller.value, '2000-02-31');
      // 31 February is impossible, so the field validates as false.
      expect(formKey.currentState!.validate(), isFalse);
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
