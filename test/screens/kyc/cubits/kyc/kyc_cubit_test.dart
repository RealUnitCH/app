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

UserDto _user({String? mail = 'test@example.com'}) => UserDto(mail: mail, kyc: _kycHeader());

KycStepDto _step(
  KycStepName name, {
  KycStepStatus status = KycStepStatus.notStarted,
  KycStepReason? reason,
  bool isCurrent = false,
  int sequenceNumber = 0,
}) => KycStepDto(
  name: name,
  status: status,
  reason: reason,
  sequenceNumber: sequenceNumber,
  isCurrent: isCurrent,
);

KycLevelDto _kycStatus({
  required KycLevel level,
  List<KycStepDto> steps = const [],
}) => KycLevelDto(kycLevel: level, kycSteps: steps);

KycSessionDto _session({
  required KycLevel level,
  required List<KycStepDto> steps,
  KycStepSessionDto? currentStep,
}) => KycSessionDto(kycLevel: level, kycSteps: steps, currentStep: currentStep);

void main() {
  late DfxKycService kycService;
  late RealUnitRegistrationService registrationService;

  setUp(() {
    kycService = _MockDfxKycService();
    registrationService = _MockRealUnitRegistrationService();
  });

  KycCubit buildCubit({int? requiredLevel}) =>
      KycCubit(kycService, registrationService, requiredLevel: requiredLevel);

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
          // Second pass — backend still hasn't bumped level; the recursion
          // guard should emit KycSuccess(email) instead of looping.
          (_) async => RegistrationEmailStatus.emailRegistered,
        );
      },
      build: buildCubit,
      act: (cubit) => cubit.checkKyc(),
      expect: () => [
        // First pass enters _runCheckKyc → KycLoading, then attempts
        // registerEmail and recurses. The recursive call's KycLoading is
        // deduped by bloc (state unchanged). On the second pass
        // _emailRegistrationAttempted is true and the guard surfaces email.
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
      'emits KycSuccess(registration) when disclaimer accepted but BitBox not confirmed',
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
      'emits KycAccountMergeRequested when level < required and merge step present',
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
        cubit.markBitboxConfirmed();
        await cubit.checkKyc();
      },
      expect: () => [
        const KycLoading(),
        const KycAccountMergeRequested(),
      ],
    );

    blocTest<KycCubit, KycState>(
      'emits KycPending when a required step is inReview',
      setUp: () {
        when(() => kycService.getKycStatus()).thenAnswer(
          (_) async => _kycStatus(
            level: KycLevel.level20,
            steps: [
              _step(KycStepName.ident, status: KycStepStatus.inReview),
            ],
          ),
        );
        when(() => kycService.getUser()).thenAnswer((_) async => _user());
      },
      build: buildCubit,
      act: (cubit) async {
        cubit.markLegalDisclaimerAccepted();
        cubit.markBitboxConfirmed();
        await cubit.checkKyc();
      },
      expect: () => [
        const KycLoading(),
        const KycPending(KycStep.ident),
      ],
    );

    blocTest<KycCubit, KycState>(
      'emits KycPending(dfxApproval) when dfxApproval is the inReview step',
      setUp: () {
        when(() => kycService.getKycStatus()).thenAnswer(
          (_) async => _kycStatus(
            level: KycLevel.level20,
            steps: [
              _step(KycStepName.dfxApproval, status: KycStepStatus.inReview),
            ],
          ),
        );
        when(() => kycService.getUser()).thenAnswer((_) async => _user());
      },
      build: buildCubit,
      act: (cubit) async {
        cubit.markLegalDisclaimerAccepted();
        cubit.markBitboxConfirmed();
        await cubit.checkKyc();
      },
      expect: () => [const KycLoading(), const KycPending(KycStep.dfxApproval)],
    );

    blocTest<KycCubit, KycState>(
      'calls _continueKyc and emits KycSuccess(currentStep) when level < required and no pending step',
      setUp: () {
        when(() => kycService.getKycStatus()).thenAnswer(
          (_) async => _kycStatus(level: KycLevel.level20),
        );
        when(() => kycService.getUser()).thenAnswer((_) async => _user());
        when(() => kycService.continueKyc()).thenAnswer(
          (_) async => _session(
            level: KycLevel.level20,
            steps: [
              _step(KycStepName.ident, isCurrent: true),
            ],
          ),
        );
      },
      build: buildCubit,
      act: (cubit) async {
        cubit.markLegalDisclaimerAccepted();
        cubit.markBitboxConfirmed();
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
          (_) async => _kycStatus(level: KycLevel.level20),
        );
        when(() => kycService.getUser()).thenAnswer((_) async => _user());
        when(() => kycService.continueKyc()).thenAnswer(
          (_) async => _session(
            level: KycLevel.level20,
            steps: [
              _step(KycStepName.personalData, isCurrent: true),
            ],
          ),
        );
      },
      build: buildCubit,
      act: (cubit) async {
        cubit.markLegalDisclaimerAccepted();
        cubit.markBitboxConfirmed();
        await cubit.checkKyc();
      },
      expect: () => [
        const KycLoading(),
        const KycUnsupportedStepFailure(KycStepName.personalData),
      ],
    );

    blocTest<KycCubit, KycState>(
      'emits KycCompleted when level >= required and gates have passed',
      setUp: () {
        when(() => kycService.getKycStatus()).thenAnswer(
          (_) async => _kycStatus(level: KycLevel.level30),
        );
        when(() => kycService.getUser()).thenAnswer((_) async => _user());
      },
      build: buildCubit,
      act: (cubit) async {
        cubit.markLegalDisclaimerAccepted();
        cubit.markBitboxConfirmed();
        await cubit.checkKyc();
      },
      expect: () => [const KycLoading(), const KycCompleted()],
    );

    blocTest<KycCubit, KycState>(
      'returning user at level >= required still routes through the BitBox gate first',
      setUp: () {
        when(() => kycService.getKycStatus()).thenAnswer(
          (_) async => _kycStatus(level: KycLevel.level50),
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
      'routes to twoFa step on ApiException(statusCode: 403)',
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
        const KycSuccess(currentStep: KycStep.twoFa),
      ],
    );

    blocTest<KycCubit, KycState>(
      "routes to twoFa step on ApiException(code: 'TFA_REQUIRED')",
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

    blocTest<KycCubit, KycState>(
      'honours custom requiredLevel: level 20 with required 10 → KycCompleted',
      setUp: () {
        when(() => kycService.getKycStatus()).thenAnswer(
          (_) async => _kycStatus(level: KycLevel.level20),
        );
        when(() => kycService.getUser()).thenAnswer((_) async => _user());
      },
      build: () => buildCubit(requiredLevel: 10),
      act: (cubit) async {
        cubit.markLegalDisclaimerAccepted();
        cubit.markBitboxConfirmed();
        await cubit.checkKyc();
      },
      expect: () => [const KycLoading(), const KycCompleted()],
    );
  });

  group('$KycCubit timeout & generation handling', () {
    test(
      'a late response from a timed-out call does NOT overwrite the fresh state of a retry (regression for #315 / #317)',
      () async {
        // Call 1: getKycStatus hangs forever — the cubit's 30 s outer timeout
        // would normally fire, but in tests we use `fakeAsync`-style time
        // skipping is overkill here; instead we await call 1 with a tight
        // outer timeout via Future.any and immediately fire call 2.
        // The contract under test: when call 1's late response finally
        // resolves, it must NOT emit further state because the generation
        // counter has moved on.

        final call1Completer = Completer<KycLevelDto>();
        var firstCall = true;
        when(() => kycService.getKycStatus()).thenAnswer((_) {
          if (firstCall) {
            firstCall = false;
            return call1Completer.future;
          }
          return Future.value(_kycStatus(level: KycLevel.level30));
        });
        when(() => kycService.getUser()).thenAnswer((_) async => _user());

        final cubit = KycCubit(kycService, registrationService)
          ..markLegalDisclaimerAccepted()
          ..markBitboxConfirmed();

        final states = <KycState>[];
        final sub = cubit.stream.listen(states.add);

        // Fire call 1 but don't await it — its outer .timeout(30s) won't fire
        // in a unit test, so we simulate the timeout-and-retry race by
        // starting call 2 before call 1 resolves.
        final call1Future = cubit.checkKyc();

        // Yield to let call 1 emit KycLoading and reach the Future.wait await.
        await Future<void>.delayed(Duration.zero);

        // Call 2 — fresh response.
        await cubit.checkKyc();

        // Now resolve call 1's hanging response. Its post-await guard must
        // detect the generation mismatch and bail without emitting.
        call1Completer.complete(_kycStatus(level: KycLevel.level30));
        await call1Future;
        await Future<void>.delayed(Duration.zero);

        await sub.cancel();
        await cubit.close();

        // Call 1 emits KycLoading. Call 2's KycLoading is deduped by bloc
        // (state already KycLoading). Call 2 then emits KycCompleted on the
        // fresh response. Call 1's late response must be dropped by the
        // generation guard — no extra state after KycCompleted, and the
        // final state must be the fresh KycCompleted.
        expect(states, [const KycLoading(), const KycCompleted()]);
        expect(cubit.state, const KycCompleted());
      },
    );

    blocTest<KycCubit, KycState>(
      'emits KycFailure when a backend call throws TimeoutException '
      '(proxy for the outer 30 s `.timeout()` firing — FakeAsync is not wired '
      'into this repo yet)',
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

  group('$KycCubit markLegalDisclaimerAccepted / markBitboxConfirmed', () {
    blocTest<KycCubit, KycState>(
      'progresses past the BitBox gate once both marks are set',
      setUp: () {
        when(() => kycService.getKycStatus()).thenAnswer(
          (_) async => _kycStatus(level: KycLevel.level30),
        );
        when(() => kycService.getUser()).thenAnswer((_) async => _user());
      },
      build: buildCubit,
      act: (cubit) async {
        await cubit.checkKyc(); // expects legalDisclaimer
        cubit.markLegalDisclaimerAccepted();
        await cubit.checkKyc(); // expects registration (BitBox gate)
        cubit.markBitboxConfirmed();
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
