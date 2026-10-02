import 'dart:async';
import 'dart:convert';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:realunit_wallet/generated/release_info.dart';
import 'package:realunit_wallet/packages/repository/cache_repository.dart';
import 'package:realunit_wallet/packages/repository/settings_repository.dart';
import 'package:realunit_wallet/packages/service/dfx/exceptions/api_exception.dart';
import 'package:realunit_wallet/packages/service/dfx/models/client_policy/real_unit_client_policy.dart';
import 'package:realunit_wallet/packages/service/dfx/real_unit_client_policy_service.dart';
import 'package:realunit_wallet/packages/storage/database.dart';
import 'package:realunit_wallet/packages/utils/marketing_version.dart';
import 'package:realunit_wallet/screens/update_required/bloc/client_policy_cubit.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeService extends Fake implements RealUnitClientPolicyService {
  RealUnitClientPolicy? nextFetch;
  int fetchCount = 0;
  Completer<RealUnitClientPolicy?>? fetchCompleter;
  bool throwOnFetch = false;

  @override
  Future<RealUnitClientPolicy?> fetch() {
    fetchCount++;
    if (throwOnFetch) throw Exception('fetch failed');
    final pending = fetchCompleter;
    if (pending != null) return pending.future;
    return Future.value(nextFetch);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;
  late CacheRepository cache;
  late SettingsRepository settings;
  late _FakeService service;
  late ClientPolicyCubit cubit;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    db = AppDatabase.forTesting(NativeDatabase.memory());
    cache = CacheRepository(db);
    settings = SettingsRepository(await SharedPreferences.getInstance());
    service = _FakeService();
    cubit = ClientPolicyCubit(
      service,
      cache,
      settings,
      installedVersion: () => '1.2.0',
    );
  });

  tearDown(() async {
    await cubit.close();
    await db.close();
  });

  Future<void> waitLoaded() =>
      cubit.stream.firstWhere((state) => state is ClientPolicyLoaded);

  Future<Map<String, dynamic>> readCache() async {
    final raw = await cache.read(ClientPolicyCubit.cacheKey);
    expect(raw, isNotNull);
    return jsonDecode(raw!) as Map<String, dynamic>;
  }

  group('$ClientPolicyCubit', () {
    test(
      'empty reportUpgradeRequired caches forcedHard and does not fetch',
      () async {
        final loaded = waitLoaded();
        cubit.reportUpgradeRequired(const UpgradeRequiredException());
        await loaded;

        final stored = await readCache();
        expect(stored['forcedHard'], isTrue);
        expect(stored['minSupportedVersion'], isNull);
        expect(stored['installed'], '1.2.0');
        expect(stored['severity'], 'hard');
        expect(service.fetchCount, 0);
        expect(cubit.severity, ClientPolicySeverity.hard);
      },
    );

    test(
      'reportUpgradeRequired with min stores it and does not force-hard',
      () async {
        final loaded = waitLoaded();
        cubit.reportUpgradeRequired(
          const UpgradeRequiredException(minSupportedVersion: '1.3.0'),
        );
        await loaded;

        final stored = await readCache();
        expect(stored['forcedHard'], isFalse);
        expect(stored['minSupportedVersion'], '1.3.0');
        expect(service.fetchCount, 0);
        expect(cubit.severity, ClientPolicySeverity.hard);
      },
    );

    test('refresh after forcedHard with none clears forcedHard', () async {
      final loaded = waitLoaded();
      cubit.reportUpgradeRequired(const UpgradeRequiredException());
      await loaded;
      expect(cubit.severity, ClientPolicySeverity.hard);

      service.nextFetch = const RealUnitClientPolicy(
        severity: ClientPolicySeverity.none,
      );
      await cubit.refresh();

      final current = cubit.state as ClientPolicyLoaded;
      expect(current.policy.forcedHard, isFalse);
      expect(current.policy.severity, ClientPolicySeverity.none);
    });

    test('in-flight refresh does not overwrite a 426 hard', () async {
      final pending = Completer<RealUnitClientPolicy?>();
      service.fetchCompleter = pending;

      final states = <ClientPolicyState>[];
      final sub = cubit.stream.listen(states.add);

      final refreshFuture = cubit.refresh();
      expect(service.fetchCount, 1);

      cubit.reportUpgradeRequired(const UpgradeRequiredException());
      expect(cubit.severity, ClientPolicySeverity.hard);

      pending.complete(
        const RealUnitClientPolicy(severity: ClientPolicySeverity.none),
      );
      await refreshFuture;
      await Future<void>.delayed(Duration.zero);
      await sub.cancel();

      expect(cubit.severity, ClientPolicySeverity.hard);
      expect(
        states.whereType<ClientPolicyLoaded>().map((s) => s.policy.severity),
        everyElement(ClientPolicySeverity.hard),
      );
      expect(states, isNot(contains(const ClientPolicyFailOpen())));
    });

    test('dismissSoft hides the banner for that latest', () async {
      service.nextFetch = const RealUnitClientPolicy(
        latestVersion: '1.4.0',
        severity: ClientPolicySeverity.soft,
      );
      await cubit.refresh();
      expect(cubit.showSoftBanner, isTrue);

      cubit.dismissSoft('1.4.0');
      await Future<void>.delayed(Duration.zero);

      expect(cubit.showSoftBanner, isFalse);
    });

    test('showSoftBanner is false when latestVersion is null', () async {
      service.nextFetch = const RealUnitClientPolicy(
        severity: ClientPolicySeverity.soft,
      );
      await cubit.refresh();
      expect(cubit.showSoftBanner, isFalse);
    });

    test('showSoftBanner is false when latestVersion is empty', () async {
      service.nextFetch = const RealUnitClientPolicy(
        latestVersion: '',
        severity: ClientPolicySeverity.soft,
      );
      await cubit.refresh();
      expect(cubit.showSoftBanner, isFalse);
    });

    test('null fetch and empty cache fail open', () async {
      service.nextFetch = null;
      await cubit.refresh();

      expect(cubit.state, const ClientPolicyFailOpen());
    });

    test('null fetch keeps a live Loaded hard instead of FailOpen', () async {
      service.nextFetch = const RealUnitClientPolicy(
        severity: ClientPolicySeverity.hard,
      );
      await cubit.refresh();
      expect(cubit.severity, ClientPolicySeverity.hard);
      expect((cubit.state as ClientPolicyLoaded).policy.forcedHard, isFalse);

      service.nextFetch = null;
      await cubit.refresh();

      expect(cubit.state, isA<ClientPolicyLoaded>());
      expect(cubit.severity, ClientPolicySeverity.hard);
      expect(cubit.state, isNot(const ClientPolicyFailOpen()));
    });

    test('426 on 0.0.0 does not emit or store hard', () async {
      await cubit.close();
      cubit = ClientPolicyCubit(
        service,
        cache,
        settings,
        installedVersion: () => '0.0.0',
      );

      final loaded = waitLoaded();
      cubit.reportUpgradeRequired(const UpgradeRequiredException());
      await loaded;

      final stored = await readCache();
      expect(stored['forcedHard'], isFalse);
      expect(cubit.severity, isNot(ClientPolicySeverity.hard));
      expect(service.fetchCount, 0);
    });

    test('ClientPolicyInitial and FailOpen equal themselves', () {
      expect(const ClientPolicyInitial(), isNot(const ClientPolicyFailOpen()));
      // ignore: prefer_const_constructors
      expect(ClientPolicyInitial(), ClientPolicyInitial());
      // ignore: prefer_const_constructors
      expect(ClientPolicyFailOpen(), ClientPolicyFailOpen());
    });

    test(
      'defaults installedVersion to releaseMarketingVersion',
      () async {
        await cubit.close();
        cubit = ClientPolicyCubit(service, cache, settings);

        final loaded = waitLoaded();
        cubit.reportUpgradeRequired(const UpgradeRequiredException());
        await loaded;

        final stored = await readCache();
        expect(stored['installed'], releaseMarketingVersion);
      },
    );

    test('initialize emits cache then the refresh result', () async {
      const cachedPolicy = RealUnitClientPolicy(
        minSupportedVersion: '1.0.0',
        latestVersion: '1.3.0',
        severity: ClientPolicySeverity.soft,
      );
      await cache.write(
        ClientPolicyCubit.cacheKey,
        jsonEncode(cachedPolicy.toCacheJson(installed: '1.2.0')),
      );
      service.nextFetch = const RealUnitClientPolicy(
        minSupportedVersion: '1.1.0',
        latestVersion: '1.5.0',
        severity: ClientPolicySeverity.none,
      );

      final states = <ClientPolicyState>[];
      final refreshed = Completer<void>();
      final sub = cubit.stream.listen((state) {
        states.add(state);
        if (state is ClientPolicyLoaded &&
            state.policy.latestVersion == '1.5.0' &&
            !refreshed.isCompleted) {
          refreshed.complete();
        }
      });
      await cubit.initialize();
      await refreshed.future;
      await sub.cancel();

      expect(states.length, greaterThanOrEqualTo(2));
      final fromCache = states.first as ClientPolicyLoaded;
      expect(fromCache.policy.latestVersion, '1.3.0');
      expect(fromCache.policy.minSupportedVersion, '1.0.0');
      expect(fromCache.policy.severity, ClientPolicySeverity.soft);
      final fromRefresh = states.last as ClientPolicyLoaded;
      expect(fromRefresh.policy.latestVersion, '1.5.0');
      expect(fromRefresh.policy.minSupportedVersion, '1.1.0');
      expect(fromRefresh.policy.severity, ClientPolicySeverity.none);
    });

    test(
      'null fetch keeps a Loaded non-hard forcedHard instead of FailOpen',
      () async {
        await cubit.close();
        cubit = ClientPolicyCubit(
          service,
          cache,
          settings,
          installedVersion: () => '0.0.0',
        );
        const cachedPolicy = RealUnitClientPolicy(
          forcedHard: true,
          severity: ClientPolicySeverity.none,
        );
        await cache.write(
          ClientPolicyCubit.cacheKey,
          jsonEncode(cachedPolicy.toCacheJson(installed: '0.0.0')),
        );
        service.nextFetch = null;
        await cubit.initialize();
        await Future<void>.delayed(Duration.zero);

        expect(cubit.state, isA<ClientPolicyLoaded>());
        final kept = cubit.state as ClientPolicyLoaded;
        expect(kept.policy.forcedHard, isTrue);
        expect(kept.policy.severity, isNot(ClientPolicySeverity.hard));

        service.throwOnFetch = true;
        await cubit.refresh();

        expect(cubit.state, isA<ClientPolicyLoaded>());
        expect(
          (cubit.state as ClientPolicyLoaded).policy.forcedHard,
          isTrue,
        );
        expect(cubit.severity, isNot(ClientPolicySeverity.hard));
        expect(cubit.state, isNot(const ClientPolicyFailOpen()));
      },
    );

    test('null fetch from Initial emits cached hard', () async {
      const cachedPolicy = RealUnitClientPolicy(
        minSupportedVersion: '1.3.0',
        severity: ClientPolicySeverity.hard,
      );
      await cache.write(
        ClientPolicyCubit.cacheKey,
        jsonEncode(cachedPolicy.toCacheJson(installed: '1.2.0')),
      );
      service.nextFetch = null;
      await cubit.refresh();

      expect(cubit.state, isA<ClientPolicyLoaded>());
      expect(cubit.severity, ClientPolicySeverity.hard);
      expect(
        (cubit.state as ClientPolicyLoaded).policy.minSupportedVersion,
        '1.3.0',
      );
      expect(cubit.state, isNot(const ClientPolicyFailOpen()));
    });

    test('null fetch keeps a live Loaded soft instead of FailOpen', () async {
      service.nextFetch = const RealUnitClientPolicy(
        latestVersion: '1.4.0',
        severity: ClientPolicySeverity.soft,
      );
      await cubit.refresh();
      expect(cubit.state, isA<ClientPolicyLoaded>());
      expect(cubit.severity, ClientPolicySeverity.soft);

      service.nextFetch = null;
      await cubit.refresh();

      expect(cubit.state, isA<ClientPolicyLoaded>());
      expect(cubit.severity, ClientPolicySeverity.soft);
      expect(
        (cubit.state as ClientPolicyLoaded).policy.latestVersion,
        '1.4.0',
      );
      expect(cubit.state, isNot(const ClientPolicyFailOpen()));
    });

    test(
      'reportUpgradeRequired copies store URLs from the current Loaded',
      () async {
        const appStoreUrl = 'https://apps.apple.com/app/id123';
        const playStoreUrl =
            'https://play.google.com/store/apps/details?id=swiss.realunit.app';
        const githubReleasesUrl =
            'https://github.com/RealUnitCH/app/releases';
        service.nextFetch = const RealUnitClientPolicy(
          severity: ClientPolicySeverity.none,
          appStoreUrl: appStoreUrl,
          playStoreUrl: playStoreUrl,
          githubReleasesUrl: githubReleasesUrl,
        );
        await cubit.refresh();

        final loaded = waitLoaded();
        cubit.reportUpgradeRequired(
          const UpgradeRequiredException(minSupportedVersion: '1.3.0'),
        );
        await loaded;

        final current = cubit.state as ClientPolicyLoaded;
        expect(current.policy.appStoreUrl, appStoreUrl);
        expect(current.policy.playStoreUrl, playStoreUrl);
        expect(current.policy.githubReleasesUrl, githubReleasesUrl);

        Map<String, dynamic>? stored;
        for (var i = 0; i < 50; i++) {
          final raw = await cache.read(ClientPolicyCubit.cacheKey);
          if (raw != null) {
            final decoded = jsonDecode(raw) as Map<String, dynamic>;
            if (decoded['minSupportedVersion'] == '1.3.0') {
              stored = decoded;
              break;
            }
          }
        }
        expect(stored, isNotNull);
        expect(stored!['appStoreUrl'], appStoreUrl);
        expect(stored['playStoreUrl'], playStoreUrl);
        expect(stored['githubReleasesUrl'], githubReleasesUrl);
      },
    );

    test(
      'reportUpgradeRequired after close persists store URLs from cache',
      () async {
        const appStoreUrl = 'https://apps.apple.com/app/id123';
        const playStoreUrl =
            'https://play.google.com/store/apps/details?id=swiss.realunit.app';
        const githubReleasesUrl =
            'https://github.com/RealUnitCH/app/releases';
        const cachedPolicy = RealUnitClientPolicy(
          severity: ClientPolicySeverity.none,
          appStoreUrl: appStoreUrl,
          playStoreUrl: playStoreUrl,
          githubReleasesUrl: githubReleasesUrl,
        );
        await cache.write(
          ClientPolicyCubit.cacheKey,
          jsonEncode(cachedPolicy.toCacheJson(installed: '1.2.0')),
        );
        await cubit.close();
        expect(cubit.state, const ClientPolicyInitial());

        cubit.reportUpgradeRequired(
          const UpgradeRequiredException(minSupportedVersion: '1.3.0'),
        );

        Map<String, dynamic>? stored;
        for (var i = 0; i < 50; i++) {
          final raw = await cache.read(ClientPolicyCubit.cacheKey);
          if (raw != null) {
            final decoded = jsonDecode(raw) as Map<String, dynamic>;
            if (decoded['minSupportedVersion'] == '1.3.0') {
              stored = decoded;
              break;
            }
          }
        }

        expect(stored, isNotNull);
        expect(stored!['appStoreUrl'], appStoreUrl);
        expect(stored['playStoreUrl'], playStoreUrl);
        expect(stored['githubReleasesUrl'], githubReleasesUrl);
        expect(cubit.state, const ClientPolicyInitial());

        cubit = ClientPolicyCubit(
          service,
          cache,
          settings,
          installedVersion: () => '1.2.0',
        );
      },
    );

    test('initialize with empty cache and null fetch fail-opens', () async {
      service.nextFetch = null;
      final failOpen = cubit.stream.firstWhere(
        (state) => state is ClientPolicyFailOpen,
      );
      await cubit.initialize();

      expect(await failOpen, const ClientPolicyFailOpen());
    });

    test('empty cache string with null fetch fail-opens', () async {
      await cache.write(ClientPolicyCubit.cacheKey, '');
      service.nextFetch = null;
      await cubit.refresh();

      expect(cubit.state, const ClientPolicyFailOpen());
    });

    test('invalid cache JSON with null fetch fail-opens', () async {
      await cache.write(ClientPolicyCubit.cacheKey, '{');
      service.nextFetch = null;
      await cubit.refresh();

      expect(cubit.state, const ClientPolicyFailOpen());
    });

    test('non-JSON cache with null fetch fail-opens', () async {
      await cache.write(ClientPolicyCubit.cacheKey, 'not-json');
      service.nextFetch = null;
      await cubit.refresh();

      expect(cubit.state, const ClientPolicyFailOpen());
    });

    test('JSON array cache with null fetch fail-opens', () async {
      await cache.write(ClientPolicyCubit.cacheKey, '[1]');
      service.nextFetch = null;
      await cubit.refresh();

      expect(cubit.state, const ClientPolicyFailOpen());
    });

    test('initialize emits Loaded from a valid cache object', () async {
      const cachedPolicy = RealUnitClientPolicy(
        minSupportedVersion: '1.0.0',
        latestVersion: '1.3.0',
        severity: ClientPolicySeverity.soft,
      );
      await cache.write(
        ClientPolicyCubit.cacheKey,
        jsonEncode(cachedPolicy.toCacheJson(installed: '1.2.0')),
      );
      service.nextFetch = const RealUnitClientPolicy(
        severity: ClientPolicySeverity.none,
      );

      final first = cubit.stream.firstWhere(
        (state) => state is ClientPolicyLoaded,
      );
      await cubit.initialize();
      final loaded = await first as ClientPolicyLoaded;

      expect(loaded.policy.minSupportedVersion, '1.0.0');
      expect(loaded.policy.latestVersion, '1.3.0');
      expect(loaded.policy.severity, ClientPolicySeverity.soft);
    });

    test('fetch throw fail-opens like a null fetch', () async {
      service.throwOnFetch = true;
      await cubit.refresh();

      expect(cubit.state, const ClientPolicyFailOpen());
    });
  });
}
