import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:mocktail/mocktail.dart';
import 'package:realunit_wallet/packages/service/dfx/dfx_kyc_service.dart';
import 'package:realunit_wallet/screens/kyc/steps/2fa/cubits/kyc_2fa/kyc_2fa_cubit.dart';
import 'package:realunit_wallet/screens/kyc/steps/2fa/cubits/kyc_2fa_verify/kyc_2fa_verify_cubit.dart';
import 'package:realunit_wallet/screens/kyc/steps/2fa/kyc_2fa_page.dart';
import 'package:realunit_wallet/widgets/form/labeled_text_field.dart';

import '../../../helper/pump_app.dart';

class MockKyc2FaCubit extends MockCubit<Kyc2FaState> implements Kyc2FaCubit {}

class MockKyc2FaVerifyCubit extends MockCubit<Kyc2FaVerifyState> implements Kyc2FaVerifyCubit {}

class MockDfxKycService extends Mock implements DfxKycService {}

class _OnVerifiedSpy {
  int callCount = 0;
  void call() => callCount++;
}

void main() {
  late Kyc2FaCubit kyc2FaCubit;
  late Kyc2FaVerifyCubit kyc2FaVerifyCubit;
  late _OnVerifiedSpy onVerified;

  setUp(() {
    kyc2FaCubit = MockKyc2FaCubit();
    kyc2FaVerifyCubit = MockKyc2FaVerifyCubit();
    onVerified = _OnVerifiedSpy();

    when(() => kyc2FaCubit.state).thenReturn(const Kyc2FaInitial());
    when(() => kyc2FaCubit.requestCode()).thenAnswer((_) => Future.value());
    when(() => kyc2FaVerifyCubit.state).thenReturn(const Kyc2FaVerifyInitial());
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
      ],
      child: child,
    );
  }

  group('$Kyc2FaPage', () {
    testWidgets('renders $Kyc2FaView', (tester) async {
      await tester.pumpApp(Kyc2FaPage(onVerified: onVerified.call));

      expect(find.byType(Kyc2FaView), findsOne);
    });
  });

  group('$Kyc2FaView', () {
    testWidgets('is initially rendered correctly', (tester) async {
      await tester.pumpApp(buildSubject(Kyc2FaView(onVerified: onVerified.call)));

      expect(find.byType(LabeledTextField), findsOne);
      expect(find.byType(FilledButton), findsOne);
      expect(find.byType(TextButton), findsOne);
    });
  });

  group('$BlocListener', () {
    testWidgets('invokes onVerified when verification succeeds', (tester) async {
      whenListen(
        kyc2FaVerifyCubit,
        Stream.fromIterable([
          const Kyc2FaVerifySuccess(),
        ]),
        initialState: const Kyc2FaVerifyInitial(),
      );

      await tester.pumpApp(buildSubject(Kyc2FaView(onVerified: onVerified.call)));
      await tester.pump();

      expect(onVerified.callCount, 1);
    });

    testWidgets('shows Snackbar if verification code is false', (tester) async {
      whenListen(
        kyc2FaVerifyCubit,
        Stream.fromIterable([
          const Kyc2FaVerifyFailure(errorMessage: 'Invalid verification code'),
        ]),
        initialState: const Kyc2FaVerifyInitial(),
      );

      await tester.pumpApp(buildSubject(Kyc2FaView(onVerified: onVerified.call)));
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

      await tester.pumpApp(buildSubject(Kyc2FaView(onVerified: onVerified.call)));
      await tester.pump();

      expect(find.byType(SnackBar), findsOne);
    });
  });
}
