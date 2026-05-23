import 'package:alchemist/alchemist.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
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
  });
}
