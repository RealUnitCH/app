import 'dart:async';
import 'dart:convert';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
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

  @override
  Future<RealUnitClientPolicy?> fetch() {
    fetchCount++;
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
  });
}
