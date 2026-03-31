import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:mocktail/mocktail.dart';
import 'package:realunit_wallet/packages/service/dfx/dfx_support_service.dart';
import 'package:realunit_wallet/packages/service/dfx/models/support/support_issue.dart';
import 'package:realunit_wallet/packages/service/dfx/models/support/support_issue_reason.dart';
import 'package:realunit_wallet/packages/service/dfx/models/support/support_issue_state.dart';
import 'package:realunit_wallet/packages/service/dfx/models/support/support_issue_type.dart';
import 'package:realunit_wallet/packages/service/dfx/models/support/support_message.dart';
import 'package:realunit_wallet/screens/support/cubits/support_chat/support_chat_cubit.dart';
import 'package:realunit_wallet/screens/support/cubits/support_chat/support_chat_state.dart';
import 'package:realunit_wallet/screens/support/subpages/support_chat_page.dart';
import 'package:realunit_wallet/screens/support/widgets/support_chat_message_bubble.dart';
import 'package:realunit_wallet/screens/support/widgets/support_chat_message_input_field.dart';

import '../../helper/pump_app.dart';

class MockSupportChatCubit extends MockCubit<SupportChatState>
    implements SupportChatCubit {}

class MockDfxSupportService extends Mock implements DfxSupportService {}

void main() {
  late SupportChatCubit supportChatCubit;

  setUp(() {
    supportChatCubit = MockSupportChatCubit();
    when(() => supportChatCubit.state).thenReturn(const SupportChatInitial());
  });

  void setupDependencyInjection() {
    final getIt = GetIt.instance;
    getIt.registerSingleton<DfxSupportService>(MockDfxSupportService());
  }

  setUpAll(() {
    setupDependencyInjection();
  });

  Widget buildSubject(Widget child) {
    return BlocProvider.value(
      value: supportChatCubit,
      child: child,
    );
  }

  group('$SupportChatPage', () {
    testWidgets('renders $SupportChatView', (tester) async {
      await tester.pumpApp(const SupportChatPage(ticketUid: 'test-uid'));

      expect(find.byType(SupportChatView), findsOne);
    });
  });

  group('$SupportChatView', () {
    testWidgets('renders initially correctly', (tester) async {
      await tester.pumpApp(buildSubject(const SupportChatView()));

      expect(find.byType(SizedBox), findsOne);
    });

    testWidgets('renders correctly when loading', (tester) async {
      when(() => supportChatCubit.state).thenReturn(const SupportChatLoading());

      await tester.pumpApp(buildSubject(const SupportChatView()));

      expect(find.byType(CupertinoActivityIndicator), findsOne);
    });

    testWidgets('renders correctly when loading failed', (tester) async {
      const error = 'failed';
      when(() => supportChatCubit.state).thenReturn(const SupportChatError(error));

      await tester.pumpApp(buildSubject(const SupportChatView()));

      expect(find.text(error), findsOne);
    });

    testWidgets('renders correctly when successfully loaded', (tester) async {
      final messages = [
        SupportMessage(id: 1, created: DateTime.now(), message: 'Hello'),
        SupportMessage(id: 2, created: DateTime.now(), message: 'World'),
      ];
      final ticket = SupportIssue(
        uid: '123',
        created: DateTime.now(),
        messages: messages,
        name: 'name',
        reason: SupportIssueReason.other,
        state: SupportIssueState.created,
        type: SupportIssueType.genericIssue,
      );
      when(() => supportChatCubit.state).thenReturn(SupportChatLoaded(ticket: ticket));

      await tester.pumpApp(buildSubject(const SupportChatView()));

      expect(find.byType(ListView), findsOne);
      expect(find.byType(SupportChatMessageBubble), findsNWidgets(messages.length));
      expect(find.byType(SupportChatMessageInputField), findsOne);
    });

    testWidgets('renders correctly when successfully loaded with no messages', (tester) async {
      final ticket = SupportIssue(
        uid: '123',
        created: DateTime.now(),
        messages: [],
        name: 'name',
        reason: SupportIssueReason.other,
        state: SupportIssueState.created,
        type: SupportIssueType.genericIssue,
      );
      when(() => supportChatCubit.state).thenReturn(SupportChatLoaded(ticket: ticket));

      await tester.pumpApp(buildSubject(const SupportChatView()));

      expect(find.byType(ListView), findsOne);
      expect(find.byType(SupportChatMessageBubble), findsNothing);
      expect(find.byType(SupportChatMessageInputField), findsOne);
    });
  });
}
