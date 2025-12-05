import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:realunit_wallet/screens/welcome/widgets/welcome_card.dart';

import '../../../helper/helper.dart';

class MockFunction extends Mock {
  Future<void> onPressed();
}

void main() {
  late String title;
  String? description;
  VoidCallback? onPressed;
  Widget? trailing;
  MockFunction functions = MockFunction();

  setUp(() {
    title = 'Welcome';
    when(() => functions.onPressed()).thenAnswer((_) => Future.value());
  });

  Widget buildSubject() {
    return WelcomeCard(
      title: title,
      description: description,
      onPressed: onPressed,
      trailing: trailing,
    );
  }

  group('$WelcomeCard', () {
    testWidgets('renders initially correctly', (tester) async {
      await tester.pumpApp(buildSubject());

      expect(find.byType(WelcomeCard), findsOne);
      expect(find.text(title), findsOne);
      expect(find.byType(Text), findsNWidgets(1));
    });

    testWidgets('renders with description', (tester) async {
      description = 'Description';

      await tester.pumpApp(buildSubject());

      expect(find.text(description!), findsOne);
      expect(find.byType(Text), findsNWidgets(2));
    });

    testWidgets('renders with trailing widget', (tester) async {
      trailing = Icon(Icons.info);

      await tester.pumpApp(buildSubject());

      expect(find.byWidget(trailing!), findsOne);
    });

    testWidgets('calls correct function when pressed', (tester) async {
      onPressed = functions.onPressed;

      await tester.pumpApp(buildSubject());
      await tester.tap(find.byType(WelcomeCard));
      await tester.pumpAndSettle();

      verify(() => functions.onPressed()).called(1);
    });
  });
}
