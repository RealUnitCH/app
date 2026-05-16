import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:realunit_wallet/screens/dashboard/widgets/time_period_selection_button.dart';
import 'package:realunit_wallet/styles/colors.dart';

Widget _host(Widget child) => MaterialApp(home: Scaffold(body: child));

void main() {
  group('$TimePeriodSelectionButton', () {
    testWidgets('renders the label', (tester) async {
      await tester.pumpWidget(_host(
        const TimePeriodSelectionButton('1W'),
      ));

      expect(find.text('1W'), findsOneWidget);
    });

    testWidgets('isSelected=false: label is neutral-400, bottom border is transparent',
        (tester) async {
      await tester.pumpWidget(_host(
        const TimePeriodSelectionButton('1W'),
      ));

      final text = tester.widget<Text>(find.text('1W'));
      expect(text.style!.color, RealUnitColors.neutral400);

      final container = tester.widget<Container>(find.byType(Container));
      final decoration = container.decoration! as BoxDecoration;
      final borderColor = decoration.border!.bottom.color;
      expect(borderColor, Colors.transparent);
    });

    testWidgets('isSelected=true: label is blue, bottom border is blue',
        (tester) async {
      await tester.pumpWidget(_host(
        const TimePeriodSelectionButton('1W', isSelected: true),
      ));

      final text = tester.widget<Text>(find.text('1W'));
      expect(text.style!.color, RealUnitColors.realUnitBlue);

      final container = tester.widget<Container>(find.byType(Container));
      final decoration = container.decoration! as BoxDecoration;
      final borderColor = decoration.border!.bottom.color;
      expect(borderColor, RealUnitColors.realUnitBlue);
    });

    testWidgets('tap fires onTap', (tester) async {
      var taps = 0;
      await tester.pumpWidget(_host(
        TimePeriodSelectionButton('1W', onTap: () => taps++),
      ));

      await tester.tap(find.byType(TimePeriodSelectionButton));
      await tester.pump();

      expect(taps, 1);
    });
  });
}
