import 'dart:convert';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:realunit_wallet/packages/config/api_config.dart';
import 'package:realunit_wallet/packages/config/network_mode.dart';
import 'package:realunit_wallet/packages/repository/cache_repository.dart';
import 'package:realunit_wallet/packages/service/app_store.dart';
import 'package:realunit_wallet/packages/service/dfx/real_unit_client_policy_service.dart';
import 'package:realunit_wallet/packages/service/session_cache.dart';
import 'package:realunit_wallet/packages/storage/database.dart';
import 'package:realunit_wallet/packages/utils/marketing_version.dart';

void main() {
  late AppDatabase db;
  late AppStore appStore;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    appStore = AppStore(
      () => const ApiConfig(networkMode: NetworkMode.mainnet),
      SessionCache(CacheRepository(db)),
    );
  });

  tearDown(() async {
    await db.close();
  });

  RealUnitClientPolicyService build(http.Client httpClient) {
    return RealUnitClientPolicyService(
      appStore,
      httpClient: httpClient,
      installedVersion: () => '1.2.0',
    );
  }

  group('$RealUnitClientPolicyService', () {
    test('200 parses the policy JSON', () async {
      const playStoreUrl =
          'https://play.google.com/store/apps/details?id=swiss.realunit.app';
      Uri? sent;
      final client = MockClient((request) async {
        sent = request.url;
        return http.Response(
          jsonEncode({
            'minSupportedVersion': '1.0.0',
            'latestVersion': '1.4.0',
            'severity': 'soft',
            'storeUrls': {'playStore': playStoreUrl},
          }),
          200,
        );
      });

      final policy = await build(client).fetch();

      expect(
        sent,
        buildUri(
          const ApiConfig(networkMode: NetworkMode.mainnet).apiHost,
          '/v1/realunit/client-policy',
        ),
      );
      expect(policy, isNotNull);
      expect(policy!.minSupportedVersion, '1.0.0');
      expect(policy.latestVersion, '1.4.0');
      expect(policy.severity, ClientPolicySeverity.soft);
      expect(policy.playStoreUrl, playStoreUrl);
      expect(policy.forcedHard, isFalse);
    });

    test('404 returns null', () async {
      final client = MockClient((_) async => http.Response('', 404));

      expect(await build(client).fetch(), isNull);
    });

    test('500 returns null', () async {
      final client = MockClient((_) async => http.Response('', 500));

      expect(await build(client).fetch(), isNull);
    });

    test('invalid JSON returns null', () async {
      final client = MockClient((_) async => http.Response('{', 200));

      expect(await build(client).fetch(), isNull);
    });

    test('JSON array returns null', () async {
      final client = MockClient((_) async => http.Response('[1]', 200));

      expect(await build(client).fetch(), isNull);
    });

    test('empty JSON array returns null', () async {
      final client = MockClient((_) async => http.Response('[]', 200));

      expect(await build(client).fetch(), isNull);
    });

    test('defaults httpClient and installedVersion from AppStore', () {
      expect(
        RealUnitClientPolicyService(appStore),
        isA<RealUnitClientPolicyService>(),
      );
    });

    test(
      '200 without installedVersion uses the default release version',
      () async {
        final client = MockClient((_) async {
          return http.Response(
            jsonEncode({
              'minSupportedVersion': '1.0.0',
              'latestVersion': '1.4.0',
              'severity': 'soft',
            }),
            200,
          );
        });

        final policy = await RealUnitClientPolicyService(
          appStore,
          httpClient: client,
        ).fetch();

        expect(policy, isNotNull);
        expect(policy!.minSupportedVersion, '1.0.0');
        expect(policy.latestVersion, '1.4.0');
        expect(policy.severity, ClientPolicySeverity.soft);
        expect(policy.forcedHard, isFalse);
      },
    );
  });
}
