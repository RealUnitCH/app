import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:mocktail/mocktail.dart';
import 'package:realunit_wallet/packages/service/dfx/dfx_kyc_service.dart';
import 'package:realunit_wallet/screens/kyc/cubits/kyc/kyc_cubit.dart';
import 'package:realunit_wallet/screens/kyc/steps/2fa/cubits/kyc_2fa/kyc_2fa_cubit.dart';
import 'package:realunit_wallet/screens/kyc/steps/2fa/cubits/kyc_2fa_verify/kyc_2fa_verify_cubit.dart';
import 'package:realunit_wallet/screens/kyc/steps/2fa/kyc_2fa_page.dart';
import 'package:realunit_wallet/widgets/buttons/app_text_button.dart';
import 'package:realunit_wallet/widgets/form/labeled_text_field.dart';

import '../../../helper/pump_app.dart';

class MockKyc2FaCubit extends MockCubit<Kyc2FaState> implements Kyc2FaCubit {}

class MockKyc2FaVerifyCubit extends MockCubit<Kyc2FaVerifyState> implements Kyc2FaVerifyCubit {}

class MockKycCubit extends MockCubit<KycState> implements KycCubit {}

class MockDfxKycService extends Mock implements DfxKycService {}

void main() {
  late Kyc2FaCubit kyc2FaCubit;
  late Kyc2FaVerifyCubit kyc2FaVerifyCubit;
  late KycCubit kycCubit;

  setUp(() {
    kyc2FaCubit = MockKyc2FaCubit();
    kyc2FaVerifyCubit = MockKyc2FaVerifyCubit();
    kycCubit = MockKycCubit();

    when(() => kyc2FaCubit.state).thenReturn(const Kyc2FaInitial());
    when(() => kyc2FaCubit.requestCode()).thenAnswer((_) => Future.value());
    when(() => kyc2FaVerifyCubit.state).thenReturn(const Kyc2FaVerifyInitial());
    when(() => kycCubit.state).thenReturn(const KycInitial());
    when(() => kycCubit.checkKyc()).thenAnswer((_) => Future.value());
  });

  void setupDependencyInjection() {
    final getIt = GetIt.instance;
    getIt.registerSingleton<DfxKycService>(MockDfxKycService());
  }

  setUpAll(() {
    setupDependencyInjection();
  });

  tearDownAll(() async => await GetIt.instance.reset());

  Widget buildSubject(Widget child) {
    return MultiBlocProvider(
      providers: [
        BlocProvider.value(value: kyc2FaCubit),
        BlocProvider.value(value: kyc2FaVerifyCubit),
        BlocProvider.value(value: kycCubit),
      ],
      child: child,
    );
  }

  group('$Kyc2FaPage', () {
    testWidgets('renders $Kyc2FaView', (tester) async {
      await tester.pumpApp(const Kyc2FaPage());

      expect(find.byType(Kyc2FaView), findsOne);
    });
  });

  group('$Kyc2FaView', () {
    testWidgets('is initially rendered correctly', (tester) async {
      await tester.pumpApp(buildSubject(const Kyc2FaView()));

      expect(find.byType(LabeledTextField), findsOne);
      expect(find.byType(FilledButton), findsOne);
      expect(find.byType(AppTextButton), findsOne);
    });
  });

  group('$BlocListener', () {
    testWidgets('triggers checkKyc if verification code is correct', (tester) async {
      whenListen(
        kyc2FaVerifyCubit,
        Stream.fromIterable([
          const Kyc2FaVerifySuccess(),
        ]),
        initialState: const Kyc2FaVerifyInitial(),
      );

      await tester.pumpApp(buildSubject(const Kyc2FaView()));
      await tester.pump();

      verify(() => kycCubit.checkKyc()).called(1);
    });

    testWidgets('shows Snackbar if verification code is false', (tester) async {
      whenListen(
        kyc2FaVerifyCubit,
        Stream.fromIterable([
          const Kyc2FaVerifyFailure(errorMessage: 'Invalid verification code'),
        ]),
        initialState: const Kyc2FaVerifyInitial(),
      );

      await tester.pumpApp(buildSubject(const Kyc2FaView()));
      await tester.pump();

      expect(find.byType(SnackBar), findsOne);
    });

    testWidgets('shows Snackbar if verification code could not be sent', (tester) async {
      whenListen(
        kyc2FaCubit,
        Stream.fromIterable([
          const Kyc2FaFailure(errorMessage: 'Code could not be sent'),
        ]),
        initialState: const Kyc2FaInitial(),
      );

      await tester.pumpApp(buildSubject(const Kyc2FaView()));
      await tester.pump();

      expect(find.byType(SnackBar), findsOne);
    });
  });
}
