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

    // Impossible dates (31.02., 29.02. outside leap years) roll into the next
    // month, which validate() rejects.
    final year30 = '${DateTime.now().year - 30}';
    for (final (seed, expectedValid) in [
      ('$year30-02-31', false),
      ('$year30-02-28', true),
      ('2003-02-29', false),
      ('2004-02-29', true),
    ]) {
      testWidgets('validate() is $expectedValid for $seed', (tester) async {
        final formKey = GlobalKey<FormState>();
        await tester.pumpApp(
          _host(
            Form(
              key: formKey,
              child: BirthdayField(controller: ValueNotifier<String?>(seed)),
            ),
          ),
        );

        expect(formKey.currentState!.validate(), expectedValid);
      });
    }

    testWidgets('validate() fails for a birthday in the future', (tester) async {
      final formKey = GlobalKey<FormState>();
      final tomorrow = DateTime.now().add(const Duration(days: 1));
      final seed =
          '${tomorrow.year}-'
          '${'${tomorrow.month}'.padLeft(2, '0')}-'
          '${'${tomorrow.day}'.padLeft(2, '0')}';
      await tester.pumpApp(
        _host(
          Form(
            key: formKey,
            child: BirthdayField(controller: ValueNotifier<String?>(seed)),
          ),
        ),
      );

      // Rejected via isValidBirthdate, or on Dec 31 (rolled year not offered,
      // seed guard nulls it) via the null check — false either way.
      expect(formKey.currentState!.validate(), isFalse);
    });

    testWidgets('validate() passes for today', (tester) async {
      final formKey = GlobalKey<FormState>();
      final now = DateTime.now();
      final seed = '${now.year}-${'${now.month}'.padLeft(2, '0')}-${'${now.day}'.padLeft(2, '0')}';
      await tester.pumpApp(
        _host(
          Form(
            key: formKey,
            child: BirthdayField(controller: ValueNotifier<String?>(seed)),
          ),
        ),
      );

      expect(formKey.currentState!.validate(), isTrue);
    });

    testWidgets('selecting day/month/year via the dropdowns writes the controller', (
      tester,
    ) async {
      final controller = ValueNotifier<String?>(null);
      await tester.pumpApp(_host(BirthdayField(controller: controller)));

      Future<void> select(int fieldIndex, String value) async {
        await tester.tap(find.byType(DropdownField<String>).at(fieldIndex));
        await tester.pumpAndSettle();
        // A closed sibling dropdown can show the same label as an item in the
        // open menu (day '05' while picking month '05'), so match only inside
        // the open menu's scrollable, which renders last in the tree.
        final item = find.descendant(
          of: find.byType(Scrollable).last,
          matching: find.text(value),
        );
        // The menu builds its items lazily, so scroll the freshly-opened menu
        // (the last scrollable on screen) until the target item is rendered.
        await tester.scrollUntilVisible(
          item,
          50.0,
          scrollable: find.byType(Scrollable).last,
        );
        await tester.pumpAndSettle();
        await tester.tap(item);
        await tester.pumpAndSettle();
      }

      await select(0, '05');
      await select(1, '05');
      await select(2, '2000');

      // updateBirthday writes once all three parts are set.
      expect(controller.value, '2000-05-05');
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
