import 'package:flutter_test/flutter_test.dart';
import 'package:realunit_wallet/packages/service/dfx/models/kyc/dto/kyc_level_dto.dart';
import 'package:realunit_wallet/packages/service/dfx/models/kyc/dto/kyc_session_dto.dart';
import 'package:realunit_wallet/packages/service/dfx/models/kyc/dto/kyc_step_dto.dart';
import 'package:realunit_wallet/packages/service/dfx/models/kyc/kyc_level.dart';

void main() {
  group('$KycStepDto.fromJson', () {
    test('full step with name + type + status + reason + sequence + isCurrent', () {
      final dto = KycStepDto.fromJson({
        'name': 'ContactData',
        'type': 'Auto',
        'status': 'InProgress',
        'reason': 'AccountExists',
        'sequenceNumber': 5,
        'isCurrent': true,
      });

      expect(dto.name, KycStepName.contactData);
      expect(dto.type, KycStepType.auto);
      expect(dto.status, KycStepStatus.inProgress);
      expect(dto.reason, KycStepReason.accountExists);
      expect(dto.sequenceNumber, 5);
      expect(dto.isCurrent, isTrue);
    });

    test('type and reason are optional (null on the wire)', () {
      final dto = KycStepDto.fromJson({
        'name': 'NationalityData',
        'type': null,
        'status': 'NotStarted',
        'reason': null,
        'sequenceNumber': 0,
        'isCurrent': false,
      });

      expect(dto.type, isNull);
      expect(dto.reason, isNull);
    });

    test('isCurrent defaults to false when missing', () {
      final dto = KycStepDto.fromJson({
        'name': 'PersonalData',
        'status': 'NotStarted',
        'sequenceNumber': 1,
        // isCurrent absent
      });

      expect(dto.isCurrent, isFalse);
    });

    test('unknown name throws (no silent fallback)', () {
      expect(
        () => KycStepDto.fromJson({
          'name': 'NotARealStep',
          'status': 'NotStarted',
          'sequenceNumber': 0,
        }),
        throwsA(anything),
      );
    });
  });

  group('$KycSessionInfoDto.fromJson', () {
    test('parses url + UrlType', () {
      final dto = KycSessionInfoDto.fromJson({
        'url': 'https://kyc.example/session/abc',
        'type': 'Browser',
      });

      expect(dto.url, 'https://kyc.example/session/abc');
      expect(dto.type, UrlType.browser);
    });

    test('UrlTypeExtension.fromJson covers all four enum values', () {
      expect(UrlTypeExtension.fromJson('Browser'), UrlType.browser);
      expect(UrlTypeExtension.fromJson('API'), UrlType.api);
      expect(UrlTypeExtension.fromJson('Token'), UrlType.token);
      expect(UrlTypeExtension.fromJson('None'), UrlType.none);
    });

    test('UrlType.fromJson throws ArgumentError on unknown', () {
      expect(() => UrlTypeExtension.fromJson('XML'), throwsArgumentError);
    });
  });

  group('$KycStepSessionDto.fromJson', () {
    test('inherits the step fields and carries a nested KycSessionInfoDto', () {
      final dto = KycStepSessionDto.fromJson({
        'session': {
          'url': 'https://kyc.example/edit-name',
          'type': 'Browser',
        },
        'name': 'NameChange',
        'status': 'NotStarted',
        'sequenceNumber': 0,
        'isCurrent': true,
      });

      expect(dto, isA<KycStepDto>());
      expect(dto.name, KycStepName.nameChange);
      expect(dto.status, KycStepStatus.notStarted);
      expect(dto.isCurrent, isTrue);
      expect(dto.session.url, 'https://kyc.example/edit-name');
      expect(dto.session.type, UrlType.browser);
    });
  });

  group('$KycLevelDto.fromJson', () {
    test('parses level + step list', () {
      final dto = KycLevelDto.fromJson({
        'kycLevel': 20,
        'kycSteps': [
          {
            'name': 'ContactData',
            'status': 'Completed',
            'sequenceNumber': 0,
          },
          {
            'name': 'PersonalData',
            'status': 'NotStarted',
            'sequenceNumber': 1,
          },
        ],
      });

      expect(dto.kycLevel, KycLevel.level20);
      expect(dto.kycSteps, hasLength(2));
      expect(dto.kycSteps.first.name, KycStepName.contactData);
    });

    test('empty steps list is allowed', () {
      final dto = KycLevelDto.fromJson({
        'kycLevel': 0,
        'kycSteps': <Map<String, dynamic>>[],
      });

      expect(dto.kycLevel, KycLevel.level0);
      expect(dto.kycSteps, isEmpty);
    });
  });

  group('$KycSessionDto.fromJson', () {
    test('extends $KycLevelDto with optional currentStep', () {
      final dto = KycSessionDto.fromJson({
        'kycLevel': 20,
        'kycSteps': <Map<String, dynamic>>[],
        'currentStep': {
          'session': {'url': 'https://x', 'type': 'Browser'},
          'name': 'NameChange',
          'status': 'NotStarted',
          'sequenceNumber': 0,
          'isCurrent': true,
        },
      });

      expect(dto, isA<KycLevelDto>());
      expect(dto.currentStep, isNotNull);
      expect(dto.currentStep!.name, KycStepName.nameChange);
    });

    test('currentStep null on the wire stays null', () {
      final dto = KycSessionDto.fromJson({
        'kycLevel': 0,
        'kycSteps': <Map<String, dynamic>>[],
        'currentStep': null,
      });

      expect(dto.currentStep, isNull);
    });
  });
}
