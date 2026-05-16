import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:realunit_wallet/screens/support/widgets/support_chat_message_input_field.dart';

import '../../../helper/helper.dart';

Widget _host(Widget child) => Scaffold(body: child);

void main() {
  late TextEditingController controller;

  setUp(() {
    controller = TextEditingController();
  });

  tearDown(() {
    controller.dispose();
  });

  group('$SupportChatMessageInputField', () {
    testWidgets('closed ticket: shows the disabled banner, no TextField, no send IconButton',
        (tester) async {
      await tester.pumpApp(_host(
        SupportChatMessageInputField(
          controller: controller,
          isSending: false,
          isTicketOpen: false,
          onSend: () {},
        ),
      ));

      expect(find.byType(TextField), findsNothing);
      expect(find.byType(IconButton), findsNothing);
      // Banner is the only Text widget in the tree.
      expect(find.byType(Text), findsOneWidget);
    });

    testWidgets('open + idle: TextField enabled + send IconButton active',
        (tester) async {
      var sends = 0;
      await tester.pumpApp(_host(
        SupportChatMessageInputField(
          controller: controller,
          isSending: false,
          isTicketOpen: true,
          onSend: () => sends++,
        ),
      ));

      final field = tester.widget<TextField>(find.byType(TextField));
      expect(field.enabled, isTrue);

      // The send icon is the rocket-style send_rounded; tapping fires onSend.
      expect(find.byIcon(Icons.send_rounded), findsOneWidget);
      await tester.tap(find.byType(IconButton));
      await tester.pump();
      expect(sends, 1);
    });

    testWidgets('open + sending: TextField disabled + IconButton inactive (onPressed null)',
        (tester) async {
      var sends = 0;
      await tester.pumpApp(_host(
        SupportChatMessageInputField(
          controller: controller,
          isSending: true,
          isTicketOpen: true,
          onSend: () => sends++,
        ),
      ));

      final field = tester.widget<TextField>(find.byType(TextField));
      expect(field.enabled, isFalse);

      // The send icon is replaced by a CupertinoActivityIndicator and the
      // IconButton has onPressed: null.
      expect(find.byType(CupertinoActivityIndicator), findsOneWidget);
      expect(find.byIcon(Icons.send_rounded), findsNothing);

      final btn = tester.widget<IconButton>(find.byType(IconButton));
      expect(btn.onPressed, isNull);

      await tester.tap(find.byType(IconButton));
      await tester.pump();
      expect(sends, 0); // disabled tap is a no-op
    });
  });
}
