import 'package:realunit_wallet/packages/service/dfx/models/client_policy/real_unit_client_policy.dart';

class StoreUpdateTarget {
  final String? primaryUrl;
  final String? githubSecondaryUrl;
  const StoreUpdateTarget({this.primaryUrl, this.githubSecondaryUrl});
}

const playInstallerPackages = {
  'com.android.vending',
  'com.google.android.feedback',
};

StoreUpdateTarget pickStoreUpdate({
  required bool isIOS,
  required String? installerPackage,
  required RealUnitClientPolicy policy,
}) {
  if (isIOS) {
    return StoreUpdateTarget(primaryUrl: policy.appStoreUrl);
  }

  final installer = installerPackage ?? '';

  if (playInstallerPackages.contains(installer)) {
    return StoreUpdateTarget(primaryUrl: policy.playStoreUrl);
  }

  if (installer.isEmpty) {
    final primaryUrl = policy.playStoreUrl;
    final github = policy.githubReleasesUrl;
    final githubSecondaryUrl =
        github != null && github != primaryUrl ? github : null;
    return StoreUpdateTarget(
      primaryUrl: primaryUrl,
      githubSecondaryUrl: githubSecondaryUrl,
    );
  }

  // sideload / packageinstaller
  return StoreUpdateTarget(primaryUrl: policy.githubReleasesUrl);
}
