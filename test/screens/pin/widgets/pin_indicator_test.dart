import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:realunit_wallet/screens/pin/widgets/pin_indicator.dart';
import 'package:realunit_wallet/styles/colors.dart';

Widget _host(Widget child) => MaterialApp(home: Scaffold(body: child));

void main() {
  List<Container> dots(WidgetTester tester) =>
      tester.widgetList<Container>(find.byType(Container)).toList();

  group('$PinIndicator', () {
    testWidgets('renders exactly expectedPinLength circles', (tester) async {
      await tester.pumpWidget(_host(
        const PinIndicator(pinLength: 0, expectedPinLength: 6, wrongPin: false),
      ));

      expect(dots(tester), hasLength(6));
    });

    testWidgets('fills the first pinLength dots with the foreground color',
        (tester) async {
      await tester.pumpWidget(_host(
        const PinIndicator(pinLength: 3, expectedPinLength: 6, wrongPin: false),
      ));

      final fills = dots(tester)
          .map((c) => (c.decoration! as BoxDecoration).color)
          .toList();
      // First three filled (black), last three transparent.
      expect(fills.take(3), everyElement(RealUnitColors.realUnitBlack));
      expect(fills.skip(3), everyElement(Colors.transparent));
    });

    testWidgets('wrongPin: every border is the status red', (tester) async {
      await tester.pumpWidget(_host(
        const PinIndicator(pinLength: 2, expectedPinLength: 6, wrongPin: true),
      ));

      final borderColors = dots(tester)
          .map((c) => (c.decoration! as BoxDecoration).border!.top.color)
          .toList();

      expect(borderColors, everyElement(RealUnitColors.status.red600));
    });

    testWidgets('wrongPin=false: every border is the black foreground',
        (tester) async {
      await tester.pumpWidget(_host(
        const PinIndicator(pinLength: 0, expectedPinLength: 6, wrongPin: false),
      ));

      final borderColors = dots(tester)
          .map((c) => (c.decoration! as BoxDecoration).border!.top.color)
          .toList();

      expect(borderColors, everyElement(RealUnitColors.realUnitBlack));
    });

    testWidgets('fully entered pin fills all dots', (tester) async {
      await tester.pumpWidget(_host(
        const PinIndicator(pinLength: 6, expectedPinLength: 6, wrongPin: false),
      ));

      final fills = dots(tester)
          .map((c) => (c.decoration! as BoxDecoration).color)
          .toList();
      expect(fills, everyElement(RealUnitColors.realUnitBlack));
    });
  });
}
