import 'package:flutter_test/flutter_test.dart';
import 'package:realunit_wallet/packages/utils/marketing_version.dart';

void main() {
  group('parseMarketingVersion', () {
    test('parses a three-part marketing version', () {
      final parsed = parseMarketingVersion('1.2.0');

      expect(parsed, isNotNull);
      expect(parsed!.major, 1);
      expect(parsed.minor, 2);
      expect(parsed.patch, 0);
    });

    test('parses 0.0.0 as a valid sentinel', () {
      final parsed = parseMarketingVersion('0.0.0');

      expect(parsed, isNotNull);
      expect(parsed!.major, 0);
      expect(parsed.minor, 0);
      expect(parsed.patch, 0);
    });

    test('returns null for missing, empty, or unparseable values', () {
      expect(parseMarketingVersion(null), isNull);
      expect(parseMarketingVersion(''), isNull);
      expect(parseMarketingVersion('1.2'), isNull);
      expect(parseMarketingVersion('1.2.0-beta'), isNull);
      expect(parseMarketingVersion('1.2.24+42'), isNull);
    });
  });

  group('compareMarketingVersions', () {
    test('orders 1.2.0 < 1.2.1 < 1.3.0 < 2.0.0', () {
      expect(compareMarketingVersions('1.2.0', '1.2.1'), lessThan(0));
      expect(compareMarketingVersions('1.2.1', '1.3.0'), lessThan(0));
      expect(compareMarketingVersions('1.3.0', '2.0.0'), lessThan(0));
      expect(compareMarketingVersions('2.0.0', '1.2.0'), greaterThan(0));
    });

    test('compares patch 9 < 10 as integers, not strings', () {
      expect(compareMarketingVersions('1.2.9', '1.2.10'), lessThan(0));
      expect(compareMarketingVersions('1.2.10', '1.2.9'), greaterThan(0));
    });

    test('compares minor 9 < 10 as integers, not strings', () {
      expect(compareMarketingVersions('1.9.0', '1.10.0'), lessThan(0));
      expect(compareMarketingVersions('1.10.0', '1.9.0'), greaterThan(0));
    });

    test('1.2.0 is not less than 1.2.0', () {
      expect(compareMarketingVersions('1.2.0', '1.2.0'), 0);
    });

    test('returns 0 when either side is unparseable', () {
      expect(compareMarketingVersions('1.2', '1.2.0'), 0);
      expect(compareMarketingVersions('1.2.0', '1.2.0-beta'), 0);
      expect(compareMarketingVersions('1.2.24+42', '1.3.0'), 0);
      expect(compareMarketingVersions(null, '1.2.0'), 0);
    });
  });

  group('computeClientPolicySeverity', () {
    test('0.0.0 is never hard even if min is 1.0.0', () {
      expect(
        computeClientPolicySeverity(
          installed: '0.0.0',
          minSupportedVersion: '1.0.0',
        ),
        ClientPolicySeverity.none,
      );
    });

    test('0.0.0 with latest 1.2.0 is soft', () {
      expect(
        computeClientPolicySeverity(
          installed: '0.0.0',
          latestVersion: '1.2.0',
        ),
        ClientPolicySeverity.soft,
      );
    });

    test('missing, null, or unparseable installed is none', () {
      expect(
        computeClientPolicySeverity(installed: null, minSupportedVersion: '1.3.0'),
        ClientPolicySeverity.none,
      );
      expect(
        computeClientPolicySeverity(installed: '', minSupportedVersion: '1.3.0'),
        ClientPolicySeverity.none,
      );
      expect(
        computeClientPolicySeverity(installed: '1.2', minSupportedVersion: '1.3.0'),
        ClientPolicySeverity.none,
      );
      expect(
        computeClientPolicySeverity(
          installed: '1.2.0-beta',
          minSupportedVersion: '1.3.0',
        ),
        ClientPolicySeverity.none,
      );
      expect(
        computeClientPolicySeverity(
          installed: '1.2.24+42',
          minSupportedVersion: '1.3.0',
        ),
        ClientPolicySeverity.none,
      );
    });

    test('1.2.0 vs min 1.3.0 is hard', () {
      expect(
        computeClientPolicySeverity(
          installed: '1.2.0',
          minSupportedVersion: '1.3.0',
        ),
        ClientPolicySeverity.hard,
      );
    });

    test('empty min is not hard', () {
      expect(
        computeClientPolicySeverity(
          installed: '1.2.0',
          minSupportedVersion: '',
        ),
        ClientPolicySeverity.none,
      );
    });

    test('installed equal to latest is not soft', () {
      expect(
        computeClientPolicySeverity(
          installed: '1.2.0',
          latestVersion: '1.2.0',
        ),
        ClientPolicySeverity.none,
      );
    });

    test('installed below latest is soft when not hard', () {
      expect(
        computeClientPolicySeverity(
          installed: '1.2.0',
          minSupportedVersion: '1.0.0',
          latestVersion: '1.3.0',
        ),
        ClientPolicySeverity.soft,
      );
    });

    test('latest below min is ignored for soft', () {
      expect(
        computeClientPolicySeverity(
          installed: '0.0.0',
          minSupportedVersion: '1.3.0',
          latestVersion: '1.2.0',
        ),
        ClientPolicySeverity.none,
      );
      expect(
        computeClientPolicySeverity(
          installed: '1.4.0',
          minSupportedVersion: '1.3.0',
          latestVersion: '1.2.0',
        ),
        ClientPolicySeverity.none,
      );
    });
  });
}
