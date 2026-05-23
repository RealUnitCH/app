import 'package:alchemist/alchemist.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:realunit_wallet/screens/kyc/cubits/kyc/kyc_cubit.dart';
import 'package:realunit_wallet/screens/kyc/steps/2fa/cubits/kyc_2fa/kyc_2fa_cubit.dart';
import 'package:realunit_wallet/screens/kyc/steps/2fa/cubits/kyc_2fa_verify/kyc_2fa_verify_cubit.dart';
import 'package:realunit_wallet/screens/kyc/steps/2fa/kyc_2fa_page.dart';

import '../../../helper/helper.dart';

class _MockKyc2FaCubit extends MockCubit<Kyc2FaState> implements Kyc2FaCubit {}

class _MockKyc2FaVerifyCubit extends MockCubit<Kyc2FaVerifyState>
    implements Kyc2FaVerifyCubit {}

class _MockKycCubit extends MockCubit<KycState> implements KycCubit {}

void main() {
  const phoneConstraints = BoxConstraints.tightFor(width: 390, height: 844);

  late _MockKyc2FaCubit kyc2FaCubit;
  late _MockKyc2FaVerifyCubit kyc2FaVerifyCubit;
  late _MockKycCubit kycCubit;

  setUp(() {
    kyc2FaCubit = _MockKyc2FaCubit();
    kyc2FaVerifyCubit = _MockKyc2FaVerifyCubit();
    kycCubit = _MockKycCubit();

    when(() => kyc2FaCubit.state).thenReturn(const Kyc2FaInitial());
    when(() => kyc2FaCubit.requestCode()).thenAnswer((_) => Future.value());
    when(() => kyc2FaVerifyCubit.state).thenReturn(const Kyc2FaVerifyInitial());
    when(() => kycCubit.state).thenReturn(const KycInitial());
  });

  group('$Kyc2FaView', () {
    goldenTest(
      'initial empty state',
      fileName: 'kyc_2fa_page_default',
      constraints: phoneConstraints,
      builder: () => wrapForGolden(
        MultiBlocProvider(
          providers: [
            BlocProvider<Kyc2FaCubit>.value(value: kyc2FaCubit),
            BlocProvider<Kyc2FaVerifyCubit>.value(value: kyc2FaVerifyCubit),
            BlocProvider<KycCubit>.value(value: kycCubit),
          ],
          child: const Kyc2FaView(),
        ),
      ),
    );
  });
}
