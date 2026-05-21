import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:realunit_wallet/packages/service/dfx/dfx_kyc_service.dart';
import 'package:realunit_wallet/packages/service/dfx/models/kyc/dto/kyc_session_dto.dart';
import 'package:realunit_wallet/packages/service/dfx/models/kyc/kyc_level.dart';
import 'package:realunit_wallet/screens/settings_user_data/subpages/edit_address/cubit/settings_edit_address_cubit.dart';

class _MockKycService extends Mock implements DfxKycService {}

KycSessionDto _session({
  required KycStepStatus stepStatus,
  String? url = 'https://kyc.example/edit-address',
}) {
  final currentStep = url == null
      ? null
      : KycStepSessionDto(
          name: KycStepName.addressChange,
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
    registerFallbackValue(KycStepName.addressChange);
  });

  setUp(() {
    kyc = _MockKycService();
  });

  group('$SettingsEditAddressCubit', () {
    test('reaches Ready with the session URL', () async {
      when(() => kyc.startStep(KycStepName.addressChange))
          .thenAnswer((_) async => _session(stepStatus: KycStepStatus.notStarted));

      final cubit = SettingsEditAddressCubit(kycService: kyc);
      await cubit.stream.firstWhere((s) => s is SettingsEditAddressReady);

      expect((cubit.state as SettingsEditAddressReady).url, contains('edit-address'));
    });

    test(
      'reaches Pending only when the session returns no URL (W3.2: inReview-gating moved upstream to canEditAddress)',
      () async {
        when(() => kyc.startStep(KycStepName.addressChange))
            .thenAnswer((_) async => _session(stepStatus: KycStepStatus.inReview, url: null));

        final cubit = SettingsEditAddressCubit(kycService: kyc);
        await cubit.stream.firstWhere((s) => s is SettingsEditAddressPending);

        expect(cubit.state, isA<SettingsEditAddressPending>());
      },
    );

    test('reaches Failure on API throw', () async {
      when(() => kyc.startStep(any()))
          .thenAnswer((_) async => throw Exception('throttle'));

      final cubit = SettingsEditAddressCubit(kycService: kyc);
      await cubit.stream.firstWhere((s) => s is SettingsEditAddressFailure);

      expect(
        (cubit.state as SettingsEditAddressFailure).message,
        contains('throttle'),
      );
    });

    test('reaches Pending when the session has no URL', () async {
      // The session lacking a URL is now interpreted as "still in some
      // pending review state" rather than a hard failure — the upstream
      // capability gate stops this branch from being reached in practice.
      when(() => kyc.startStep(KycStepName.addressChange))
          .thenAnswer((_) async => _session(stepStatus: KycStepStatus.notStarted, url: null));

      final cubit = SettingsEditAddressCubit(kycService: kyc);
      await cubit.stream.firstWhere((s) => s is SettingsEditAddressPending);

      expect(cubit.state, isA<SettingsEditAddressPending>());
    });

    test('submitAddress is a no-op when not in Ready state', () async {
      when(() => kyc.startStep(any()))
          .thenAnswer((_) async => throw Exception('boom'));
      final cubit = SettingsEditAddressCubit(kycService: kyc);
      await cubit.stream.firstWhere((s) => s is SettingsEditAddressFailure);

      await cubit.submitAddress(
        street: 'Test',
        houseNumber: '1',
        zip: '8000',
        city: 'Zurich',
        countryId: 41,
        fileBase64: 'AAAA',
        fileName: 'address.pdf',
      );

      verifyNever(() => kyc.setData(any(), any()));
    });

    test('submitAddress sends the structured payload and emits Success', () async {
      when(() => kyc.startStep(KycStepName.addressChange))
          .thenAnswer((_) async => _session(stepStatus: KycStepStatus.notStarted));
      when(() => kyc.setData(any(), any())).thenAnswer((_) async {});

      final cubit = SettingsEditAddressCubit(kycService: kyc);
      await cubit.stream.firstWhere((s) => s is SettingsEditAddressReady);

      await cubit.submitAddress(
        street: 'Bahnhofstrasse',
        houseNumber: '12',
        zip: '8001',
        city: 'Zurich',
        countryId: 41,
        fileBase64: 'ZmFrZQ==',
        fileName: 'utility.pdf',
      );

      expect(cubit.state, isA<SettingsEditAddressSuccess>());
      verify(() => kyc.setData(any(), {
            'file': 'ZmFrZQ==',
            'fileName': 'utility.pdf',
            'address': {
              'street': 'Bahnhofstrasse',
              'houseNumber': '12',
              'zip': '8001',
              'city': 'Zurich',
              'country': {'id': 41},
            },
          })).called(1);
    });

    test('submitAddress omits houseNumber from address payload when empty', () async {
      when(() => kyc.startStep(KycStepName.addressChange))
          .thenAnswer((_) async => _session(stepStatus: KycStepStatus.notStarted));
      Map<String, dynamic>? captured;
      when(() => kyc.setData(any(), any())).thenAnswer((invocation) async {
        captured = invocation.positionalArguments[1] as Map<String, dynamic>;
      });

      final cubit = SettingsEditAddressCubit(kycService: kyc);
      await cubit.stream.firstWhere((s) => s is SettingsEditAddressReady);

      await cubit.submitAddress(
        street: 'Hauptstrasse',
        houseNumber: '',
        zip: '8000',
        city: 'Zurich',
        countryId: 41,
        fileBase64: 'AAAA',
        fileName: 'file.pdf',
      );

      final address = captured!['address'] as Map<String, dynamic>;
      expect(address.containsKey('houseNumber'), isFalse);
      expect(address['street'], 'Hauptstrasse');
    });

    test('submitAddress emits Failure if setData throws', () async {
      when(() => kyc.startStep(KycStepName.addressChange))
          .thenAnswer((_) async => _session(stepStatus: KycStepStatus.notStarted));
      when(() => kyc.setData(any(), any()))
          .thenAnswer((_) async => throw Exception('400 bad request'));

      final cubit = SettingsEditAddressCubit(kycService: kyc);
      await cubit.stream.firstWhere((s) => s is SettingsEditAddressReady);

      await cubit.submitAddress(
        street: 'S',
        houseNumber: '1',
        zip: '8000',
        city: 'Z',
        countryId: 41,
        fileBase64: 'A',
        fileName: 'f',
      );

      expect(cubit.state, isA<SettingsEditAddressFailure>());
      expect(
        (cubit.state as SettingsEditAddressFailure).message,
        contains('400 bad request'),
      );
    });
  });
}
