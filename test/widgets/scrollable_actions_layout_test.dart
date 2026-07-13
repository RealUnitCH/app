import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:realunit_wallet/widgets/scrollable_actions_layout.dart';

import '../helper/helper.dart';

void main() {
  group('$ScrollableActionsLayout', () {
    testWidgets('keeps actions tappable when body is taller than viewport', (tester) async {
      var taps = 0;
      const viewport = Size(375, 500);

      await tester.binding.setSurfaceSize(viewport);
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(size: viewport),
            child: Scaffold(
              body: SizedBox(
                height: 500,
                child: ScrollableActionsLayout(
                  body: Column(
                    children: List.generate(
                      40,
                      (i) => SizedBox(height: 40, child: Text('row $i')),
                    ),
                  ),
                  actions: [
                    FilledButton(
                      onPressed: () => taps++,
                      child: const Text('Do it'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      await expectNoLayoutOverflow(tester, () async {});
      await expectFullyTappable(
        tester,
        find.text('Do it'),
        within: find.byType(ScrollableActionsLayout),
      );
      expect(taps, 1);
    });

    testWidgets('stacks without Expanded when height is unbounded', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: ScrollableActionsLayout(
                body: Text('body'),
                actions: [Text('action')],
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('body'), findsOneWidget);
      expect(find.text('action'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
