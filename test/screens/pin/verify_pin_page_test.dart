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
import 'package:realunit_wallet/widgets/number_pad.dart';

import '../../helper/pump_app.dart';

class MockVerifyPinCubit extends MockCubit<VerifyPinState> implements VerifyPinCubit {}

class MockPinAuthCubit extends MockCubit<PinAuthState> implements PinAuthCubit {}

class MockBiometricService extends Mock implements BiometricService {}

class MockSecureStorage extends Mock implements SecureStorage {}

void main() {
  late VerifyPinCubit verifyPinCubit;
  late PinAuthCubit pinAuthCubit;

  setUp(() {
    verifyPinCubit = MockVerifyPinCubit();

    when(() => verifyPinCubit.state).thenReturn(const VerifyPinState(pin: ''));
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
      await tester.pumpApp(const VerifyPinPage());

      expect(find.byType(VerifyPinView), findsOne);
    });
  });

  group('$VerifyPinView', () {
    testWidgets('is initially correctly rendered', (tester) async {
      when(() => verifyPinCubit.state).thenReturn(const VerifyPinState(pin: ''));

      await tester.pumpApp(buildSubject(const VerifyPinView()));

      expect(find.text(S.current.pinVerify), findsOne);
      expect(find.text(S.current.pinVerifyDescription), findsOne);

      expect(find.byType(PinIndicator), findsOne);
      expect((tester.widget(find.byType(Visibility)) as Visibility).visible, isFalse);
      expect(find.byType(NumberPad), findsOne);
      expect(find.byType(TextButton), findsOne);
    });

    testWidgets('shows error message when pin is incorrect', (tester) async {
      when(() => verifyPinCubit.state).thenReturn(const VerifyPinFailure());

      await tester.pumpApp(buildSubject(const VerifyPinView()));

      expect((tester.widget(find.byType(Visibility)) as Visibility).visible, isTrue);
    });

    group('$BlocListener', () {
      testWidgets('triggers onPinVerified if verification is successful', (tester) async {
        whenListen(
          verifyPinCubit,
          Stream.fromIterable([
            const VerifyPinSuccess(),
          ]),
          initialState: const VerifyPinState(pin: ''),
        );

        await tester.pumpApp(buildSubject(const VerifyPinView()));
        await tester.pump();

        verify(() => pinAuthCubit.onPinVerified()).called(1);
      });
    });
  });
}
