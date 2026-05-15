import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:realunit_wallet/packages/service/dfx/dfx_support_service.dart';
import 'package:realunit_wallet/packages/service/dfx/models/support/dto/support_issue_dto.dart';
import 'package:realunit_wallet/packages/service/dfx/models/support/support_issue_reason.dart';
import 'package:realunit_wallet/packages/service/dfx/models/support/support_issue_state.dart';
import 'package:realunit_wallet/packages/service/dfx/models/support/support_issue_type.dart';
import 'package:realunit_wallet/screens/support/cubits/support_tickets/support_tickets_cubit.dart';
import 'package:realunit_wallet/screens/support/cubits/support_tickets/support_tickets_state.dart';

class _MockSupportService extends Mock implements DfxSupportService {}

SupportIssueDto _ticket({String uid = 'uid-1'}) => SupportIssueDto(
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

  // The cubit fires loadTickets() in its constructor; we assert the
  // final state via stream.firstWhere instead of the sequence (a
  // subscriber attached after construction misses the synchronous
  // Loading emit on a broadcast stream).
  group('$SupportTicketsCubit', () {
    test('reaches Loaded with mapped DTOs', () async {
      when(() => service.getTickets()).thenAnswer(
        (_) async => [_ticket(uid: 'a'), _ticket(uid: 'b')],
      );

      final cubit = SupportTicketsCubit(service);
      await cubit.stream.firstWhere((s) => s is SupportTicketsLoaded);

      expect((cubit.state as SupportTicketsLoaded).tickets, hasLength(2));
      expect((cubit.state as SupportTicketsLoaded).tickets.first.uid, 'a');
    });

    test('reaches Loaded(empty) for an empty list', () async {
      when(() => service.getTickets()).thenAnswer((_) async => []);

      final cubit = SupportTicketsCubit(service);
      await cubit.stream.firstWhere((s) => s is SupportTicketsLoaded);

      expect((cubit.state as SupportTicketsLoaded).tickets, isEmpty);
    });

    test('reaches Error when the service throws', () async {
      when(() => service.getTickets()).thenAnswer((_) async => throw Exception('network down'));

      final cubit = SupportTicketsCubit(service);
      await cubit.stream.firstWhere((s) => s is SupportTicketsError);

      expect((cubit.state as SupportTicketsError).message, contains('network down'));
    });

    test('manual loadTickets() refreshes after an initial error', () async {
      // Async throw on the first call so Loading actually transitions.
      var calls = 0;
      when(() => service.getTickets()).thenAnswer((_) async {
        calls++;
        if (calls == 1) throw Exception('boom');
        return [_ticket(uid: 'recovered')];
      });

      final cubit = SupportTicketsCubit(service);
      await cubit.stream.firstWhere((s) => s is SupportTicketsError);
      await cubit.loadTickets();

      expect(cubit.state, isA<SupportTicketsLoaded>());
      expect((cubit.state as SupportTicketsLoaded).tickets.single.uid, 'recovered');
    });
  });
}
