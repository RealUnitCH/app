import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:realunit_wallet/widgets/standard_slide_button.dart';

Widget _host(Widget child) => MaterialApp(
      home: Scaffold(
        body: SizedBox(
          width: 300, // Fixed width so the drag math is deterministic.
          child: child,
        ),
      ),
    );

void main() {
  group('$StandardSlideButton', () {
    testWidgets('renders the buttonText label', (tester) async {
      await tester.pumpWidget(_host(
        StandardSlideButton(
          buttonText: 'Slide to confirm',
          onSlideComplete: () {},
        ),
      ));

      expect(find.text('Slide to confirm'), findsOneWidget);
    });

    testWidgets('a small drag (< 90% across) does NOT fire onSlideComplete',
        (tester) async {
      var fired = 0;
      await tester.pumpWidget(_host(
        StandardSlideButton(
          buttonText: 'Slide',
          onSlideComplete: () => fired++,
        ),
      ));

      final knob = find.byIcon(Icons.arrow_forward_ios);
      // Drag the knob 50px to the right — well short of the 90% threshold
      // (effectiveMaxWidth ≈ 292; required ≈ 212).
      await tester.drag(knob, const Offset(50, 0));
      await tester.pumpAndSettle();

      expect(fired, 0);
    });

    testWidgets('a long drag (full width) fires onSlideComplete', (tester) async {
      var fired = 0;
      await tester.pumpWidget(_host(
        StandardSlideButton(
          buttonText: 'Slide',
          onSlideComplete: () => fired++,
        ),
      ));

      final knob = find.byIcon(Icons.arrow_forward_ios);
      // Drag far past the threshold; the cubit clamps overshoot.
      await tester.drag(knob, const Offset(500, 0));
      await tester.pumpAndSettle();

      expect(fired, 1);
    });

    testWidgets('the knob snaps back to the left edge after each drag',
        (tester) async {
      await tester.pumpWidget(_host(
        StandardSlideButton(
          buttonText: 'Slide',
          onSlideComplete: () {},
        ),
      ));

      final knob = find.byIcon(Icons.arrow_forward_ios);
      await tester.drag(knob, const Offset(500, 0));
      await tester.pumpAndSettle();

      // After release, the knob's container has snapped back to _dragPosition=0.
      // The Positioned wraps it with left = sideMargin (4) + _dragPosition (0).
      final positioned = tester.widget<Positioned>(find.byType(Positioned));
      expect(positioned.left, 4.0);
    });
  });
}
