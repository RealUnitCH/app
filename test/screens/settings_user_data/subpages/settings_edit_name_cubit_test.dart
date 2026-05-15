import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:realunit_wallet/packages/service/dfx/dfx_kyc_service.dart';
import 'package:realunit_wallet/packages/service/dfx/models/kyc/dto/kyc_session_dto.dart';
import 'package:realunit_wallet/packages/service/dfx/models/kyc/kyc_level.dart';
import 'package:realunit_wallet/screens/settings_user_data/subpages/edit_name/cubit/settings_edit_name_cubit.dart';

class _MockKycService extends Mock implements DfxKycService {}

KycSessionDto _session({
  required KycStepStatus stepStatus,
  String? url = 'https://kyc.example/edit-name',
}) {
  final currentStep = url == null
      ? null
      : KycStepSessionDto(
          name: KycStepName.nameChange,
          status: stepStatus,
          sequenceNumber: 0,
          isCurrent: true,
          session: KycSessionInfoDto(url: url, type: UrlType.browser),
        );
  return KycSessionDto(
    kycLevel: KycLevel.level20,
    kycSteps: const [],
    currentStep: currentStep,
  );
}

void main() {
  late _MockKycService kyc;

  setUpAll(() {
    registerFallbackValue(KycStepName.nameChange);
  });

  setUp(() {
    kyc = _MockKycService();
  });

  // The cubit fires _loadEdit() in its constructor. We assert the
  // final state via stream.firstWhere.
  group('$SettingsEditNameCubit', () {
    test('reaches Ready with the session URL on a fresh step', () async {
      when(() => kyc.startStep(KycStepName.nameChange))
          .thenAnswer((_) async => _session(stepStatus: KycStepStatus.notStarted));

      final cubit = SettingsEditNameCubit(kycService: kyc);
      await cubit.stream.firstWhere((s) => s is SettingsEditNameReady);

      expect((cubit.state as SettingsEditNameReady).url, contains('edit-name'));
    });

    test('reaches Pending when the step is already inReview', () async {
      when(() => kyc.startStep(KycStepName.nameChange))
          .thenAnswer((_) async => _session(stepStatus: KycStepStatus.inReview));

      final cubit = SettingsEditNameCubit(kycService: kyc);
      await cubit.stream.firstWhere((s) => s is SettingsEditNamePending);

      expect(cubit.state, isA<SettingsEditNamePending>());
    });

    test('reaches Failure when the API throws', () async {
      when(() => kyc.startStep(any()))
          .thenAnswer((_) async => throw Exception('rate-limited'));

      final cubit = SettingsEditNameCubit(kycService: kyc);
      await cubit.stream.firstWhere((s) => s is SettingsEditNameFailure);

      expect((cubit.state as SettingsEditNameFailure).message, contains('rate-limited'));
    });

    test('reaches Failure when the session has no URL', () async {
      when(() => kyc.startStep(KycStepName.nameChange))
          .thenAnswer((_) async => _session(stepStatus: KycStepStatus.notStarted, url: null));

      final cubit = SettingsEditNameCubit(kycService: kyc);
      await cubit.stream.firstWhere((s) => s is SettingsEditNameFailure);

      expect(
        (cubit.state as SettingsEditNameFailure).message,
        contains('No session URL'),
      );
    });

    test('refresh() re-runs _loadEdit and can recover from a prior failure', () async {
      var calls = 0;
      when(() => kyc.startStep(any())).thenAnswer((_) async {
        calls++;
        if (calls == 1) throw Exception('transient');
        return _session(stepStatus: KycStepStatus.notStarted);
      });

      final cubit = SettingsEditNameCubit(kycService: kyc);
      await cubit.stream.firstWhere((s) => s is SettingsEditNameFailure);
      cubit.refresh();
      await cubit.stream.firstWhere((s) => s is SettingsEditNameReady);

      expect(cubit.state, isA<SettingsEditNameReady>());
    });

    test('submitName is a no-op when not in Ready state', () async {
      when(() => kyc.startStep(any()))
          .thenAnswer((_) async => throw Exception('boom'));
      final cubit = SettingsEditNameCubit(kycService: kyc);
      await cubit.stream.firstWhere((s) => s is SettingsEditNameFailure);

      await cubit.submitName(
        firstName: 'A',
        lastName: 'B',
        fileBase64: 'AAAA',
        fileName: 'id.pdf',
      );

      verifyNever(() => kyc.setData(any(), any()));
      expect(cubit.state, isA<SettingsEditNameFailure>());
    });

    test('submitName POSTs the form payload and emits Success', () async {
      when(() => kyc.startStep(KycStepName.nameChange))
          .thenAnswer((_) async => _session(stepStatus: KycStepStatus.notStarted));
      when(() => kyc.setData(any(), any())).thenAnswer((_) async {});

      final cubit = SettingsEditNameCubit(kycService: kyc);
      await cubit.stream.firstWhere((s) => s is SettingsEditNameReady);
      final url = (cubit.state as SettingsEditNameReady).url;

      await cubit.submitName(
        firstName: 'Alice',
        lastName: 'Doe',
        fileBase64: 'ZmFrZQ==',
        fileName: 'id.pdf',
      );

      expect(cubit.state, isA<SettingsEditNameSuccess>());
      verify(() => kyc.setData(url, {
            'firstName': 'Alice',
            'lastName': 'Doe',
            'file': 'ZmFrZQ==',
            'fileName': 'id.pdf',
          })).called(1);
    });

    test('submitName emits Failure if setData throws', () async {
      when(() => kyc.startStep(KycStepName.nameChange))
          .thenAnswer((_) async => _session(stepStatus: KycStepStatus.notStarted));
      when(() => kyc.setData(any(), any())).thenAnswer((_) async => throw Exception('500'));

      final cubit = SettingsEditNameCubit(kycService: kyc);
      await cubit.stream.firstWhere((s) => s is SettingsEditNameReady);

      await cubit.submitName(
        firstName: 'A',
        lastName: 'B',
        fileBase64: 'AAAA',
        fileName: 'id.pdf',
      );

      expect(cubit.state, isA<SettingsEditNameFailure>());
      expect((cubit.state as SettingsEditNameFailure).message, contains('500'));
    });
  });
}
