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

      await expectNoLayoutOverflow(tester, () async {
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
      });

      await expectFullyTappable(
        tester,
        find.text('Do it'),
        within: find.byType(ScrollableActionsLayout),
      );
      expect(taps, 1);
    });

    testWidgets('throws when height is unbounded (no silent degradation)', (tester) async {
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

      final exception = tester.takeException();
      expect(exception, isA<FlutterError>());
      expect(
        (exception as FlutterError).toString(),
        contains('requires a bounded height'),
      );
    });
  });
}
