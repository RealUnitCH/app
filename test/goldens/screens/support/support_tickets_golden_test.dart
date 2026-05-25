import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:realunit_wallet/screens/support/cubits/support_tickets/support_tickets_cubit.dart';
import 'package:realunit_wallet/screens/support/cubits/support_tickets/support_tickets_state.dart';
import 'package:realunit_wallet/screens/support/subpages/support_tickets_page.dart';

import '../../../helper/helper.dart';

class _MockSupportTicketsCubit extends MockCubit<SupportTicketsState>
    implements SupportTicketsCubit {}

void main() {
  late _MockSupportTicketsCubit cubit;

  setUp(() {
    cubit = _MockSupportTicketsCubit();
    when(() => cubit.state).thenReturn(const SupportTicketsLoaded([]));
  });

  Widget buildSubject() => BlocProvider<SupportTicketsCubit>.value(
        value: cubit,
        child: const SupportTicketsView(),
      );

  group('$SupportTicketsView', () {
    goldenTest(
      'empty tickets list',
      fileName: 'support_tickets_page_default',
      constraints: const BoxConstraints.tightFor(width: 390, height: 844),
      builder: () => wrapForGolden(buildSubject()),
    );
  });
}
