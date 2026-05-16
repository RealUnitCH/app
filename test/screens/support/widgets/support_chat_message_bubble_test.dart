import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:realunit_wallet/packages/service/dfx/models/support/support_message.dart';
import 'package:realunit_wallet/screens/support/widgets/support_chat_message_bubble.dart';
import 'package:realunit_wallet/styles/colors.dart';

Widget _host(Widget child) => MaterialApp(home: Scaffold(body: child));

SupportMessage _msg({
  String? author,
  String? body = 'Hello',
  DateTime? created,
}) =>
    SupportMessage(
      id: 1,
      author: author,
      message: body,
      created: created ?? DateTime.utc(2026, 5, 15, 10),
    );

void main() {
  group('$SupportChatMessageBubble', () {
    testWidgets('user message: blue bubble, aligned to end', (tester) async {
      await tester.pumpWidget(_host(
        SupportChatMessageBubble(supportMessage: _msg(author: 'user-1')),
      ));

      final container = tester.widget<Container>(find.byType(Container));
      final decoration = container.decoration! as BoxDecoration;
      expect(decoration.color, RealUnitColors.realUnitBlue);

      // The wrapping Row aligns to MainAxisAlignment.end for the user bubble.
      final row = tester.widget<Row>(find.byType(Row));
      expect(row.mainAxisAlignment, MainAxisAlignment.end);
    });

    testWidgets('support message: neutral grey bubble, aligned to start',
        (tester) async {
      await tester.pumpWidget(_host(
        SupportChatMessageBubble(supportMessage: _msg(author: null)),
      ));

      final container = tester.widget<Container>(find.byType(Container));
      final decoration = container.decoration! as BoxDecoration;
      expect(decoration.color, RealUnitColors.neutral100);

      final row = tester.widget<Row>(find.byType(Row));
      expect(row.mainAxisAlignment, MainAxisAlignment.start);
    });

    testWidgets('renders the message body', (tester) async {
      await tester.pumpWidget(_host(
        SupportChatMessageBubble(
          supportMessage: _msg(author: 'user-1', body: 'Where is my withdrawal?'),
        ),
      ));

      expect(find.text('Where is my withdrawal?'), findsOneWidget);
    });

    testWidgets('null body: no message Text rendered (only the timestamp)',
        (tester) async {
      await tester.pumpWidget(_host(
        SupportChatMessageBubble(
          supportMessage: _msg(author: null, body: null),
        ),
      ));

      // Only the timestamp Text remains.
      expect(find.byType(Text), findsOneWidget);
    });
  });
}
