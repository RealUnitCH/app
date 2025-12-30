import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:mocktail/mocktail.dart';
import 'package:realunit_wallet/packages/service/dfx/dfx_country_service.dart';
import 'package:realunit_wallet/packages/service/dfx/dfx_registration_service.dart';
import 'package:realunit_wallet/packages/service/dfx/models/registration/dfx_registration_status.dart';
import 'package:realunit_wallet/screens/registration/cubits/registration_step/registration_step_cubit.dart';
import 'package:realunit_wallet/screens/registration/cubits/registration_submit/registration_submit_cubit.dart';
import 'package:realunit_wallet/screens/registration/registration_page.dart';
import 'package:realunit_wallet/screens/registration/steps/registration_address_step.dart';
import 'package:realunit_wallet/screens/registration/steps/registration_completed_step.dart';
import 'package:realunit_wallet/screens/registration/steps/registration_personal_step.dart';

import '../../helper/helper.dart';

class MockRegistrationStepCubit extends MockCubit<RegistrationStepState>
    implements RegistrationStepCubit {}

class MockRegistrationSubmitCubit extends MockCubit<RegistrationSubmitState>
    implements RegistrationSubmitCubit {}

class MockDfxRegistrationService extends Mock implements DfxRegistrationService {}

class MockDfxCountryService extends Mock implements DfxCountryService {}

void main() {
  late RegistrationStepCubit registrationStepCubit;
  late RegistrationSubmitCubit registrationSubmitCubit;

  setUp(() {
    registrationStepCubit = MockRegistrationStepCubit();
    registrationSubmitCubit = MockRegistrationSubmitCubit();

    when(() => registrationStepCubit.state)
        .thenReturn(const RegistrationStepState(RegistrationStep.personal));
    when(() => registrationSubmitCubit.state).thenReturn(RegistrationSubmitInitial());
  });

  void setupDependencyInjection() {
    final getIt = GetIt.instance;
    getIt.registerSingleton<DfxRegistrationService>(MockDfxRegistrationService());
    getIt.registerSingleton<DfxCountryService>(MockDfxCountryService());
  }

  setUpAll(() {
    setupDependencyInjection();
  });

  tearDownAll(() async => await GetIt.instance.reset());

  Widget buildSubject(Widget child) {
    return MultiBlocProvider(
      providers: [
        BlocProvider.value(value: registrationStepCubit),
        BlocProvider.value(value: registrationSubmitCubit),
      ],
      child: child,
    );
  }

  group('$RegistrationPage', () {
    testWidgets('renders $RegistrationView', (tester) async {
      await tester.pumpApp(RegistrationPage());

      expect(find.byType(RegistrationView), findsOne);
    });
  });

  group('$RegistrationView', () {
    testWidgets('renders initially $RegistrationPersonalStep', (tester) async {
      final state = const RegistrationStepState(RegistrationStep.personal);
      when(() => registrationStepCubit.state).thenReturn(state);

      await tester.pumpApp(buildSubject(RegistrationView()));

      (tester.widget(find.byType(PageView)) as PageView).controller?.jumpToPage(state.index);
      await tester.pump();

      expect(
        (tester.widget(find.byType(LinearProgressIndicator)) as LinearProgressIndicator).value,
        state.progress,
      );
      expect(find.byType(RegistrationPersonalStep).hitTestable(), findsOne);
    });

    testWidgets('renders $RegistrationAddressStep', (tester) async {
      final state = const RegistrationStepState(RegistrationStep.address);
      when(() => registrationStepCubit.state).thenReturn(state);

      await tester.pumpApp(buildSubject(RegistrationView()));

      (tester.widget(find.byType(PageView)) as PageView).controller?.jumpToPage(state.index);
      await tester.pump();

      expect(
        (tester.widget(find.byType(LinearProgressIndicator)) as LinearProgressIndicator).value,
        state.progress,
      );
      expect(find.byType(RegistrationAddressStep), findsOne);
    });

    testWidgets('renders $RegistrationCompletedStep', (tester) async {
      final state = const RegistrationStepState(RegistrationStep.completed);
      when(() => registrationStepCubit.state).thenReturn(state);

      await tester.pumpApp(buildSubject(RegistrationView()));

      (tester.widget(find.byType(PageView)) as PageView).controller?.jumpToPage(state.index);
      await tester.pump();

      expect(
        (tester.widget(find.byType(LinearProgressIndicator)) as LinearProgressIndicator).value,
        state.progress,
      );
      expect(find.byType(RegistrationCompletedStep), findsOne);
    });

    testWidgets('renders loading state above the PageView when submitting loads', (tester) async {
      when(() => registrationSubmitCubit.state).thenReturn(RegistrationSubmitLoading());

      await tester.pumpApp(buildSubject(RegistrationView()));

      expect(find.byType(CircularProgressIndicator), findsOne);
    });
  });

  group('$BlocListener', () {
    testWidgets('triggers next if submitting successes', (tester) async {
      whenListen(
        registrationSubmitCubit,
        Stream.fromIterable([RegistrationSubmitSuccess(DfxRegistrationStatus.completed)]),
        initialState: RegistrationSubmitInitial(),
      );

      await tester.pumpApp(buildSubject(RegistrationView()));
      await tester.pump();

      verify(() => registrationStepCubit.next()).called(1);
    });

    testWidgets('shows SnackBar if submitting fails', (tester) async {
      whenListen(
        registrationSubmitCubit,
        Stream.fromIterable([RegistrationSubmitFailure('fail')]),
        initialState: RegistrationSubmitInitial(),
      );

      await tester.pumpApp(buildSubject(RegistrationView()));
      await tester.pump();

      expect(find.byType(SnackBar), findsOne);
    });
  });
}
