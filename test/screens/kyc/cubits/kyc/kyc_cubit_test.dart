import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:realunit_wallet/packages/service/dfx/dfx_kyc_service.dart';
import 'package:realunit_wallet/packages/service/dfx/exceptions/api_exception.dart';
import 'package:realunit_wallet/packages/service/dfx/models/kyc/dto/kyc_level_dto.dart';
import 'package:realunit_wallet/packages/service/dfx/models/kyc/dto/kyc_session_dto.dart';
import 'package:realunit_wallet/packages/service/dfx/models/kyc/dto/kyc_step_dto.dart';
import 'package:realunit_wallet/packages/service/dfx/models/kyc/kyc_level.dart';
import 'package:realunit_wallet/packages/service/dfx/models/registration/registration_email_status.dart';
import 'package:realunit_wallet/packages/service/dfx/models/user/dto/user_dto.dart';
import 'package:realunit_wallet/packages/service/dfx/real_unit_registration_service.dart';
import 'package:realunit_wallet/screens/kyc/cubits/kyc/kyc_cubit.dart';

class _MockDfxKycService extends Mock implements DfxKycService {}

class _MockRealUnitRegistrationService extends Mock implements RealUnitRegistrationService {}

UserKycDto _kycHeader({KycLevel level = KycLevel.level0}) =>
    UserKycDto(hash: 'h', level: level, dataComplete: false);

UserDto _user({
  String? mail = 'test@example.com',
  KycLevel headerLevel = KycLevel.level0,
}) => UserDto(
  mail: mail,
  kyc: _kycHeader(level: headerLevel),
);

KycStepDto _step(
  KycStepName name, {
  KycStepStatus status = KycStepStatus.notStarted,
  KycStepReason? reason,
  bool isCurrent = false,
  bool isRequired = false,
  int sequenceNumber = 0,
}) => KycStepDto(
  name: name,
  status: status,
  reason: reason,
  sequenceNumber: sequenceNumber,
  isCurrent: isCurrent,
  isRequired: isRequired,
);

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

