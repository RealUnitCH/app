import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:realunit_wallet/generated/release_info.dart';
import 'package:realunit_wallet/packages/service/dfx/api_client.dart';
import 'package:realunit_wallet/packages/service/dfx/exceptions/api_exception.dart';

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

    test('close() delegates to the wrapped inner client', () {
      // The wrapper owns no resources of its own, so close() must hand
      // off cleanly to whatever Client was injected. A regression that
      // forgets to forward close() would leak the underlying socket pool
      // (and silently swallow `inner.close()` semantics in tests that
      // rely on it).
      var closed = false;
      final inner = _CloseTrackingClient(() => closed = true);
      final client = RealUnitApiClient(inner);

      client.close();

      expect(closed, isTrue);
    });

    test('default constructor instantiates its own inner Client', () {
      // The optional-argument branch (`inner ?? Client()`) is otherwise
      // never exercised by the injecting tests above. close() must
      // still work — it would throw if the default branch were broken
      // (e.g. `null!` dereference).
      final client = RealUnitApiClient();
      expect(() => client.close(), returnsNormally);
    });

    test('426 UPGRADE_REQUIRED fires onUpgradeRequired once and still completes', () async {
      var calls = 0;
      UpgradeRequiredException? seen;
      final client = RealUnitApiClient(
        MockClient((request) async {
          return http.Response(
            '{"code":"UPGRADE_REQUIRED","minSupportedVersion":"1.3.0"}',
            426,
          );
        }),
      );
      client.onUpgradeRequired = (error) {
        calls += 1;
        seen = error;
      };

      final response = await client.get(
        Uri.parse('https://dev.api.dfx.swiss/v1/realunit/price'),
      );

      expect(response.statusCode, 426);
      expect(
        response.body,
        '{"code":"UPGRADE_REQUIRED","minSupportedVersion":"1.3.0"}',
      );
      expect(calls, 1);
      expect(seen, isNotNull);
      expect(seen!.minSupportedVersion, '1.3.0');
      expect(
        ApiException.userFacingMessage(
          const UpgradeRequiredException(minSupportedVersion: '1.3.0'),
        ),
        '',
      );
    });

    test('200 does not fire onUpgradeRequired', () async {
      var calls = 0;
      final client = RealUnitApiClient(
        MockClient((request) async {
          return http.Response('{}', 200);
        }),
      );
      client.onUpgradeRequired = (_) => calls += 1;

      final response = await client.get(
        Uri.parse('https://dev.api.dfx.swiss/v1/realunit/price'),
      );

      expect(response.statusCode, 200);
      expect(calls, 0);
    });

    test('empty-body 426 still fires onUpgradeRequired with null min', () async {
      UpgradeRequiredException? seen;
      final client = RealUnitApiClient(
        MockClient((request) async {
          return http.Response('', 426);
        }),
      );
      client.onUpgradeRequired = (error) => seen = error;

      final response = await client.get(
        Uri.parse('https://dev.api.dfx.swiss/v1/realunit/price'),
      );

      expect(response.statusCode, 426);
      expect(response.body, isEmpty);
      expect(seen, isNotNull);
      expect(seen!.minSupportedVersion, isNull);
    });
  });
}

class _CloseTrackingClient extends http.BaseClient {
  _CloseTrackingClient(this._onClose);

  final void Function() _onClose;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    throw UnimplementedError('not used in close() test');
  }

  @override
  void close() {
    _onClose();
    super.close();
  }
}
