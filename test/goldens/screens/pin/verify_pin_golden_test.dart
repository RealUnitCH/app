import 'package:alchemist/alchemist.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:realunit_wallet/screens/pin/bloc/verify_pin/verify_pin_cubit.dart';
import 'package:realunit_wallet/screens/pin/verify_pin_page.dart';

import '../../../helper/helper.dart';

class _MockVerifyPinCubit extends MockCubit<VerifyPinState>
    implements VerifyPinCubit {}

void main() {
  late _MockVerifyPinCubit verifyPinCubit;

  setUp(() {
    verifyPinCubit = _MockVerifyPinCubit();
    when(() => verifyPinCubit.state).thenReturn(const VerifyPinState());
    when(() => verifyPinCubit.checkBiometricAvailability())
        .thenAnswer((_) async {});
  });

  Widget buildSubject() => BlocProvider<VerifyPinCubit>.value(
        value: verifyPinCubit,
        child: VerifyPinView(onAuthenticated: () {}),
      );

  group('$VerifyPinView', () {
    goldenTest(
      'default state',
      fileName: 'verify_pin_page_default',
      constraints: const BoxConstraints.tightFor(width: 390, height: 844),
      builder: () => wrapForGolden(buildSubject()),
    );
  });
}
