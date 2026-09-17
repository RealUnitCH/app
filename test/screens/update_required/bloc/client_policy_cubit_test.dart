import 'dart:convert';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
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

  @override
  Future<RealUnitClientPolicy?> fetch() async {
    fetchCount++;
    return nextFetch;
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

  Future<void> _waitLoaded() =>
      cubit.stream.firstWhere((state) => state is ClientPolicyLoaded);

  Future<Map<String, dynamic>> _readCache() async {
    final raw = await cache.read(ClientPolicyCubit.cacheKey);
    expect(raw, isNotNull);
    return jsonDecode(raw!) as Map<String, dynamic>;
  }

  group('$ClientPolicyCubit', () {
    test(
      'empty reportUpgradeRequired caches forcedHard and does not fetch',
      () async {
        final loaded = _waitLoaded();
        cubit.reportUpgradeRequired(const UpgradeRequiredException());
        await loaded;

        final stored = await _readCache();
        expect(stored['forcedHard'], isTrue);
        expect(stored['minSupportedVersion'], isNull);
        expect(service.fetchCount, 0);
        expect(cubit.severity, ClientPolicySeverity.hard);
      },
    );

    test(
      'reportUpgradeRequired with min stores it and does not force-hard',
      () async {
        final loaded = _waitLoaded();
        cubit.reportUpgradeRequired(
          const UpgradeRequiredException(minSupportedVersion: '1.3.0'),
        );
        await loaded;

        final stored = await _readCache();
        expect(stored['forcedHard'], isFalse);
        expect(stored['minSupportedVersion'], '1.3.0');
        expect(service.fetchCount, 0);
        expect(cubit.severity, ClientPolicySeverity.hard);
      },
    );

    test('refresh after forcedHard with none clears forcedHard', () async {
      final loaded = _waitLoaded();
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

    test('null fetch and empty cache fail open', () async {
      service.nextFetch = null;
      await cubit.refresh();

      expect(cubit.state, const ClientPolicyFailOpen());
    });
  });
}