void main() {
  late DfxKycService kycService;
  late RealUnitRegistrationService registrationService;

  setUp(() {
    kycService = _MockDfxKycService();
    registrationService = _MockRealUnitRegistrationService();
  });

  KycCubit buildCubit() => KycCubit(kycService, registrationService);

  group('$KycCubit checkKyc', () {
    blocTest<KycCubit, KycState>(
      'emits KycSuccess(email) when user has no email',
      setUp: () {
        when(() => kycService.getKycStatus()).thenAnswer(
          (_) async => _kycStatus(level: KycLevel.level0),
        );
        when(() => kycService.getUser()).thenAnswer((_) async => _user(mail: null));
      },
      build: buildCubit,
      act: (cubit) => cubit.checkKyc(),
      expect: () => [
        const KycLoading(),
        const KycSuccess(currentStep: KycStep.email),
      ],
    );

    blocTest<KycCubit, KycState>(
      'auto-registers email when mail exists but level < 10, then recurses',
      setUp: () {
        when(() => kycService.getKycStatus()).thenAnswer(
          (_) async => _kycStatus(level: KycLevel.level0),
        );
        when(() => kycService.getUser()).thenAnswer((_) async => _user());
        when(() => registrationService.registerEmail(any())).thenAnswer(
          (_) async => RegistrationEmailStatus.emailRegistered,
        );
      },
      build: buildCubit,
      act: (cubit) => cubit.checkKyc(),
      expect: () => [
        const KycLoading(),
        const KycSuccess(currentStep: KycStep.email),
      ],
      verify: (_) {
        verify(() => registrationService.registerEmail('test@example.com')).called(1);
      },
    );

    blocTest<KycCubit, KycState>(
      'emits KycSuccess(legalDisclaimer) when disclaimer not yet accepted',
      setUp: () {
        when(() => kycService.getKycStatus()).thenAnswer(
          (_) async => _kycStatus(level: KycLevel.level20),
        );
        when(() => kycService.getUser()).thenAnswer((_) async => _user());
      },
      build: buildCubit,
      act: (cubit) => cubit.checkKyc(),
      expect: () => [
        const KycLoading(),
        const KycSuccess(currentStep: KycStep.legalDisclaimer),
      ],
    );

    blocTest<KycCubit, KycState>(
      'emits KycSuccess(registration) when disclaimer accepted but registration sign not yet produced',
      setUp: () {
        when(() => kycService.getKycStatus()).thenAnswer(
          (_) async => _kycStatus(level: KycLevel.level20),
        );
        when(() => kycService.getUser()).thenAnswer((_) async => _user());
      },
      build: buildCubit,
      act: (cubit) async {
        cubit.markLegalDisclaimerAccepted();
        await cubit.checkKyc();
      },
      expect: () => [
        const KycLoading(),
        const KycSuccess(currentStep: KycStep.registration),
      ],
    );

    blocTest<KycCubit, KycState>(
      'emits KycAccountMergeRequested when any step carries the accountMergeRequested reason',
      setUp: () {
        when(() => kycService.getKycStatus()).thenAnswer(
          (_) async => _kycStatus(
            level: KycLevel.level20,
            steps: [
              _step(
                KycStepName.contactData,
                reason: KycStepReason.accountMergeRequested,
              ),
            ],
          ),
        );
        when(() => kycService.getUser()).thenAnswer((_) async => _user());
      },
      build: buildCubit,
      act: (cubit) async {
        cubit.markLegalDisclaimerAccepted();
        cubit.markRegistrationSignProduced();
        await cubit.checkKyc();
      },
      expect: () => [
        const KycLoading(),
        const KycAccountMergeRequested(),
      ],
    );

    // From here on the routing is API-driven via `processStatus` —
    // the cubit no longer iterates `kycSteps` to derive completion or
    // pendingness.
    blocTest<KycCubit, KycState>(
      'emits KycCompleted when API reports processStatus=Completed',
      setUp: () {
        when(() => kycService.getKycStatus()).thenAnswer(
          (_) async => _kycStatus(
            level: KycLevel.level50,
            processStatus: KycProcessStatus.completed,
          ),
        );
        when(() => kycService.getUser()).thenAnswer((_) async => _user());
      },
      build: buildCubit,
      act: (cubit) async {
        cubit.markLegalDisclaimerAccepted();
        cubit.markRegistrationSignProduced();
        await cubit.checkKyc();
      },
      expect: () => [const KycLoading(), const KycCompleted()],
    );

    blocTest<KycCubit, KycState>(
      'emits KycPending(ident) when API reports processStatus=PendingReview and ident is the required pending step',
      setUp: () {
        when(() => kycService.getKycStatus()).thenAnswer(
          (_) async => _kycStatus(
            level: KycLevel.level50,
            processStatus: KycProcessStatus.pendingReview,
            steps: [
              _step(KycStepName.ident, status: KycStepStatus.inReview, isRequired: true),
            ],
          ),
        );
        when(() => kycService.getUser()).thenAnswer((_) async => _user());
      },
      build: buildCubit,
      act: (cubit) async {
        cubit.markLegalDisclaimerAccepted();
        cubit.markRegistrationSignProduced();
        await cubit.checkKyc();
      },
      expect: () => [const KycLoading(), const KycPending(KycStep.ident)],
    );

    blocTest<KycCubit, KycState>(
      'emits KycPending(dfxApproval) when dfxApproval is the only required step in PendingReview',
      setUp: () {
        when(() => kycService.getKycStatus()).thenAnswer(
          (_) async => _kycStatus(
            level: KycLevel.level50,
            processStatus: KycProcessStatus.pendingReview,
            steps: [
              _step(KycStepName.dfxApproval, status: KycStepStatus.inReview, isRequired: true),
            ],
          ),
        );
        when(() => kycService.getUser()).thenAnswer((_) async => _user());
      },
      build: buildCubit,
      act: (cubit) async {
        cubit.markLegalDisclaimerAccepted();
        cubit.markRegistrationSignProduced();
        await cubit.checkKyc();
      },
      expect: () => [const KycLoading(), const KycPending(KycStep.dfxApproval)],
    );

    blocTest<KycCubit, KycState>(
      'calls _continueKyc and emits KycSuccess(currentStep) when processStatus=InProgress',
      setUp: () {
        when(() => kycService.getKycStatus()).thenAnswer(
          (_) async => _kycStatus(
            level: KycLevel.level20,
            processStatus: KycProcessStatus.inProgress,
          ),
        );
        when(() => kycService.getUser()).thenAnswer((_) async => _user());
        when(() => kycService.continueKyc()).thenAnswer(
          (_) async => _session(
            level: KycLevel.level20,
            steps: [_step(KycStepName.ident, isCurrent: true)],
          ),
        );
      },
      build: buildCubit,
      act: (cubit) async {
        cubit.markLegalDisclaimerAccepted();
        cubit.markRegistrationSignProduced();
        await cubit.checkKyc();
      },
      expect: () => [
        const KycLoading(),
        const KycSuccess(currentStep: KycStep.ident),
      ],
    );

    blocTest<KycCubit, KycState>(
      'emits KycUnsupportedStepFailure when _continueKyc currentStep has no UI mapping',
      setUp: () {
        when(() => kycService.getKycStatus()).thenAnswer(
          (_) async => _kycStatus(
            level: KycLevel.level20,
            processStatus: KycProcessStatus.inProgress,
          ),
        );
        when(() => kycService.getUser()).thenAnswer((_) async => _user());
        when(() => kycService.continueKyc()).thenAnswer(
          (_) async => _session(
            level: KycLevel.level20,
            steps: [_step(KycStepName.personalData, isCurrent: true)],
          ),
        );
      },
      build: buildCubit,
      act: (cubit) async {
        cubit.markLegalDisclaimerAccepted();
        cubit.markRegistrationSignProduced();
        await cubit.checkKyc();
      },
      expect: () => [
        const KycLoading(),
        const KycUnsupportedStepFailure(KycStepName.personalData),
      ],
    );

    blocTest<KycCubit, KycState>(
      'emits KycFailure when API reports processStatus=Failed (KYC terminated)',
      setUp: () {
        when(() => kycService.getKycStatus()).thenAnswer(
          (_) async => _kycStatus(
            level: KycLevel.terminated,
            processStatus: KycProcessStatus.failed,
          ),
        );
        when(() => kycService.getUser()).thenAnswer((_) async => _user());
      },
      build: buildCubit,
      act: (cubit) async {
        cubit.markLegalDisclaimerAccepted();
        cubit.markRegistrationSignProduced();
        await cubit.checkKyc();
      },
      expect: () => [const KycLoading(), isA<KycFailure>()],
    );

    blocTest<KycCubit, KycState>(
      'returning user at completed processStatus still routes through the sign gate first',
      setUp: () {
        when(() => kycService.getKycStatus()).thenAnswer(
          (_) async => _kycStatus(
            level: KycLevel.level50,
            processStatus: KycProcessStatus.completed,
          ),
        );
        when(() => kycService.getUser()).thenAnswer((_) async => _user());
      },
      build: buildCubit,
      act: (cubit) async {
        cubit.markLegalDisclaimerAccepted();
        await cubit.checkKyc();
      },
      expect: () => [
        const KycLoading(),
        const KycSuccess(currentStep: KycStep.registration),
      ],
    );

    blocTest<KycCubit, KycState>(
      'does NOT route to twoFa on 403 without TFA_REQUIRED body code',
      setUp: () {
        when(() => kycService.getKycStatus()).thenThrow(
          const ApiException(statusCode: 403, code: 'FORBIDDEN', message: ''),
        );
        when(() => kycService.getUser()).thenAnswer((_) async => _user());
      },
      build: buildCubit,
      act: (cubit) => cubit.checkKyc(),
      expect: () => [
        const KycLoading(),
        isA<KycFailure>(),
      ],
    );

    blocTest<KycCubit, KycState>(
      "routes to twoFa step on ApiException(code: 'TFA_REQUIRED'), regardless of HTTP status",
      setUp: () {
        when(() => kycService.getKycStatus()).thenThrow(
          const ApiException(statusCode: 400, code: 'TFA_REQUIRED', message: ''),
        );
        when(() => kycService.getUser()).thenAnswer((_) async => _user());
      },
      build: buildCubit,
      act: (cubit) => cubit.checkKyc(),
      expect: () => [
        const KycLoading(),
        const KycSuccess(currentStep: KycStep.twoFa),
      ],
    );

    blocTest<KycCubit, KycState>(
      "routes to twoFa step on ApiException(statusCode: 403, code: 'TFA_REQUIRED')",
      setUp: () {
        when(() => kycService.getKycStatus()).thenThrow(
          const ApiException(statusCode: 403, code: 'TFA_REQUIRED', message: ''),
        );
        when(() => kycService.getUser()).thenAnswer((_) async => _user());
      },
      build: buildCubit,
      act: (cubit) => cubit.checkKyc(),
      expect: () => [
        const KycLoading(),
        const KycSuccess(currentStep: KycStep.twoFa),
      ],
    );

    blocTest<KycCubit, KycState>(
      'emits KycFailure on unrelated ApiException',
      setUp: () {
        when(() => kycService.getKycStatus()).thenThrow(
          const ApiException(statusCode: 500, code: 'SERVER_ERROR', message: 'boom'),
        );
        when(() => kycService.getUser()).thenAnswer((_) async => _user());
      },
      build: buildCubit,
      act: (cubit) => cubit.checkKyc(),
      expect: () => [
        const KycLoading(),
        isA<KycFailure>(),
      ],
    );

    blocTest<KycCubit, KycState>(
      'emits KycFailure on generic exception',
      setUp: () {
        when(() => kycService.getKycStatus()).thenThrow(Exception('network down'));
        when(() => kycService.getUser()).thenAnswer((_) async => _user());
      },
      build: buildCubit,
      act: (cubit) => cubit.checkKyc(),
      expect: () => [
        const KycLoading(),
        isA<KycFailure>(),
      ],
    );
  });

  group('$KycCubit timeout & generation handling', () {
    test(
      'a late response from a timed-out call does NOT overwrite the fresh state of a retry (regression for #315 / #317)',
      () async {
        final call1Completer = Completer<KycLevelDto>();
        var firstCall = true;
        when(() => kycService.getKycStatus()).thenAnswer((_) {
          if (firstCall) {
            firstCall = false;
            return call1Completer.future;
          }
          return Future.value(
            _kycStatus(level: KycLevel.level50, processStatus: KycProcessStatus.completed),
          );
        });
        when(() => kycService.getUser()).thenAnswer((_) async => _user());

        final cubit = KycCubit(kycService, registrationService)
          ..markLegalDisclaimerAccepted()
          ..markRegistrationSignProduced();

        final states = <KycState>[];
        final sub = cubit.stream.listen(states.add);

        final call1Future = cubit.checkKyc();

        await Future<void>.delayed(Duration.zero);

        await cubit.checkKyc();

        call1Completer.complete(
          _kycStatus(level: KycLevel.level50, processStatus: KycProcessStatus.completed),
        );
        await call1Future;
        await Future<void>.delayed(Duration.zero);

        await sub.cancel();
        await cubit.close();

        expect(states, [const KycLoading(), const KycCompleted()]);
        expect(cubit.state, const KycCompleted());
      },
    );

    blocTest<KycCubit, KycState>(
      'emits KycFailure when a backend call throws TimeoutException',
      setUp: () {
        when(() => kycService.getKycStatus()).thenAnswer(
          (_) async => throw TimeoutException('backend slow'),
        );
        when(() => kycService.getUser()).thenAnswer((_) async => _user());
      },
      build: buildCubit,
      act: (cubit) => cubit.checkKyc(),
      expect: () => [const KycLoading(), isA<KycFailure>()],
    );
  });

  group('$KycCubit markLegalDisclaimerAccepted / markRegistrationSignProduced', () {
    blocTest<KycCubit, KycState>(
      'progresses past the sign gate once both marks are set',
      setUp: () {
        when(() => kycService.getKycStatus()).thenAnswer(
          (_) async => _kycStatus(
            level: KycLevel.level50,
            processStatus: KycProcessStatus.completed,
          ),
        );
        when(() => kycService.getUser()).thenAnswer((_) async => _user());
      },
      build: buildCubit,
      act: (cubit) async {
        await cubit.checkKyc(); // expects legalDisclaimer
        cubit.markLegalDisclaimerAccepted();
        await cubit.checkKyc(); // expects registration (sign gate)
        cubit.markRegistrationSignProduced();
        await cubit.checkKyc(); // expects KycCompleted
      },
      expect: () => [
        const KycLoading(),
        const KycSuccess(currentStep: KycStep.legalDisclaimer),
        const KycLoading(),
        const KycSuccess(currentStep: KycStep.registration),
        const KycLoading(),
        const KycCompleted(),
      ],
    );
  });
}
