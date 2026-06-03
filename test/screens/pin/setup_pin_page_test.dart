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
import 'package:realunit_wallet/screens/pin/bloc/setup_pin/setup_pin_cubit.dart';
import 'package:realunit_wallet/screens/pin/constants/pin_constants.dart';
import 'package:realunit_wallet/screens/pin/setup_pin_page.dart';
import 'package:realunit_wallet/widgets/number_pad.dart';

import '../../helper/pump_app.dart';

class MockSetupPinCubit extends MockCubit<SetupPinState> implements SetupPinCubit {}

class MockPinAuthCubit extends MockCubit<PinAuthState> implements PinAuthCubit {}

class MockBiometricService extends Mock implements BiometricService {}

class MockSecureStorage extends Mock implements SecureStorage {}

void main() {
  late SetupPinCubit setupPinCubit;
  late PinAuthCubit pinAuthCubit;

  setUp(() {
    setupPinCubit = MockSetupPinCubit();

    when(() => setupPinCubit.state).thenReturn(const SetupPinState());
    when(() => setupPinCubit.isBiometricAvailable()).thenAnswer((_) => Future.value(false));
  });

  void setupDependencyInjection() {
    final getIt = GetIt.instance;
    getIt.registerSingleton<BiometricService>(MockBiometricService());
    getIt.registerSingleton<SecureStorage>(MockSecureStorage());
    getIt.registerSingleton<PinAuthCubit>(pinAuthCubit);
  }

  setUpAll(() {
    pinAuthCubit = MockPinAuthCubit();
    when(() => pinAuthCubit.state).thenReturn(const PinAuthState());
    when(() => pinAuthCubit.onPinSetupComplete()).thenAnswer((_) => Future<void>.value());
    setupDependencyInjection();
  });

  tearDownAll(() async => await GetIt.instance.reset());

  Widget buildSubject(Widget child) {
    return MultiBlocProvider(
      providers: [
        BlocProvider.value(value: setupPinCubit),
      ],
      child: child,
    );
  }

  group('$SetupPinPage', () {
    testWidgets('renders $SetupPinView', (tester) async {
      await tester.pumpApp(const SetupPinPage());

      expect(find.byType(SetupPinView), findsOne);
    });
  });

  group('$SetupPinView', () {
    group('${SetupPinMode.create}', () {
      testWidgets('is initially correctly rendered', (tester) async {
        when(() => setupPinCubit.state).thenReturn(const SetupPinState(mode: SetupPinMode.create));

        await tester.pumpApp(buildSubject(const SetupPinView()));

        expect((tester.widget(find.byType(AppBar)) as AppBar).leading, isNull);
        expect(find.text(S.current.pinCreate), findsOne);
        expect(find.text(S.current.pinCreateDescription('$pinLength')), findsOne);
        expect(find.byType(NumberPad), findsOne);
      });
    });

    group('${SetupPinMode.confirm}', () {
      testWidgets('is initially correctly rendered', (tester) async {
        when(() => setupPinCubit.state).thenReturn(const SetupPinState(mode: SetupPinMode.confirm));

        await tester.pumpApp(buildSubject(const SetupPinView()));

        expect((tester.widget(find.byType(AppBar)) as AppBar).leading, isNotNull);
        expect((tester.widget(find.byType(Visibility)) as Visibility).visible, isFalse);
        expect(find.text(S.current.pinConfirm), findsOne);
        expect(find.text(S.current.pinConfirmDescription), findsOne);
        expect(find.byType(NumberPad), findsOne);
      });

      testWidgets('shows error message when pin mismatches', (tester) async {
        when(
          () => setupPinCubit.state,
        ).thenReturn(
          const SetupPinState(
            mode: SetupPinMode.confirm,
            mismatch: true,
          ),
        );

        await tester.pumpApp(buildSubject(const SetupPinView()));

        expect((tester.widget(find.byType(Visibility)) as Visibility).visible, isTrue);
      });
    });

    group('$BlocListener', () {
      testWidgets('triggers onPinSetupComplete if setup is complete', (tester) async {
        whenListen(
          setupPinCubit,
          Stream.fromIterable([
            const SetupPinState(isComplete: true),
          ]),
          initialState: const SetupPinState(),
        );

        await tester.pumpApp(buildSubject(const SetupPinView()));
        await tester.pump();

        verify(() => pinAuthCubit.onPinSetupComplete()).called(1);
      });
    });
  });
}
