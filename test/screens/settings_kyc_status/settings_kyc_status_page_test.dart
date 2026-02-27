import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:mocktail/mocktail.dart';
import 'package:realunit_wallet/packages/service/dfx/dfx_kyc_service.dart';
import 'package:realunit_wallet/packages/service/dfx/models/kyc/kyc_level.dart';
import 'package:realunit_wallet/packages/service/dfx/models/kyc/kyc_status.dart';
import 'package:realunit_wallet/packages/service/dfx/models/kyc/kyc_step.dart';
import 'package:realunit_wallet/screens/settings_kyc_status/cubit/settings_kyc_status_cubit.dart';
import 'package:realunit_wallet/screens/settings_kyc_status/settings_kyc_status_page.dart';

import '../../helper/helper.dart';

class MockSettingsKycStatusCubit extends MockCubit<SettingsKycStatusState>
    implements SettingsKycStatusCubit {}

class MockDfxKycService extends Mock implements DfxKycService {}

void main() {
  late SettingsKycStatusCubit settingsKycStatusCubit;

  setUp(() {
    settingsKycStatusCubit = MockSettingsKycStatusCubit();
    when(() => settingsKycStatusCubit.state).thenReturn(const SettingsKycStatusInitial());
    when(() => settingsKycStatusCubit.getKycStatus()).thenAnswer((_) => Future.value());
  });

  void setupDependencyInjection() {
    final getIt = GetIt.instance;
    getIt.registerSingleton<DfxKycService>(MockDfxKycService());
  }

  setUpAll(() {
    setupDependencyInjection();
  });

  Widget buildSubject(Widget child) {
    return BlocProvider.value(
      value: settingsKycStatusCubit,
      child: child,
    );
  }

  group('$SettingsKycStatusPage', () {
    testWidgets('renders $SettingsKycStatusView', (tester) async {
      await tester.pumpApp(const SettingsKycStatusPage());

      expect(find.byType(SettingsKycStatusView), findsOne);
    });
  });

  group('$SettingsKycStatusView', () {
    testWidgets('renders initially correctly', (tester) async {
      await tester.pumpApp(buildSubject(const SettingsKycStatusView()));

      expect(find.byType(SizedBox), findsOne);
    });

    testWidgets('renders correctly when loading KycStatus', (tester) async {
      when(() => settingsKycStatusCubit.state).thenReturn(const SettingsKycStatusLoading());
      await tester.pumpApp(buildSubject(const SettingsKycStatusView()));

      expect(find.byType(CupertinoActivityIndicator), findsOne);
    });

    testWidgets('renders correctly when loading KycStatus failed', (tester) async {
      final errorMessage = 'not working bro';
      when(() => settingsKycStatusCubit.state).thenReturn(SettingsKycStatusFailure(errorMessage));

      await tester.pumpApp(buildSubject(const SettingsKycStatusView()));

      expect(
        find.byWidgetPredicate((Widget widget) => widget is Text && widget.data == errorMessage),
        findsOne,
      );
    });

    testWidgets('renders correctly when KycStatus loaded successfully', (tester) async {
      final kycSteps = [
        const KycStep(
          name: KycStepName.contactData,
          status: KycStepStatus.notStarted,
          sequenceNumber: 1,
          isCurrent: false,
        ),
        const KycStep(
          name: KycStepName.personalData,
          status: KycStepStatus.notStarted,
          sequenceNumber: 2,
          isCurrent: false,
        ),
      ];
      final kycLevel = KycLevel.level20;

      when(() => settingsKycStatusCubit.state).thenReturn(
        SettingsKycStatusSuccess(
          kycStatus: KycStatus(
            level: kycLevel,
            steps: kycSteps,
          ),
        ),
      );

      await tester.pumpApp(buildSubject(const SettingsKycStatusView()));

      expect(
        find.byWidgetPredicate(
          (Widget widget) => widget is Text && widget.data!.contains('${kycLevel.value}'),
        ),
        findsOne,
      );
      for (var step in kycSteps) {
        expect(
          find.byWidgetPredicate(
            (Widget widget) => widget is Text && widget.data!.contains(step.name.value),
          ),
          findsOne,
        );
      }
      expect(find.byIcon(Icons.info), findsOne);
      expect(find.byType(FilledButton), findsOne);
    });
  });
}
