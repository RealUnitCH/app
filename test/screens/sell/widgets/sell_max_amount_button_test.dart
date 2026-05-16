import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:realunit_wallet/screens/sell/widgets/sell_max_amount_button.dart';

import '../../../helper/helper.dart';

void main() {
  group('$SellMaxAmountButton', () {
    testWidgets('renders the localised label in upper-case', (tester) async {
      await tester.pumpApp(Scaffold(body: SellMaxAmountButton(onTap: () {})));

      // The translated label is `S.of(context).max.toUpperCase()`. We can't
      // pin the exact translation (locale-dependent), but it must be
      // upper-case — pin via a regex check on the rendered Text.
      final text = tester.widget<Text>(find.byType(Text));
      expect(text.data, isNotNull);
      expect(text.data, equals(text.data!.toUpperCase()));
    });

    testWidgets('tapping fires onTap once', (tester) async {
      var taps = 0;
      await tester.pumpApp(Scaffold(body: SellMaxAmountButton(onTap: () => taps++)));

      await tester.tap(find.byType(SellMaxAmountButton));
      await tester.pump();

      expect(taps, 1);
    });

    testWidgets('uses an InkWell as the tap surface', (tester) async {
      await tester.pumpApp(Scaffold(body: SellMaxAmountButton(onTap: () {})));

      expect(find.byType(InkWell), findsOneWidget);
    });
  });
}
