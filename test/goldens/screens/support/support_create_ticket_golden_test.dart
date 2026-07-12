import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:realunit_wallet/packages/service/dfx/models/support/support_issue_reason.dart';
import 'package:realunit_wallet/packages/service/dfx/models/support/support_issue_type.dart';
import 'package:realunit_wallet/screens/support/cubits/support_create_ticket/support_create_ticket_cubit.dart';
import 'package:realunit_wallet/screens/support/cubits/support_create_ticket/support_create_ticket_state.dart';
import 'package:realunit_wallet/screens/support/subpages/support_create_ticket_page.dart';

import '../../../helper/helper.dart';

class _MockSupportCreateTicketCubit extends MockCubit<SupportCreateTicketState>
    implements SupportCreateTicketCubit {}

void main() {
  late _MockSupportCreateTicketCubit cubit;

  setUp(() {
    cubit = _MockSupportCreateTicketCubit();
    when(() => cubit.state).thenReturn(const SupportCreateTicketState());
  });

  Widget buildSubject() => BlocProvider<SupportCreateTicketCubit>.value(
        value: cubit,
        child: const SupportCreateTicketView(),
      );

  group('$SupportCreateTicketView', () {
    goldenTest(
      'default empty form',
      fileName: 'support_create_ticket_page_default',
      constraints: const BoxConstraints.tightFor(width: 390, height: 844),
      builder: () => wrapForGolden(buildSubject()),
    );

    // `selectType` sets `selectedReason` to `other` alongside `selectedType`,
    // and a non-empty `message` flips `canSubmit` to true, so the Send button
    // renders enabled. The message TextField renders empty because the field is
    // not bound to state (it drives the cubit via `onChanged` only); the
    // enabled button is what proves the filled state.
    goldenTest(
      'filled form — type tag selected, send button enabled',
      fileName: 'support_create_ticket_page_filled',
      constraints: phoneConstraints,
      builder: () {
        when(() => cubit.state).thenReturn(
          const SupportCreateTicketState(
            selectedType: SupportIssueType.genericIssue,
            selectedReason: SupportIssueReason.other,
            message: 'Ich habe eine Frage zu meinem Konto.',
          ),
        );
        return wrapForGolden(buildSubject());
      },
    );

    goldenTest(
      'submitting — send button shows the loading spinner',
      fileName: 'support_create_ticket_page_submitting',
      // The loading button hosts a CupertinoActivityIndicator; freeze it on the
      // first frame instead of letting pumpAndSettle hang.
      pumpBeforeTest: pumpOnce,
      constraints: phoneConstraints,
      builder: () {
        when(() => cubit.state).thenReturn(
          const SupportCreateTicketState(
            selectedType: SupportIssueType.genericIssue,
            selectedReason: SupportIssueReason.other,
            message: 'Ich habe eine Frage zu meinem Konto.',
            isSubmitting: true,
          ),
        );
        return wrapForGolden(buildSubject());
      },
    );
  });
}
