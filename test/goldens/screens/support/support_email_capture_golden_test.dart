import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:realunit_wallet/screens/support/cubits/support_email_capture/support_email_capture_cubit.dart';
import 'package:realunit_wallet/screens/support/subpages/support_email_capture_page.dart';

import '../../../helper/helper.dart';

class _MockSupportEmailCaptureCubit extends MockCubit<SupportEmailCaptureState>
    implements SupportEmailCaptureCubit {}

void main() {
  late _MockSupportEmailCaptureCubit cubit;

  setUp(() {
    cubit = _MockSupportEmailCaptureCubit();
    when(() => cubit.state).thenReturn(const SupportEmailCaptureInitial());
  });

  Widget buildSubject() => BlocProvider<SupportEmailCaptureCubit>.value(
    value: cubit,
    child: const SupportEmailCaptureView(),
  );

  group('$SupportEmailCaptureView', () {
    goldenTest(
      'default empty form',
      fileName: 'support_email_capture_page_default',
      constraints: const BoxConstraints.tightFor(width: 390, height: 844),
      builder: () => wrapForGolden(buildSubject()),
    );

    goldenTest(
      'submitting loading state',
      fileName: 'support_email_capture_page_submitting',
      constraints: const BoxConstraints.tightFor(width: 390, height: 844),
      // CupertinoActivityIndicator ticks forever; pumpOnce stops alchemist
      // from waiting for animation completion (same pattern as
      // `kyc_email_page_loading` in `kyc_email_golden_test.dart`).
      pumpBeforeTest: pumpOnce,
      builder: () {
        when(() => cubit.state).thenReturn(const SupportEmailCaptureSubmitting());
        return wrapForGolden(buildSubject());
      },
    );
  });
}
