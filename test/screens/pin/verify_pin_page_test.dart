import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:mocktail/mocktail.dart';
import 'package:realunit_wallet/generated/i18n.dart';
import 'package:realunit_wallet/packages/service/biometric_service.dart';
import 'package:realunit_wallet/packages/storage/secure_storage.dart';
import 'package:realunit_wallet/screens/pin/bloc/auth/pin_auth_cubit.dart';
import 'package:realunit_wallet/screens/pin/bloc/verify_pin/verify_pin_cubit.dart';
import 'package:realunit_wallet/screens/pin/verify_pin_page.dart';
import 'package:realunit_wallet/screens/pin/widgets/pin_indicator.dart';
import 'package:realunit_wallet/setup/di.dart';
import 'package:realunit_wallet/widgets/number_pad.dart';

import '../../helper/pump_app.dart';

class MockVerifyPinCubit extends MockCubit<VerifyPinState> implements VerifyPinCubit {}

class MockPinAuthCubit extends MockCubit<PinAuthState> implements PinAuthCubit {}

class MockBiometricService extends Mock implements BiometricService {}

class MockSecureStorage extends Mock implements SecureStorage {}

void main() {
  late VerifyPinCubit verifyPinCubit;
  late PinAuthCubit pinAuthCubit;
  void onAuthenticated() => {};

  setUp(() {
    verifyPinCubit = MockVerifyPinCubit();

    when(() => verifyPinCubit.state).thenReturn(const VerifyPinState());
    when(() => verifyPinCubit.checkBiometricAvailability()).thenAnswer((_) => Future.value());
  });

  void setupDependencyInjection() {
    final getIt = GetIt.instance;
    final biometricService = MockBiometricService();
    when(() => biometricService.canUse()).thenAnswer((_) => Future.value(false));
    getIt.registerSingleton<BiometricService>(biometricService);
    getIt.registerSingleton<SecureStorage>(MockSecureStorage());
    getIt.registerSingleton<PinAuthCubit>(pinAuthCubit);
  }

  setUpAll(() {
    pinAuthCubit = MockPinAuthCubit();
    when(() => pinAuthCubit.state).thenReturn(const PinAuthState());
    when(() => pinAuthCubit.onPinVerified()).thenAnswer((_) => Future.value());
    setupDependencyInjection();
  });

  tearDownAll(() async => await GetIt.instance.reset());

  Widget buildSubject(Widget child) {
    return MultiBlocProvider(
      providers: [
        BlocProvider.value(value: verifyPinCubit),
      ],
      child: child,
    );
  }

  group('$VerifyPinPage', () {
    testWidgets('renders $VerifyPinView', (tester) async {
      await tester.pumpApp(VerifyPinPage(onAuthenticated: onAuthenticated));

      expect(find.byType(VerifyPinView), findsOne);
    });
  });

  group('${VerifyPinPage.appLock()}', () {
    testWidgets('renders $VerifyPinView with TextButton', (tester) async {
      await tester.pumpApp(VerifyPinPage.appLock());

      expect(find.byType(VerifyPinView), findsOne);
      expect(find.byType(TextButton), findsOne);
    });
  });

  group('$VerifyPinView', () {
    testWidgets('is initially correctly rendered', (tester) async {
      when(() => verifyPinCubit.state).thenReturn(const VerifyPinState());

      await tester.pumpApp(
        buildSubject(VerifyPinView(onAuthenticated: onAuthenticated)),
      );

      expect(find.text(S.current.pinVerify), findsOne);
      expect(find.text(S.current.pinVerifyDescription), findsOne);

      expect(find.byType(PinIndicator), findsOne);
      expect((tester.widget(find.byType(Visibility)) as Visibility).visible, isFalse);
      expect(find.byType(NumberPad), findsOne);
    });

    testWidgets('shows error message when pin is incorrect', (tester) async {
      when(() => verifyPinCubit.state).thenReturn(const VerifyPinFailure());

      await tester.pumpApp(
        buildSubject(VerifyPinView(onAuthenticated: onAuthenticated)),
      );

      expect((tester.widget(find.byType(Visibility)) as Visibility).visible, isTrue);
    });

    group('$BlocListener', () {
      testWidgets('triggers onPinVerified if verification is successful', (tester) async {
        whenListen(
          verifyPinCubit,
          Stream.fromIterable([
            const VerifyPinSuccess(),
          ]),
          initialState: const VerifyPinState(),
        );

        await tester.pumpApp(
          buildSubject(VerifyPinView(onAuthenticated: getIt<PinAuthCubit>().onPinVerified)),
        );
        await tester.pump();

        verify(() => pinAuthCubit.onPinVerified()).called(1);
      });
    });
  });
}
