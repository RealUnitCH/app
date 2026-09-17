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
    final urls = _stringKeyedMap(json['storeUrls']) ?? const <String, dynamic>{};
    return RealUnitClientPolicyDto(
      minSupportedVersion: _optionalString(json['minSupportedVersion']),
      latestVersion: _optionalString(json['latestVersion']),
      severity: _optionalString(json['severity']),
      appStore: _optionalString(urls['appStore']),
      playStore: _optionalString(urls['playStore']),
      githubReleases: _optionalString(urls['githubReleases']),
    );
  }
}

String? _optionalString(Object? value) {
  if (value is String && value.isNotEmpty) return value;
  return null;
}

Map<String, dynamic>? _stringKeyedMap(Object? value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) {
    return value.map((key, val) => MapEntry(key.toString(), val));
  }
  return null;
}
