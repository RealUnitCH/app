import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:realunit_wallet/screens/support/cubits/support_chat/support_chat_cubit.dart';
import 'package:realunit_wallet/screens/support/cubits/support_chat/support_chat_state.dart';
import 'package:realunit_wallet/screens/support/subpages/support_chat_page.dart';

import '../../../helper/helper.dart';

class _MockSupportChatCubit extends MockCubit<SupportChatState>
    implements SupportChatCubit {}

void main() {
  late _MockSupportChatCubit cubit;

  setUp(() {
    cubit = _MockSupportChatCubit();
    when(() => cubit.state).thenReturn(const SupportChatLoading());
  });

  Widget buildSubject() => BlocProvider<SupportChatCubit>.value(
        value: cubit,
        child: const SupportChatView(),
      );

  group('$SupportChatView', () {
    goldenTest(
      'loading state',
      fileName: 'support_chat_page_default',
      // CircularProgressIndicator never settles; pump once to capture the
      // initial frame instead of letting pumpAndSettle hang.
      pumpBeforeTest: pumpOnce,
      constraints: const BoxConstraints.tightFor(width: 390, height: 844),
      builder: () => wrapForGolden(buildSubject()),
    );
  });
}
