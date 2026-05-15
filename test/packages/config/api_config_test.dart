import 'package:flutter_test/flutter_test.dart';
import 'package:realunit_wallet/packages/config/api_config.dart';
import 'package:realunit_wallet/packages/config/network_mode.dart';
import 'package:realunit_wallet/packages/utils/default_assets.dart';

void main() {
  late ApiConfig config;

  group('$ApiConfig', () {
    group('testnet mode', () {
      setUpAll(() => config = const ApiConfig(networkMode: NetworkMode.testnet));

      test('returns correct apiHost', () {
        expect(config.apiHost, equals('dev.api.dfx.swiss'));
      });

      test('asset is the Sepolia RealUnit testnet asset', () {
        expect(config.asset, realUnitTestAsset);
      });

      test('ethAssetId and zchfAssetId are the Sepolia ids', () {
        expect(config.ethAssetId, sepoliaEthAssetId);
        expect(config.zchfAssetId, sepoliaZchfAssetId);
      });
    });

    group('mainnet mode', () {
      setUpAll(() => config = const ApiConfig(networkMode: NetworkMode.mainnet));

      test('returns correct apiHost', () {
        expect(config.apiHost, equals('api.dfx.swiss'));
      });

      test('asset is the Ethereum mainnet RealUnit asset', () {
        expect(config.asset, realUnitAsset);
      });

      test('ethAssetId and zchfAssetId are the Ethereum ids', () {
        expect(config.ethAssetId, ethereumEthAssetId);
        expect(config.zchfAssetId, ethereumZchfAssetId);
      });
    });
  });

  group('buildUri', () {
    test('builds an https URI (production is not local-testing)', () {
      final uri = buildUri('api.dfx.swiss', '/v1/foo');

      expect(uri.scheme, 'https');
      expect(uri.host, 'api.dfx.swiss');
      expect(uri.path, '/v1/foo');
    });

    test('appends queryParams when provided', () {
      final uri = buildUri('api.dfx.swiss', '/v1/foo', {'a': '1', 'b': '2'});

      expect(uri.queryParameters['a'], '1');
      expect(uri.queryParameters['b'], '2');
    });

    test('omits the query string entirely when params are null', () {
      final uri = buildUri('api.dfx.swiss', '/v1/foo');

      expect(uri.hasQuery, isFalse);
    });
  });
}
