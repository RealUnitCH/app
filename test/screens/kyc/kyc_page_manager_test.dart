import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:realunit_wallet/packages/service/app_store.dart';
import 'package:realunit_wallet/packages/service/dfx/dfx_kyc_service.dart';
import 'package:realunit_wallet/packages/service/dfx/models/kyc/dto/kyc_level_dto.dart';
import 'package:realunit_wallet/packages/service/dfx/models/kyc/dto/kyc_session_dto.dart';
import 'package:realunit_wallet/packages/service/dfx/models/kyc/dto/kyc_step_dto.dart';
import 'package:realunit_wallet/packages/service/dfx/models/kyc/kyc_level.dart';
import 'package:realunit_wallet/packages/service/dfx/models/user/dto/user_dto.dart';
import 'package:realunit_wallet/packages/service/dfx/models/wallet/real_unit_registration_info_dto.dart';
import 'package:realunit_wallet/packages/service/dfx/models/wallet/real_unit_registration_state.dart';
import 'package:realunit_wallet/packages/service/dfx/real_unit_registration_service.dart';
import 'package:realunit_wallet/packages/wallet/wallet.dart';
import 'package:realunit_wallet/screens/kyc/cubits/kyc/kyc_cubit.dart';
import 'package:realunit_wallet/screens/kyc/kyc_page_manager.dart';
import 'package:realunit_wallet/screens/kyc/subpages/kyc_failure_page.dart';
import 'package:realunit_wallet/screens/kyc/subpages/kyc_loading_page.dart';
import 'package:realunit_wallet/screens/kyc/subpages/kyc_pending_page.dart';

import '../../helper/helper.dart';

class _MockDfxKycService extends Mock implements DfxKycService {}

class _MockRealUnitRegistrationService extends Mock
    implements RealUnitRegistrationService {}

class _MockAppStore extends Mock implements AppStore {}

class _MockAWallet extends Mock implements AWallet {}

class _MockKycCubit extends MockCubit<KycState> implements KycCubit {}

UserKycDto _kycHeader({KycLevel level = KycLevel.level0}) =>
    UserKycDto(hash: 'h', level: level, dataComplete: false);

UserDto _user({String? mail = 'test@example.com'}) =>
    UserDto(mail: mail, kyc: _kycHeader());

KycLevelDto _kycStatus({
  required KycLevel level,
  List<KycStepDto> steps = const [],
  KycProcessStatus processStatus = KycProcessStatus.inProgress,
}) => KycLevelDto(kycLevel: level, kycSteps: steps, processStatus: processStatus);

KycSessionDto _session({
  required KycLevel level,
  required List<KycStepDto> steps,
  KycStepSessionDto? currentStep,
  KycProcessStatus processStatus = KycProcessStatus.inProgress,
}) => KycSessionDto(
  kycLevel: level,
  kycSteps: steps,
  currentStep: currentStep,
  processStatus: processStatus,
);

KycStepSessionDto _currentStep(
  KycStepName name, {
  String url = 'https://example.com/session',
  UrlType urlType = UrlType.browser,
  KycStepStatus status = KycStepStatus.inProgress,
}) => KycStepSessionDto(
  session: KycSessionInfoDto(url: url, type: urlType),
  name: name,
  status: status,
  sequenceNumber: 0,
  isCurrent: true,
);

void main() {
  group('$KycViewManager (mocked cubit)', () {
    late KycCubit kycCubit;

    setUp(() {
      kycCubit = _MockKycCubit();
    });

    Future<void> pumpManager(WidgetTester tester, KycState state) async {
      when(() => kycCubit.state).thenReturn(state);
      await tester.pumpApp(
        BlocProvider<KycCubit>.value(
          value: kycCubit,
          child: const KycViewManager(),
        ),
      );
    }

    // #610 F2: KycInitial is the pre-checkKyc() seed state. It must render the
    // loading page, never fall through to the diagnostic catch-all that would
    // flash "Unhandled KYC state: KycInitial" on the very first frame.
    testWidgets('KycInitial renders the loading page, not the failure fallback',
        (tester) async {
      await pumpManager(tester, const KycInitial());

      expect(find.byType(KycLoadingPage), findsOneWidget);
      expect(find.byType(KycFailurePage), findsNothing);
    });

    testWidgets('KycLoading renders the loading page', (tester) async {
      await pumpManager(tester, const KycLoading());

      expect(find.byType(KycLoadingPage), findsOneWidget);
      expect(find.byType(KycFailurePage), findsNothing);
    });
  });

  group('KycViewManager (real cubit integration)', () {
    late _MockDfxKycService kycService;
    late _MockRealUnitRegistrationService registrationService;
    late _MockAppStore appStore;
    late _MockAWallet wallet;

    setUp(() {
      kycService = _MockDfxKycService();
      registrationService = _MockRealUnitRegistrationService();
      appStore = _MockAppStore();
      wallet = _MockAWallet();
      when(() => appStore.wallet).thenReturn(wallet);
      when(() => wallet.walletType).thenReturn(WalletType.software);
      when(() => registrationService.getRegistrationInfo()).thenAnswer(
        (_) async => RealUnitRegistrationInfoDto(
          state: RealUnitRegistrationState.alreadyRegistered,
        ),
      );
    });

    // An in-progress `dfxApproval` step used to land on a blank white Scaffold
    // (the `(_) => const Scaffold()` fallback in KycViewManager). It must render
    // the existing pending page instead.
    testWidgets(
      'KycSuccess(dfxApproval) renders KycPendingPage, not a blank Scaffold',
      (tester) async {
        when(() => kycService.getKycStatus()).thenAnswer(
          (_) async => _kycStatus(
            level: KycLevel.level50,
            processStatus: KycProcessStatus.inProgress,
          ),
        );
        when(() => kycService.getUser()).thenAnswer((_) async => _user());
        when(() => kycService.continueKyc()).thenAnswer(
          (_) async => _session(
            level: KycLevel.level50,
            steps: const [],
            currentStep: _currentStep(KycStepName.dfxApproval),
          ),
        );

        final cubit = KycCubit(kycService, registrationService, appStore);
        await tester.pumpApp(
          BlocProvider<KycCubit>.value(
            value: cubit,
            child: const KycViewManager(),
          ),
        );

        cubit.markLegalDisclaimerAccepted();
        await cubit.checkKyc();
        await tester.pumpAndSettle();

        // Sanity: the cubit really reached the bug-triggering state.
        expect(cubit.state, isA<KycSuccess>());
        expect((cubit.state as KycSuccess).currentStep, KycStep.dfxApproval);

        // Regression assertion: the pending page renders (not a blank screen).
        expect(find.byType(KycPendingPage), findsOneWidget);

        await cubit.close();
      },
    );
  });
}
