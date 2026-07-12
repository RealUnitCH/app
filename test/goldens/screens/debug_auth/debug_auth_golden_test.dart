import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:realunit_wallet/screens/debug_auth/cubit/debug_auth_cubit.dart';
import 'package:realunit_wallet/screens/debug_auth/debug_auth_view.dart';

import '../../../helper/helper.dart';

class _MockDebugAuthCubit extends MockCubit<DebugAuthState>
    implements DebugAuthCubit {}

void main() {
  late _MockDebugAuthCubit debugAuthCubit;

  setUp(() {
    debugAuthCubit = _MockDebugAuthCubit();
    when(() => debugAuthCubit.state).thenReturn(const DebugAuthState());
  });

  Widget buildSubject() => BlocProvider<DebugAuthCubit>.value(
        value: debugAuthCubit,
        child: const DebugAuthView(),
      );

  group('$DebugAuthView', () {
    goldenTest(
      'default state',
      fileName: 'debug_auth_page_default',
      constraints: const BoxConstraints.tightFor(width: 390, height: 844),
      builder: () => wrapForGolden(buildSubject()),
    );
  });
}
