/// Wire snapshot of `GET /v1/realunit/client-policy`.
class RealUnitClientPolicyDto {
  final String? minSupportedVersion;
  final String? latestVersion;
  final String? severity;
  final String? appStore;
  final String? playStore;
  final String? githubReleases;

  const RealUnitClientPolicyDto({
    this.minSupportedVersion,
    this.latestVersion,
    this.severity,
    this.appStore,
    this.playStore,
    this.githubReleases,
  });

  factory RealUnitClientPolicyDto.fromJson(Map<String, dynamic> json) {
    final urls = json['storeUrls'] as Map<String, dynamic>?;
    return RealUnitClientPolicyDto(
      minSupportedVersion: _emptyToNull(json['minSupportedVersion'] as String?),
      latestVersion: _emptyToNull(json['latestVersion'] as String?),
      severity: _emptyToNull(json['severity'] as String?),
      appStore: _emptyToNull(urls?['appStore'] as String?),
      playStore: _emptyToNull(urls?['playStore'] as String?),
      githubReleases: _emptyToNull(urls?['githubReleases'] as String?),
    );
  }
}

String? _emptyToNull(String? value) {
  if (value == null || value.isEmpty) return null;
  return value;
}
