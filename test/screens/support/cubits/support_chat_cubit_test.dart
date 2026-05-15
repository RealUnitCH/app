import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:realunit_wallet/packages/service/dfx/dfx_support_service.dart';
import 'package:realunit_wallet/packages/service/dfx/models/support/dto/support_issue_dto.dart';
import 'package:realunit_wallet/packages/service/dfx/models/support/support_issue_reason.dart';
import 'package:realunit_wallet/packages/service/dfx/models/support/support_issue_state.dart';
import 'package:realunit_wallet/packages/service/dfx/models/support/support_issue_type.dart';
import 'package:realunit_wallet/screens/support/cubits/support_chat/support_chat_cubit.dart';
import 'package:realunit_wallet/screens/support/cubits/support_chat/support_chat_state.dart';

class _MockSupportService extends Mock implements DfxSupportService {}

const _ticketUid = 'uid-1';

SupportIssueDto _ticket({String uid = _ticketUid}) => SupportIssueDto(
      uid: uid,
      state: SupportIssueState.created,
      type: SupportIssueType.genericIssue,
      reason: SupportIssueReason.other,
      name: 'Test ticket',
      created: DateTime.utc(2026, 1, 1),
      messages: const [],
    );

void main() {
  late _MockSupportService service;

  setUp(() {
    service = _MockSupportService();
  });

  // Constructor fires loadTicket(); we assert the final state via
  // stream.firstWhere rather than the full sequence.
  group('$SupportChatCubit', () {
    test('reaches Loaded with the mapped ticket', () async {
      when(() => service.getTicket(_ticketUid))
          .thenAnswer((_) async => _ticket());

      final cubit = SupportChatCubit(service, _ticketUid);
      await cubit.stream.firstWhere((s) => s is SupportChatLoaded);

      expect((cubit.state as SupportChatLoaded).ticket.uid, _ticketUid);
      expect((cubit.state as SupportChatLoaded).isSending, isFalse);
    });

    test('reaches Error when getTicket fails', () async {
      when(() => service.getTicket(any()))
          .thenAnswer((_) async => throw Exception('boom'));

      final cubit = SupportChatCubit(service, _ticketUid);
      await cubit.stream.firstWhere((s) => s is SupportChatError);

      expect((cubit.state as SupportChatError).message, contains('boom'));
    });

    test('sendMessage is a no-op when not in Loaded state', () async {
      when(() => service.getTicket(any()))
          .thenAnswer((_) async => throw Exception('still loading'));
      final cubit = SupportChatCubit(service, _ticketUid);
      await cubit.stream.firstWhere((s) => s is SupportChatError);

      await cubit.sendMessage('hello');

      // sendMessage must NOT call the service while in Error state.
      verifyNever(() => service.sendMessage(any(), any()));
    });

    test('sendMessage is a no-op for whitespace-only input', () async {
      when(() => service.getTicket(_ticketUid))
          .thenAnswer((_) async => _ticket());
      final cubit = SupportChatCubit(service, _ticketUid);
      await cubit.stream.firstWhere((s) => s is SupportChatLoaded);
      clearInteractions(service);

      await cubit.sendMessage('   \t  ');

      verifyNever(() => service.sendMessage(any(), any()));
    });

    test('sendMessage posts the message and re-fetches the ticket', () async {
      when(() => service.getTicket(_ticketUid))
          .thenAnswer((_) async => _ticket());
      when(() => service.sendMessage(any(), any())).thenAnswer((_) async {});
      final cubit = SupportChatCubit(service, _ticketUid);
      await cubit.stream.firstWhere((s) => s is SupportChatLoaded);

      await cubit.sendMessage('hello');

      verify(() => service.sendMessage(_ticketUid, 'hello')).called(1);
      // After loadTicket() + sendMessage(), getTicket has been called twice.
      verify(() => service.getTicket(_ticketUid)).called(2);
      expect(cubit.state, isA<SupportChatLoaded>());
      expect((cubit.state as SupportChatLoaded).isSending, isFalse);
    });

    test('sendMessage clears isSending=true when the service fails', () async {
      when(() => service.getTicket(_ticketUid))
          .thenAnswer((_) async => _ticket());
      when(() => service.sendMessage(any(), any()))
          .thenAnswer((_) async => throw Exception('nope'));

      final cubit = SupportChatCubit(service, _ticketUid);
      await cubit.stream.firstWhere((s) => s is SupportChatLoaded);

      await cubit.sendMessage('hello');

      // Stays Loaded but isSending is reset to false.
      expect(cubit.state, isA<SupportChatLoaded>());
      expect((cubit.state as SupportChatLoaded).isSending, isFalse);
    });
  });
}
