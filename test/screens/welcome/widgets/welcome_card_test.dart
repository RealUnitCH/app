import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:realunit_wallet/screens/welcome/widgets/welcome_card.dart';
import 'package:realunit_wallet/styles/colors.dart';

import '../../../helper/helper.dart';

class MockFunction extends Mock {
  Future<void> onPressed();
}

void main() {
  late String title;
  Widget? trailing;
  List<WelcomeCardAction> actions = [];
  MockFunction functions = MockFunction();

  setUp(() {
    title = 'Welcome';
    when(() => functions.onPressed()).thenAnswer((_) => Future.value());
  });

  Widget buildSubject() {
    return WelcomeCard(
      title: title,
      trailing: trailing,
      actions: actions,
    );
  }

  group('$WelcomeCard', () {
    testWidgets('renders initially correctly', (tester) async {
      await tester.pumpApp(buildSubject());

      expect(find.byType(WelcomeCard), findsOne);
      expect(find.text('Welcome'), findsOne);
      expect(find.byType(FilledButton), findsNothing);
    });

    testWidgets('renders with trailing widget', (tester) async {
      trailing = Icon(Icons.info);

      await tester.pumpApp(buildSubject());

      expect(find.byWidget(trailing!), findsOne);
    });

    testWidgets('renders with action button', (tester) async {
      actions = [
        WelcomeCardAction(
          title: 'Get Started',
          style: WelcomeCardActionStyle.primary,
        ),
        WelcomeCardAction(
          title: 'Learn More',
          style: WelcomeCardActionStyle.secondary,
        ),
      ];

      await tester.pumpApp(buildSubject());

      expect(find.byType(FilledButton), findsNWidgets(actions.length));
      expect(
        find.byWidgetPredicate(
          (widget) {
            if (widget is FilledButton) {
              final bgColor = widget.style?.backgroundColor?.resolve({});
              final isTextMatch =
                  widget.child is Text && (widget.child as Text).data == 'Get Started';
              return isTextMatch && bgColor == RealUnitColors.brand600;
            }
            return false;
          },
        ),
        findsOne,
      );
      expect(
        find.byWidgetPredicate(
          (widget) {
            if (widget is FilledButton) {
              final bgColor = widget.style?.backgroundColor?.resolve({});
              final isTextMatch =
                  widget.child is Text && (widget.child as Text).data == 'Learn More';
              return isTextMatch && bgColor == RealUnitColors.neutral100;
            }
            return false;
          },
        ),
        findsOne,
      );
    });

    testWidgets('calls correct function when action button pressed', (tester) async {
      actions = [
        WelcomeCardAction(
          title: 'Get Started',
          onPressed: functions.onPressed,
          style: WelcomeCardActionStyle.primary,
        ),
      ];

      await tester.pumpApp(buildSubject());
      await tester.tap(find.byType(FilledButton));

      verify(() => functions.onPressed()).called(1);
    });
  });
}
