import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:realunit_wallet/packages/service/dfx/dfx_kyc_service.dart';
import 'package:realunit_wallet/packages/service/dfx/models/kyc/dto/kyc_level_dto.dart';
import 'package:realunit_wallet/packages/service/dfx/models/kyc/dto/kyc_session_dto.dart';
import 'package:realunit_wallet/packages/service/dfx/models/kyc/dto/kyc_step_dto.dart';
import 'package:realunit_wallet/packages/service/dfx/models/kyc/kyc_level.dart';
import 'package:realunit_wallet/packages/service/dfx/models/user/dto/user_dto.dart';
import 'package:realunit_wallet/packages/service/dfx/real_unit_registration_service.dart';
import 'package:realunit_wallet/screens/kyc/cubits/kyc/kyc_cubit.dart';

class MockDfxKycService extends Mock implements DfxKycService {}

class MockRegistrationService extends Mock implements RealUnitRegistrationService {}

KycStepDto _step(KycStepName name, KycStepStatus status, {bool isCurrent = false}) =>
    KycStepDto(name: name, status: status, sequenceNumber: 0, isCurrent: isCurrent);

UserDto _user(String? mail) => UserDto(
      mail: mail,
      kyc: const UserKycDto(hash: 'h', level: KycLevel.level50, dataComplete: true),
    );

KycSessionDto _session(KycStepDto current) => KycSessionDto(
      kycLevel: KycLevel.level50,
      kycSteps: [current],
      currentStep: KycStepSessionDto(
        session: const KycSessionInfoDto(url: 'https://example/x', type: UrlType.token),
        name: current.name,
        status: current.status,
        sequenceNumber: current.sequenceNumber,
        isCurrent: true,
      ),
    );

void main() {
  late MockDfxKycService kyc;
  late MockRegistrationService reg;

  setUp(() {
    kyc = MockDfxKycService();
    reg = MockRegistrationService();
    when(() => reg.registerEmail(any())).thenAnswer((_) async => throw UnimplementedError());
  });

  KycCubit makeCubit() {
    final c = KycCubit(kyc, reg)
      ..markLegalDisclaimerAccepted()
      ..markBitboxConfirmed();
    addTearDown(c.close);
    return c;
  }

  group('$KycCubit', () {
    test('emits KycCompleted when all required steps are completed', () async {
      when(() => kyc.getKycStatus()).thenAnswer((_) async => KycLevelDto(
            kycLevel: KycLevel.level30,
            kycSteps: [
              _step(KycStepName.contactData, KycStepStatus.completed),
              _step(KycStepName.nationalityData, KycStepStatus.completed),
              _step(KycStepName.ident, KycStepStatus.completed),
              _step(KycStepName.financialData, KycStepStatus.completed),
              _step(KycStepName.dfxApproval, KycStepStatus.completed),
            ],
          ));
      when(() => kyc.getUser()).thenAnswer((_) async => _user('a@b.c'));

      final c = makeCubit();
      await c.checkKyc();
      expect(c.state, isA<KycCompleted>());
    });

    test('does not emit KycCompleted when a required step is failed at high level', () async {
      // Backend can report level >= required while individual required steps
      // are still failed/outdated — the user must redo those.
      when(() => kyc.getKycStatus()).thenAnswer((_) async => KycLevelDto(
            kycLevel: KycLevel.level50,
            kycSteps: [
              _step(KycStepName.contactData, KycStepStatus.completed),
              _step(KycStepName.nationalityData, KycStepStatus.completed),
              _step(KycStepName.ident, KycStepStatus.failed),
              _step(KycStepName.financialData, KycStepStatus.outdated),
              _step(KycStepName.dfxApproval, KycStepStatus.completed),
            ],
          ));
      when(() => kyc.getUser()).thenAnswer((_) async => _user('a@b.c'));
      when(() => kyc.continueKyc()).thenAnswer(
        (_) async =>
            _session(_step(KycStepName.ident, KycStepStatus.notStarted, isCurrent: true)),
      );

      final c = makeCubit();
      await c.checkKyc();
      expect(c.state, isNot(isA<KycCompleted>()));
    });

    test('continues KYC when any required step is unfinished', () async {
      when(() => kyc.getKycStatus()).thenAnswer((_) async => KycLevelDto(
            kycLevel: KycLevel.level50,
            kycSteps: [
              _step(KycStepName.contactData, KycStepStatus.completed),
              _step(KycStepName.nationalityData, KycStepStatus.completed),
              _step(KycStepName.ident, KycStepStatus.failed),
              _step(KycStepName.financialData, KycStepStatus.completed),
              _step(KycStepName.dfxApproval, KycStepStatus.completed),
            ],
          ));
      when(() => kyc.getUser()).thenAnswer((_) async => _user('a@b.c'));
      when(() => kyc.continueKyc()).thenAnswer(
        (_) async =>
            _session(_step(KycStepName.ident, KycStepStatus.notStarted, isCurrent: true)),
      );

      final c = makeCubit();
      await c.checkKyc();
      verify(() => kyc.continueKyc()).called(1);
      expect(c.state, isA<KycSuccess>());
      expect((c.state as KycSuccess).currentStep, KycStep.ident);
    });

    test('emits KycPending when a required step is in review', () async {
      when(() => kyc.getKycStatus()).thenAnswer((_) async => KycLevelDto(
            kycLevel: KycLevel.level50,
            kycSteps: [
              _step(KycStepName.contactData, KycStepStatus.completed),
              _step(KycStepName.nationalityData, KycStepStatus.completed),
              _step(KycStepName.ident, KycStepStatus.inReview),
              _step(KycStepName.financialData, KycStepStatus.completed),
              _step(KycStepName.dfxApproval, KycStepStatus.completed),
            ],
          ));
      when(() => kyc.getUser()).thenAnswer((_) async => _user('a@b.c'));

      final c = makeCubit();
      await c.checkKyc();
      expect(c.state, isA<KycPending>());
    });
  });
}
