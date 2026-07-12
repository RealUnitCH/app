import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:realunit_wallet/packages/service/dfx/dfx_support_service.dart';
import 'package:realunit_wallet/packages/service/dfx/models/support/dto/support_issue_dto.dart';
import 'package:realunit_wallet/packages/service/dfx/models/support/support_issue_reason.dart';
import 'package:realunit_wallet/packages/service/dfx/models/support/support_issue_state.dart';
import 'package:realunit_wallet/packages/service/dfx/models/support/support_issue_type.dart';
import 'package:realunit_wallet/screens/support/cubits/support_create_ticket/support_create_ticket_cubit.dart';
import 'package:realunit_wallet/screens/support/cubits/support_create_ticket/support_create_ticket_state.dart';

class _MockSupportService extends Mock implements DfxSupportService {}

SupportIssueDto _ticket() => SupportIssueDto(
      uid: 'created',
      state: SupportIssueState.created,
      type: SupportIssueType.bugReport,
      reason: SupportIssueReason.other,
      name: 'Bug Report',
      created: DateTime.utc(2026, 1, 1),
      messages: const [],
    );

void main() {
  late _MockSupportService service;

  setUpAll(() {
    registerFallbackValue(SupportIssueType.genericIssue);
    registerFallbackValue(SupportIssueReason.other);
  });

  setUp(() {
    service = _MockSupportService();
  });

  group('$SupportCreateTicketCubit', () {
    test('initial state has no selection, empty message, canSubmit=false', () {
      final cubit = SupportCreateTicketCubit(service);

      expect(cubit.state.selectedType, isNull);
      expect(cubit.state.selectedReason, isNull);
      expect(cubit.state.message, '');
      expect(cubit.state.canSubmit, isFalse);
    });

    blocTest<SupportCreateTicketCubit, SupportCreateTicketState>(
      'selectType sets the type AND resets reason to SupportIssueReason.other',
      build: () => SupportCreateTicketCubit(service),
      seed: () => const SupportCreateTicketState(
        selectedType: SupportIssueType.genericIssue,
        selectedReason: SupportIssueReason.fundsNotReceived,
      ),
      act: (cubit) => cubit.selectType(SupportIssueType.bugReport),
      expect: () => [
        const SupportCreateTicketState(
          selectedType: SupportIssueType.bugReport,
          selectedReason: SupportIssueReason.other,
        ),
      ],
    );

    blocTest<SupportCreateTicketCubit, SupportCreateTicketState>(
      'selectReason sets the reason without touching the type',
      build: () => SupportCreateTicketCubit(service),
      seed: () => const SupportCreateTicketState(
        selectedType: SupportIssueType.bugReport,
        selectedReason: SupportIssueReason.other,
      ),
      act: (cubit) => cubit.selectReason(SupportIssueReason.transactionMissing),
      expect: () => [
        const SupportCreateTicketState(
          selectedType: SupportIssueType.bugReport,
          selectedReason: SupportIssueReason.transactionMissing,
        ),
      ],
    );

    blocTest<SupportCreateTicketCubit, SupportCreateTicketState>(
      'updateMessage updates the message field',
      build: () => SupportCreateTicketCubit(service),
      act: (cubit) => cubit.updateMessage('hi there'),
      expect: () => [
        const SupportCreateTicketState(message: 'hi there'),
      ],
    );

    test('canSubmit requires type + reason + non-empty message + not submitting', () {
      const ready = SupportCreateTicketState(
        selectedType: SupportIssueType.bugReport,
        selectedReason: SupportIssueReason.other,
        message: 'a bug',
      );
      expect(ready.canSubmit, isTrue);
      // copyWith uses `?? this.x`, so null-args don't clear fields — build
      // each failing variant explicitly instead.
      expect(
        const SupportCreateTicketState(
          selectedReason: SupportIssueReason.other,
          message: 'a bug',
        ).canSubmit,
        isFalse,
        reason: 'selectedType=null blocks submit',
      );
      expect(
        const SupportCreateTicketState(
          selectedType: SupportIssueType.bugReport,
          message: 'a bug',
        ).canSubmit,
        isFalse,
        reason: 'selectedReason=null blocks submit',
      );
      expect(ready.copyWith(message: '').canSubmit, isFalse);
      expect(
        ready.copyWith(message: '   ').canSubmit,
        isFalse,
        reason: 'whitespace-only message is not enough',
      );
      expect(ready.copyWith(isSubmitting: true).canSubmit, isFalse);
    });

    test('submit() is a no-op when canSubmit is false', () async {
      final cubit = SupportCreateTicketCubit(service);

      await cubit.submit();

      verifyNever(() => service.createTicket(
            type: any(named: 'type'),
            reason: any(named: 'reason'),
            name: any(named: 'name'),
            message: any(named: 'message'),
          ));
      expect(cubit.state.isSubmitting, isFalse);
      expect(cubit.state.isSuccess, isFalse);
    });

    test('submit() sets isSubmitting=true then isSuccess=true on success and forwards the right name', () async {
      when(() => service.createTicket(
            type: any(named: 'type'),
            reason: any(named: 'reason'),
            name: any(named: 'name'),
            message: any(named: 'message'),
          )).thenAnswer((_) async => _ticket());
      final cubit = SupportCreateTicketCubit(service);
      cubit.selectType(SupportIssueType.bugReport);
      cubit.selectReason(SupportIssueReason.other);
      cubit.updateMessage('a bug');

      await cubit.submit();

      expect(cubit.state.isSuccess, isTrue);
      expect(cubit.state.isSubmitting, isFalse);
      expect(cubit.state.error, isNull);
      // bugReport → 'Bug Report' (one of the explicit mappings).
      verify(() => service.createTicket(
            type: SupportIssueType.bugReport,
            reason: SupportIssueReason.other,
            name: 'Bug Report',
            message: 'a bug',
          )).called(1);
    });

    test('submit() forwards "General Issue" for genericIssue type', () async {
      when(() => service.createTicket(
            type: any(named: 'type'),
            reason: any(named: 'reason'),
            name: any(named: 'name'),
            message: any(named: 'message'),
          )).thenAnswer((_) async => _ticket());
      final cubit = SupportCreateTicketCubit(service);
      cubit.selectType(SupportIssueType.genericIssue);
      cubit.selectReason(SupportIssueReason.other);
      cubit.updateMessage('hi');

      await cubit.submit();

      verify(() => service.createTicket(
            type: SupportIssueType.genericIssue,
            reason: SupportIssueReason.other,
            name: 'General Issue',
            message: 'hi',
          )).called(1);
    });

    test('submit() captures the error message on failure', () async {
      when(() => service.createTicket(
            type: any(named: 'type'),
            reason: any(named: 'reason'),
            name: any(named: 'name'),
            message: any(named: 'message'),
          )).thenAnswer((_) async => throw Exception('rate limited'));
      final cubit = SupportCreateTicketCubit(service);
      cubit.selectType(SupportIssueType.bugReport);
      cubit.selectReason(SupportIssueReason.other);
      cubit.updateMessage('msg');

      await cubit.submit();

      expect(cubit.state.isSubmitting, isFalse);
      expect(cubit.state.isSuccess, isFalse);
      expect(cubit.state.error, contains('rate limited'));
    });
  });
}
