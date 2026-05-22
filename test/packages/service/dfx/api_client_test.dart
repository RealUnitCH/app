import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:realunit_wallet/generated/release_info.dart';
import 'package:realunit_wallet/packages/service/dfx/api_client.dart';

void main() {
  group('RealUnitApiClient', () {
    test('tags every request with X-Client headers', () async {
      late Map<String, String> sent;
      final client = RealUnitApiClient(
        MockClient((request) async {
          sent = request.headers;
          return http.Response('{}', 200);
        }),
      );

      await client.get(Uri.parse('https://dev.api.dfx.swiss/v1/realunit/price'));

      expect(sent['X-Client'], 'realunit-app');
      expect(sent['X-Client-Version'], releaseMarketingVersion);
    });

    test('does not overwrite an X-Client header set by the caller', () async {
      late Map<String, String> sent;
      final client = RealUnitApiClient(
        MockClient((request) async {
          sent = request.headers;
          return http.Response('{}', 200);
        }),
      );

      await client.get(
        Uri.parse('https://dev.api.dfx.swiss/v1/realunit/price'),
        headers: {'X-Client': 'custom-client'},
      );

      expect(sent['X-Client'], 'custom-client');
    });
  });
}
