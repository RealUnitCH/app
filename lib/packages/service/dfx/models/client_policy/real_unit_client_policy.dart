import 'package:clock/clock.dart';
import 'package:equatable/equatable.dart';
import 'package:realunit_wallet/packages/service/dfx/models/client_policy/dto/real_unit_client_policy_dto.dart';
import 'package:realunit_wallet/packages/utils/marketing_version.dart';
import 'package:realunit_wallet/packages/utils/store_url_allowlist.dart';

/// Snapshot of `GET /v1/realunit/client-policy`.
///
/// Live JSON is parsed by [RealUnitClientPolicyDto.fromJson] (API severity,
/// with a 0.0.0 hard-skip). The Drift cache round-trips through
/// [toCacheJson] / [fromCacheJson] and persists live severity plus the
/// installed version; a mismatch fail-opens. [forcedHard] remains a 426
/// signal.
class RealUnitClientPolicy extends Equatable {
  final String? minSupportedVersion;
  final String? latestVersion;
  final ClientPolicySeverity severity;
  final String? appStoreUrl;
  final String? playStoreUrl;
  final String? githubReleasesUrl;
  final bool forcedHard;
  final DateTime? fetchedAt;

  const RealUnitClientPolicy({
    this.minSupportedVersion,
    this.latestVersion,
    required this.severity,
    this.appStoreUrl,
    this.playStoreUrl,
    this.githubReleasesUrl,
    this.forcedHard = false,
    this.fetchedAt,
  });

  factory RealUnitClientPolicy.fromCacheJson(
    Map<String, dynamic> json, {
    required String installed,
  }) {
    final minSupportedVersion = _optionalString(json['minSupportedVersion']);
    final latestVersion = _optionalString(json['latestVersion']);
    final forcedHard = json['forcedHard'] == true;
    final fetchedAtRaw = _optionalString(json['fetchedAt']);
    final cachedInstalled = json['installed'];

    final ClientPolicySeverity severity;
    if (forcedHard) {
      severity = _skipHardOnZeroInstalled(
        severity: ClientPolicySeverity.hard,
        installed: installed,
        minSupportedVersion: minSupportedVersion,
        latestVersion: latestVersion,
      );
    } else if (cachedInstalled is! String ||
        cachedInstalled.isEmpty ||
        cachedInstalled != installed) {
      severity = ClientPolicySeverity.none;
    } else {
      severity = _liveSeverity(
        json['severity'],
        installed: installed,
        minSupportedVersion: minSupportedVersion,
        latestVersion: latestVersion,
      );
    }

    return RealUnitClientPolicy(
      minSupportedVersion: minSupportedVersion,
      latestVersion: latestVersion,
      severity: severity,
      appStoreUrl: _storeUrl(json['appStoreUrl'], StoreUrlChannel.appStore),
      playStoreUrl: _storeUrl(json['playStoreUrl'], StoreUrlChannel.playStore),
      githubReleasesUrl: _storeUrl(
        json['githubReleasesUrl'],
        StoreUrlChannel.githubReleases,
      ),
      forcedHard: forcedHard,
      fetchedAt: fetchedAtRaw == null ? null : DateTime.tryParse(fetchedAtRaw),
    );
  }

  Map<String, dynamic> toCacheJson({required String installed}) {
    return {
      'fetchedAt': (fetchedAt ?? clock.now()).toIso8601String(),
      'minSupportedVersion': minSupportedVersion,
      'latestVersion': latestVersion,
      'appStoreUrl': appStoreUrl,
      'playStoreUrl': playStoreUrl,
      'githubReleasesUrl': githubReleasesUrl,
      'forcedHard': forcedHard,
      'severity': severity.name,
      'installed': installed,
    };
  }

  RealUnitClientPolicy copyWith({
    String? minSupportedVersion,
    String? latestVersion,
    ClientPolicySeverity? severity,
    String? appStoreUrl,
    String? playStoreUrl,
    String? githubReleasesUrl,
    bool? forcedHard,
    DateTime? fetchedAt,
  }) {
    return RealUnitClientPolicy(
      minSupportedVersion: minSupportedVersion ?? this.minSupportedVersion,
      latestVersion: latestVersion ?? this.latestVersion,
      severity: severity ?? this.severity,
      appStoreUrl: appStoreUrl ?? this.appStoreUrl,
      playStoreUrl: playStoreUrl ?? this.playStoreUrl,
      githubReleasesUrl: githubReleasesUrl ?? this.githubReleasesUrl,
      forcedHard: forcedHard ?? this.forcedHard,
      fetchedAt: fetchedAt ?? this.fetchedAt,
    );
  }

  @override
  List<Object?> get props => [
        minSupportedVersion,
        latestVersion,
        severity,
        appStoreUrl,
        playStoreUrl,
        githubReleasesUrl,
        forcedHard,
        fetchedAt,
      ];
}

extension RealUnitClientPolicyDtoMapper on RealUnitClientPolicyDto {
  RealUnitClientPolicy toDomain({required String installed}) {
    return RealUnitClientPolicy(
      minSupportedVersion: minSupportedVersion,
      latestVersion: latestVersion,
      severity: _liveSeverity(
        severity,
        installed: installed,
        minSupportedVersion: minSupportedVersion,
        latestVersion: latestVersion,
      ),
      appStoreUrl: _storeUrl(appStore, StoreUrlChannel.appStore),
      playStoreUrl: _storeUrl(playStore, StoreUrlChannel.playStore),
      githubReleasesUrl: _storeUrl(
        githubReleases,
        StoreUrlChannel.githubReleases,
      ),
      forcedHard: false,
      fetchedAt: clock.now(),
    );
  }
}

String? _optionalString(Object? value) {
  if (value is String && value.isNotEmpty) return value;
  return null;
}

String? _storeUrl(Object? raw, StoreUrlChannel channel) {
  if (raw is! String) return null;
  return parseAllowlistedStoreUrl(raw, channel);
}

bool isZeroInstalled(String installed) {
  if (installed == '0.0.0') return true;
  final parsed = parseMarketingVersion(installed);
  return parsed != null &&
      parsed.major == 0 &&
      parsed.minor == 0 &&
      parsed.patch == 0;
}

ClientPolicySeverity _skipHardOnZeroInstalled({
  required ClientPolicySeverity severity,
  required String installed,
  String? minSupportedVersion,
  String? latestVersion,
}) {
  if (severity != ClientPolicySeverity.hard || !isZeroInstalled(installed)) {
    return severity;
  }
  final recomputed = computeClientPolicySeverity(
    installed: installed,
    minSupportedVersion: minSupportedVersion,
    latestVersion: latestVersion,
  );
  return recomputed == ClientPolicySeverity.hard
      ? ClientPolicySeverity.none
      : recomputed;
}

ClientPolicySeverity _liveSeverity(
  Object? raw, {
  required String installed,
  String? minSupportedVersion,
  String? latestVersion,
}) {
  final token = raw is String ? raw.toLowerCase() : null;
  final severity = switch (token) {
    'none' => ClientPolicySeverity.none,
    'soft' => ClientPolicySeverity.soft,
    'hard' => ClientPolicySeverity.hard,
    _ => ClientPolicySeverity.none,
  };

  return _skipHardOnZeroInstalled(
    severity: severity,
    installed: installed,
    minSupportedVersion: minSupportedVersion,
    latestVersion: latestVersion,
  );
}
