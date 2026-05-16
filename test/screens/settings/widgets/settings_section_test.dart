import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:realunit_wallet/screens/settings/widgets/settings_section.dart';

Widget _host(Widget child) => MaterialApp(home: Scaffold(body: child));

void main() {
  group('$SettingsSections', () {
    testWidgets('renders one row per option with title + subtitle when given',
        (tester) async {
      await tester.pumpWidget(_host(
        SettingsSections(
          settings: [
            SettingOption(title: 'Language', subtitle: 'English', onTap: () {}),
            SettingOption(title: 'Currency', onTap: () {}),
          ],
        ),
      ));

      expect(find.text('Language'), findsOneWidget);
      expect(find.text('English'), findsOneWidget);
      expect(find.text('Currency'), findsOneWidget);
    });

    testWidgets('tap on an enabled option fires onTap', (tester) async {
      var taps = 0;
      await tester.pumpWidget(_host(
        SettingsSections(
          settings: [
            SettingOption(title: 'Language', onTap: () => taps++),
          ],
        ),
      ));

      await tester.tap(find.text('Language'));
      await tester.pump();

      expect(taps, 1);
    });

    testWidgets('disabled option (onTap == null): InkWell.onTap is null and Opacity is 0.5',
        (tester) async {
      await tester.pumpWidget(_host(
        const SettingsSections(
          settings: [
            SettingOption(title: 'Greyed out'),
          ],
        ),
      ));

      final inkWell = tester.widget<InkWell>(find.byType(InkWell));
      expect(inkWell.onTap, isNull);

      final opacity = tester.widget<Opacity>(find.byType(Opacity));
      expect(opacity.opacity, 0.5);
    });

    testWidgets('enabled option: InkWell.onTap is non-null and Opacity is 1.0',
        (tester) async {
      await tester.pumpWidget(_host(
        SettingsSections(
          settings: [
            SettingOption(title: 'Active', onTap: () {}),
          ],
        ),
      ));

      final inkWell = tester.widget<InkWell>(find.byType(InkWell));
      expect(inkWell.onTap, isNotNull);

      final opacity = tester.widget<Opacity>(find.byType(Opacity));
      expect(opacity.opacity, 1.0);
    });
  });
}
