import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:realunit_wallet/screens/support/cubits/support_page/support_page_cubit.dart';
import 'package:realunit_wallet/screens/support/support_page.dart';

import '../../../helper/helper.dart';

class _MockSupportPageCubit extends MockCubit<SupportPageState> implements SupportPageCubit {}

void main() {
  late _MockSupportPageCubit cubit;

  setUp(() {
    cubit = _MockSupportPageCubit();
    when(() => cubit.state).thenReturn(const SupportPageIdle());
  });

  Widget buildSubject() => BlocProvider<SupportPageCubit>.value(
    value: cubit,
    child: const SupportView(),
  );

  group('$SupportView', () {
    goldenTest(
      'default tiles',
      fileName: 'support_page_default',
      constraints: const BoxConstraints.tightFor(width: 390, height: 844),
      builder: () => wrapForGolden(buildSubject()),
    );
  });
}
