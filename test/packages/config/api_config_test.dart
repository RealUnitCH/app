import 'package:flutter_test/flutter_test.dart';
import 'package:realunit_wallet/packages/config/api_config.dart';
import 'package:realunit_wallet/packages/config/network_mode.dart';

void main() {
  late ApiConfig config;

  group('$ApiConfig', () {
    group('testnet mode', () {
      setUpAll(() => config = const ApiConfig(networkMode: NetworkMode.testnet));

      test('returns correct apiHost', () {
        expect(config.apiHost, equals('dev.api.dfx.swiss'));
      });
    });

    group('mainnet mode', () {
      setUpAll(() => config = const ApiConfig(networkMode: NetworkMode.mainnet));

      test('returns correct apiHost', () {
        expect(config.apiHost, equals('api.dfx.swiss'));
      });
    });
  });
}
