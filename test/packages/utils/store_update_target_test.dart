import 'package:flutter_test/flutter_test.dart';
import 'package:realunit_wallet/packages/service/dfx/models/client_policy/real_unit_client_policy.dart';
import 'package:realunit_wallet/packages/utils/marketing_version.dart';
import 'package:realunit_wallet/packages/utils/store_update_target.dart';

void main() {
  const appStoreUrl = 'https://apps.example.com/app';
  const playStoreUrl = 'https://play.example.com/app';
  const githubReleasesUrl = 'https://github.example.com/releases';

  const policy = RealUnitClientPolicy(
    severity: ClientPolicySeverity.none,
    appStoreUrl: appStoreUrl,
    playStoreUrl: playStoreUrl,
    githubReleasesUrl: githubReleasesUrl,
  );

  const duplicateGithubPolicy = RealUnitClientPolicy(
    severity: ClientPolicySeverity.none,
    appStoreUrl: appStoreUrl,
    playStoreUrl: playStoreUrl,
    githubReleasesUrl: playStoreUrl,
  );

  group('pickStoreUpdate', () {
    final cases = <({
      String name,
      bool isIOS,
      String? installerPackage,
      RealUnitClientPolicy policy,
      String? primaryUrl,
      String? githubSecondaryUrl,
    })>[
      (
        name: 'iOS uses App Store only; github secondary is null',
        isIOS: true,
        installerPackage: null,
        policy: policy,
        primaryUrl: appStoreUrl,
        githubSecondaryUrl: null,
      ),
      (
        name: 'Android vending uses Play Store; github secondary is null',
        isIOS: false,
        installerPackage: 'com.android.vending',
        policy: policy,
        primaryUrl: playStoreUrl,
        githubSecondaryUrl: null,
      ),
      (
        name: 'Android feedback uses Play Store; github secondary is null',
        isIOS: false,
        installerPackage: 'com.google.android.feedback',
        policy: policy,
        primaryUrl: playStoreUrl,
        githubSecondaryUrl: null,
      ),
      (
        name: 'Android packageinstaller uses GitHub; github secondary is null',
        isIOS: false,
        installerPackage: 'com.android.packageinstaller',
        policy: policy,
        primaryUrl: githubReleasesUrl,
        githubSecondaryUrl: null,
      ),
      (
        name:
            'Android google packageinstaller uses GitHub; github secondary is null',
        isIOS: false,
        installerPackage: 'com.google.android.packageinstaller',
        policy: policy,
        primaryUrl: githubReleasesUrl,
        githubSecondaryUrl: null,
      ),
      (
        name: 'Android null installer uses Play primary and GitHub secondary',
        isIOS: false,
        installerPackage: null,
        policy: policy,
        primaryUrl: playStoreUrl,
        githubSecondaryUrl: githubReleasesUrl,
      ),
      (
        name:
            'Android empty-string installer uses Play primary and GitHub secondary',
        isIOS: false,
        installerPackage: '',
        policy: policy,
        primaryUrl: playStoreUrl,
        githubSecondaryUrl: githubReleasesUrl,
      ),
      (
        name:
            'Android null installer does not duplicate GitHub when it equals Play',
        isIOS: false,
        installerPackage: null,
        policy: duplicateGithubPolicy,
        primaryUrl: playStoreUrl,
        githubSecondaryUrl: null,
      ),
    ];

    for (final c in cases) {
      test(c.name, () {
        final target = pickStoreUpdate(
          isIOS: c.isIOS,
          installerPackage: c.installerPackage,
          policy: c.policy,
        );

        expect(target.primaryUrl, c.primaryUrl);
        expect(target.githubSecondaryUrl, c.githubSecondaryUrl);
      });
    }

    test('iOS never uses play as primary when app and play are both set', () {
      final target = pickStoreUpdate(
        isIOS: true,
        installerPackage: 'com.android.vending',
        policy: policy,
      );

      expect(target.primaryUrl, appStoreUrl);
      expect(target.primaryUrl, isNot(playStoreUrl));
      expect(target.githubSecondaryUrl, isNull);
    });
  });
}
