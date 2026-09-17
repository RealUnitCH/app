import 'package:flutter_test/flutter_test.dart';
import 'package:realunit_wallet/packages/service/dfx/models/client_policy/dto/real_unit_client_policy_dto.dart';
import 'package:realunit_wallet/packages/service/dfx/models/client_policy/real_unit_client_policy.dart';
import 'package:realunit_wallet/packages/utils/marketing_version.dart';

void main() {
  group('$RealUnitClientPolicyDto.fromJson', () {
    test('drops a Play Store URL whose id is not swiss.realunit.app', () {
      final policy = RealUnitClientPolicyDto.fromJson(
        {
          'storeUrls': {
            'playStore':
                'https://play.google.com/store/apps/details?id=swiss.realunit.app.malware',
          },
        },
      ).toDomain(installed: '1.2.0');

      expect(policy.playStoreUrl, isNull);
    });

    test('keeps a valid Play Store URL', () {
      const playStoreUrl =
          'https://play.google.com/store/apps/details?id=swiss.realunit.app';
      final policy = RealUnitClientPolicyDto.fromJson(
        {
          'storeUrls': {'playStore': playStoreUrl},
        },
      ).toDomain(installed: '1.2.0');

      expect(policy.playStoreUrl, playStoreUrl);
    });

    test(
      'JSON severity hard with installed 0.0.0 and latest 1.4.0 is soft',
      () {
        final policy = RealUnitClientPolicyDto.fromJson(
          {
            'severity': 'hard',
            'latestVersion': '1.4.0',
          },
        ).toDomain(installed: '0.0.0');

        expect(policy.severity, ClientPolicySeverity.soft);
        expect(policy.severity, isNot(ClientPolicySeverity.hard));
      },
    );

    test('PascalCase None Soft Hard map to the enum', () {
      expect(
        RealUnitClientPolicyDto.fromJson({'severity': 'None'})
            .toDomain(installed: '1.2.0')
            .severity,
        ClientPolicySeverity.none,
      );
      expect(
        RealUnitClientPolicyDto.fromJson({'severity': 'Soft'})
            .toDomain(installed: '1.2.0')
            .severity,
        ClientPolicySeverity.soft,
      );
      expect(
        RealUnitClientPolicyDto.fromJson({'severity': 'Hard'})
            .toDomain(installed: '1.2.0')
            .severity,
        ClientPolicySeverity.hard,
      );
    });

    test('lowercase none soft hard map to the enum', () {
      expect(
        RealUnitClientPolicyDto.fromJson({'severity': 'none'})
            .toDomain(installed: '1.2.0')
            .severity,
        ClientPolicySeverity.none,
      );
      expect(
        RealUnitClientPolicyDto.fromJson({'severity': 'soft'})
            .toDomain(installed: '1.2.0')
            .severity,
        ClientPolicySeverity.soft,
      );
      expect(
        RealUnitClientPolicyDto.fromJson({'severity': 'hard'})
            .toDomain(installed: '1.2.0')
            .severity,
        ClientPolicySeverity.hard,
      );
    });

    test('missing severity does not become hard from a high min', () {
      final policy = RealUnitClientPolicyDto.fromJson(
        {'minSupportedVersion': '9.0.0'},
      ).toDomain(installed: '1.2.0');

      expect(policy.severity, ClientPolicySeverity.none);
    });

    test('unknown severity does not become hard from a high min', () {
      final policy = RealUnitClientPolicyDto.fromJson(
        {
          'severity': 'Unknown',
          'minSupportedVersion': '9.0.0',
        },
      ).toDomain(installed: '1.2.0');

      expect(policy.severity, ClientPolicySeverity.none);
    });
  });

  group('$RealUnitClientPolicy.fromCacheJson', () {
    test('forcedHard true is hard even without min', () {
      final policy = RealUnitClientPolicy.fromCacheJson(
        {'forcedHard': true},
        installed: '1.2.0',
      );

      expect(policy.forcedHard, isTrue);
      expect(policy.minSupportedVersion, isNull);
      expect(policy.severity, ClientPolicySeverity.hard);
    });

    test('0.0.0 is never hard even with forcedHard true', () {
      final withLatest = RealUnitClientPolicy.fromCacheJson(
        {
          'forcedHard': true,
          'latestVersion': '1.4.0',
        },
        installed: '0.0.0',
      );
      expect(withLatest.severity, isNot(ClientPolicySeverity.hard));
      expect(withLatest.severity, ClientPolicySeverity.soft);

      final withoutLatest = RealUnitClientPolicy.fromCacheJson(
        {'forcedHard': true},
        installed: '0.0.0',
      );
      expect(withoutLatest.severity, isNot(ClientPolicySeverity.hard));
      expect(withoutLatest.severity, ClientPolicySeverity.none);
    });
  });
}
