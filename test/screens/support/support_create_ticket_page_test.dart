import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:mocktail/mocktail.dart';
import 'package:realunit_wallet/packages/service/dfx/dfx_support_service.dart';
import 'package:realunit_wallet/packages/service/dfx/models/support/support_issue_reason.dart';
import 'package:realunit_wallet/packages/service/dfx/models/support/support_issue_type.dart';
import 'package:realunit_wallet/screens/support/cubits/support_create_ticket/support_create_ticket_cubit.dart';
import 'package:realunit_wallet/screens/support/cubits/support_create_ticket/support_create_ticket_state.dart';
import 'package:realunit_wallet/screens/support/subpages/support_create_ticket_page.dart';
import 'package:realunit_wallet/widgets/tag_selection.dart';

import '../../helper/pump_app.dart';

class MockSupportCreateTicketCubit extends MockCubit<SupportCreateTicketState>
    implements SupportCreateTicketCubit {}

class MockDfxSupportService extends Mock implements DfxSupportService {}

void main() {
  late SupportCreateTicketCubit supportCreateTicketCubit;

  setUp(() {
    supportCreateTicketCubit = MockSupportCreateTicketCubit();
    when(() => supportCreateTicketCubit.state).thenReturn(const SupportCreateTicketState());
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
      value: supportCreateTicketCubit,
      child: child,
    );
  }

  group('$SupportCreateTicketPage', () {
    testWidgets('renders $SupportCreateTicketView', (tester) async {
      await tester.pumpApp(const SupportCreateTicketPage());

      expect(find.byType(SupportCreateTicketView), findsOne);
    });
  });

  group('$SupportCreateTicketView', () {
    testWidgets('renders initially correctly', (tester) async {
      await tester.pumpApp(buildSubject(const SupportCreateTicketView()));

      expect(find.byType(TagSelection<SupportIssueType>), findsOne);
      expect(find.byType(TextField), findsOne);
      expect(find.byType(CircularProgressIndicator), findsNothing);
      final button = tester.widget<FilledButton>(find.bySubtype<FilledButton>());
      expect(button.onPressed, isNull);
    });

    testWidgets('renders correctly when submitting', (tester) async {
      when(() => supportCreateTicketCubit.state).thenReturn(
        const SupportCreateTicketState(
          selectedType: SupportIssueType.genericIssue,
          selectedReason: SupportIssueReason.other,
          message: 'test message',
          isSubmitting: true,
        ),
      );

      await tester.pumpApp(buildSubject(const SupportCreateTicketView()));

      expect(find.byType(CircularProgressIndicator), findsOne);
      final button = tester.widget<FilledButton>(find.bySubtype<FilledButton>());
      expect(button.onPressed, isNull);
    });

    testWidgets('renders correctly when can submit', (tester) async {
      when(() => supportCreateTicketCubit.state).thenReturn(
        const SupportCreateTicketState(
          selectedType: SupportIssueType.genericIssue,
          selectedReason: SupportIssueReason.other,
          message: 'test message',
        ),
      );

      await tester.pumpApp(buildSubject(const SupportCreateTicketView()));

      expect(find.byType(CircularProgressIndicator), findsNothing);
      final button = tester.widget<FilledButton>(find.bySubtype<FilledButton>());
      expect(button.onPressed, isNotNull);
    });
  });

  group('$BlocListener', () {
    testWidgets('shows SnackBar if creating ticket failed', (tester) async {
      whenListen(
        supportCreateTicketCubit,
        Stream.fromIterable([
          const SupportCreateTicketState(error: 'failed'),
        ]),
        initialState: const SupportCreateTicketState(),
      );

      await tester.pumpApp(buildSubject(const SupportCreateTicketView()));
      await tester.pump();

      expect(find.byType(SnackBar), findsOne);
    });
  });
}
