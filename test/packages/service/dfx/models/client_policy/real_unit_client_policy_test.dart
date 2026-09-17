import 'package:flutter_test/flutter_test.dart';
import 'package:realunit_wallet/packages/service/dfx/models/client_policy/real_unit_client_policy.dart';
import 'package:realunit_wallet/packages/utils/marketing_version.dart';

void main() {
  group('$RealUnitClientPolicy.fromJson', () {
    test('drops a Play Store URL whose id is not swiss.realunit.app', () {
      final policy = RealUnitClientPolicy.fromJson(
        {
          'storeUrls': {
            'playStore':
                'https://play.google.com/store/apps/details?id=swiss.realunit.app.malware',
          },
        },
        installed: '1.2.0',
      );

      expect(policy.playStoreUrl, isNull);
    });

    test('keeps a valid Play Store URL', () {
      const playStoreUrl =
          'https://play.google.com/store/apps/details?id=swiss.realunit.app';
      final policy = RealUnitClientPolicy.fromJson(
        {
          'storeUrls': {'playStore': playStoreUrl},
        },
        installed: '1.2.0',
      );

      expect(policy.playStoreUrl, playStoreUrl);
    });

    test(
      'JSON severity hard with installed 0.0.0 and latest 1.4.0 is soft',
      () {
        final policy = RealUnitClientPolicy.fromJson(
          {
            'severity': 'hard',
            'latestVersion': '1.4.0',
          },
          installed: '0.0.0',
        );

        expect(policy.severity, ClientPolicySeverity.soft);
        expect(policy.severity, isNot(ClientPolicySeverity.hard));
      },
    );
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
  });
}
