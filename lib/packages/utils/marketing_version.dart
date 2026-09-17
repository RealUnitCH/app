class MarketingVersion {
  final int major;
  final int minor;
  final int patch;

  const MarketingVersion(this.major, this.minor, this.patch);
}

const _marketingVersionPattern = RegExp(r'^(\d+)\.(\d+)\.(\d+)$');

/// Match `/^(\d+)\.(\d+)\.(\d+)$/` exactly. Null if missing or unparseable.
/// `0.0.0` is a valid sentinel. Rejects `1.2`, `1.2.0-beta`, `1.2.24+42`.
MarketingVersion? parseMarketingVersion(String? raw) {
  if (raw == null) return null;
  final match = _marketingVersionPattern.firstMatch(raw);
  if (match == null) return null;
  return MarketingVersion(
    int.parse(match.group(1)!),
    int.parse(match.group(2)!),
    int.parse(match.group(3)!),
  );
}

int _compareParsed(MarketingVersion a, MarketingVersion b) {
  final major = a.major.compareTo(b.major);
  if (major != 0) return major;
  final minor = a.minor.compareTo(b.minor);
  if (minor != 0) return minor;
  return a.patch.compareTo(b.patch);
}

/// Parse both. If either is unparseable, return 0 (do not treat as older).
/// Negative if [a] < [b], 0 if equal, positive if [a] > [b].
int compareMarketingVersions(String? a, String? b) {
  final parsedA = parseMarketingVersion(a);
  final parsedB = parseMarketingVersion(b);
  if (parsedA == null || parsedB == null) return 0;
  return _compareParsed(parsedA, parsedB);
}

enum ClientPolicySeverity { none, soft, hard }

bool _isZeroSentinel(MarketingVersion version) =>
    version.major == 0 && version.minor == 0 && version.patch == 0;

ClientPolicySeverity computeClientPolicySeverity({
  required String? installed,
  String? minSupportedVersion,
  String? latestVersion,
}) {
  final parsedInstalled = parseMarketingVersion(installed);
  final parsedMin = parseMarketingVersion(minSupportedVersion);
  final parsedLatest = parseMarketingVersion(latestVersion);

  final hard = parsedMin != null &&
      parsedInstalled != null &&
      !_isZeroSentinel(parsedInstalled) &&
      _compareParsed(parsedInstalled, parsedMin) < 0;
  if (hard) return ClientPolicySeverity.hard;

  final latestForSoft = parsedLatest != null &&
          parsedMin != null &&
          _compareParsed(parsedLatest, parsedMin) < 0
      ? null
      : parsedLatest;

  final soft = latestForSoft != null &&
      parsedInstalled != null &&
      _compareParsed(parsedInstalled, latestForSoft) < 0;
  if (soft) return ClientPolicySeverity.soft;

  return ClientPolicySeverity.none;
}
