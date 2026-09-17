import 'dart:async';
import 'dart:convert';

import 'package:clock/clock.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:realunit_wallet/generated/release_info.dart';
import 'package:realunit_wallet/packages/repository/cache_repository.dart';
import 'package:realunit_wallet/packages/repository/settings_repository.dart';
import 'package:realunit_wallet/packages/service/dfx/exceptions/api_exception.dart';
import 'package:realunit_wallet/packages/service/dfx/models/client_policy/real_unit_client_policy.dart';
import 'package:realunit_wallet/packages/service/dfx/real_unit_client_policy_service.dart';
import 'package:realunit_wallet/packages/utils/marketing_version.dart';

part 'client_policy_state.dart';

/// App-wide client-policy cubit. Last-known hard from cache is emitted in
/// [initialize] before the unawaited live refresh, so boot can see it.
class ClientPolicyCubit extends Cubit<ClientPolicyState> {
  static const cacheKey = 'client_policy_v1';

  final RealUnitClientPolicyService _service;
  final CacheRepository _cache;
  final SettingsRepository _settings;
  final String Function() _installedVersion;

  ClientPolicyCubit(
    this._service,
    this._cache,
    this._settings, {
    String Function()? installedVersion,
  })  : _installedVersion = installedVersion ?? (() => releaseMarketingVersion),
        super(const ClientPolicyInitial());

  ClientPolicySeverity get severity {
    final current = state;
    if (current is ClientPolicyLoaded) return current.policy.severity;
    return ClientPolicySeverity.none;
  }

  bool get showSoftBanner {
    final current = state;
    if (current is! ClientPolicyLoaded) return false;
    if (current.policy.severity != ClientPolicySeverity.soft) return false;
    final dismissed = _settings.dismissedClientPolicyLatest;
    if (dismissed == null) return true;
    return dismissed != current.policy.latestVersion;
  }

  Future<void> initialize() async {
    final cached = await _readCache();
    if (cached != null && !isClosed) {
      emit(ClientPolicyLoaded(cached));
    }
    unawaited(refresh());
  }

  Future<void> refresh() async {
    RealUnitClientPolicy? fetched;
    try {
      fetched = await _service.fetch();
    } catch (_) {
      fetched = null;
    }

    if (fetched != null) {
      final stored = fetched.copyWith(
        forcedHard: false,
        fetchedAt: clock.now(),
      );
      await _writeCache(stored);
      if (!isClosed) emit(ClientPolicyLoaded(stored));
      return;
    }

    final current = state;
    if (current is ClientPolicyLoaded &&
        (current.policy.severity == ClientPolicySeverity.hard ||
            current.policy.forcedHard)) {
      return;
    }

    final cached = await _readCache();
    if (cached != null &&
        (cached.forcedHard || cached.severity == ClientPolicySeverity.hard)) {
      if (!isClosed) emit(ClientPolicyLoaded(cached));
      return;
    }

    if (current is ClientPolicyLoaded &&
        current.policy.severity != ClientPolicySeverity.hard) {
      return;
    }

    if (!isClosed) emit(const ClientPolicyFailOpen());
  }

  /// Persist a 426 immediately. Must not re-GET. Tear-off compatible with
  /// `void Function(UpgradeRequiredException)`.
  ///
  /// Emits hard *synchronously* so a concurrent [refresh] cannot FailOpen
  /// before cache I/O completes.
  void reportUpgradeRequired(UpgradeRequiredException e) {
    final min = _nonEmpty(e.minSupportedVersion);
    final latest = _nonEmpty(e.latestVersion);
    var forcedHard = min == null && latest == null;
    var severity = ClientPolicySeverity.hard;
    final installed = _installedVersion();
    if (isZeroInstalled(installed)) {
      final recomputed = computeClientPolicySeverity(
        installed: installed,
        minSupportedVersion: min,
        latestVersion: latest,
      );
      severity = recomputed == ClientPolicySeverity.hard
          ? ClientPolicySeverity.none
          : recomputed;
      forcedHard = false;
    }

    String? appStoreUrl;
    String? playStoreUrl;
    String? githubReleasesUrl;
    final current = state;
    if (current is ClientPolicyLoaded) {
      appStoreUrl = current.policy.appStoreUrl;
      playStoreUrl = current.policy.playStoreUrl;
      githubReleasesUrl = current.policy.githubReleasesUrl;
    }

    final policy = RealUnitClientPolicy(
      minSupportedVersion: min,
      latestVersion: latest,
      severity: severity,
      appStoreUrl: appStoreUrl,
      playStoreUrl: playStoreUrl,
      githubReleasesUrl: githubReleasesUrl,
      forcedHard: forcedHard,
      fetchedAt: clock.now(),
    );
    if (!isClosed) emit(ClientPolicyLoaded(policy));
    unawaited(_persistUpgrade(e));
  }

  void dismissSoft(String latestVersion) {
    _settings.dismissedClientPolicyLatest = latestVersion;
    final current = state;
    if (current is ClientPolicyLoaded && !isClosed) {
      emit(ClientPolicyLoaded(current.policy, dismissedLatest: latestVersion));
    }
  }

  Future<void> _persistUpgrade(UpgradeRequiredException e) async {
    final min = _nonEmpty(e.minSupportedVersion);
    final latest = _nonEmpty(e.latestVersion);
    var forcedHard = min == null && latest == null;
    var severity = ClientPolicySeverity.hard;
    final installed = _installedVersion();
    if (isZeroInstalled(installed)) {
      final recomputed = computeClientPolicySeverity(
        installed: installed,
        minSupportedVersion: min,
        latestVersion: latest,
      );
      severity = recomputed == ClientPolicySeverity.hard
          ? ClientPolicySeverity.none
          : recomputed;
      forcedHard = false;
    }
    String? appStoreUrl;
    String? playStoreUrl;
    String? githubReleasesUrl;
    final current = state;
    if (current is ClientPolicyLoaded) {
      appStoreUrl = current.policy.appStoreUrl;
      playStoreUrl = current.policy.playStoreUrl;
      githubReleasesUrl = current.policy.githubReleasesUrl;
    } else {
      final cached = await _readCache();
      if (cached != null) {
        appStoreUrl = cached.appStoreUrl;
        playStoreUrl = cached.playStoreUrl;
        githubReleasesUrl = cached.githubReleasesUrl;
      }
    }

    final policy = RealUnitClientPolicy(
      minSupportedVersion: min,
      latestVersion: latest,
      severity: severity,
      appStoreUrl: appStoreUrl,
      playStoreUrl: playStoreUrl,
      githubReleasesUrl: githubReleasesUrl,
      forcedHard: forcedHard,
      fetchedAt: clock.now(),
    );
    await _writeCache(policy);
    if (!isClosed) emit(ClientPolicyLoaded(policy));
  }

  Future<RealUnitClientPolicy?> _readCache() async {
    try {
      final raw = await _cache.read(cacheKey);
      if (raw == null || raw.isEmpty) return null;
      final decoded = jsonDecode(raw);
      final map = decoded is Map<String, dynamic>
          ? decoded
          : decoded is Map
              ? decoded.map((key, value) => MapEntry(key.toString(), value))
              : null;
      if (map == null) return null;
      return RealUnitClientPolicy.fromCacheJson(
        map,
        installed: _installedVersion(),
      );
    } catch (_) {
      return null;
    }
  }

  Future<void> _writeCache(RealUnitClientPolicy policy) {
    return _cache.write(cacheKey, jsonEncode(policy.toCacheJson()));
  }
}

String? _nonEmpty(String? value) {
  if (value == null || value.isEmpty) return null;
  return value;
}
