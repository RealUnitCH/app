import 'package:flutter_test/flutter_test.dart';
import 'package:realunit_wallet/packages/config/api_config.dart';

void main() {
  group('ApiConfig', () {
    group('testnet mode', () {
      late ApiConfig config;

      setUp(() {
        config = const ApiConfig(networkMode: NetworkMode.testnet);
      });

      test('dfxApiHost returns dev.api.dfx.swiss', () {
        expect(config.dfxApiHost, equals('dev.api.dfx.swiss'));
      });

      test('dfxAppHost returns dev.app.dfx.swiss', () {
        expect(config.dfxAppHost, equals('dev.app.dfx.swiss'));
      });

      test('realUnitPriceUrl contains dev.api.dfx.swiss', () {
        expect(config.realUnitPriceUrl, contains('dev.api.dfx.swiss'));
      });

      test('realUnitAccountHistoryUrl contains dev.api.dfx.swiss', () {
        final url = config.realUnitAccountHistoryUrl('0x123');
        expect(url, contains('dev.api.dfx.swiss'));
        expect(url, contains('0x123'));
      });
    });

    group('mainnet mode', () {
      late ApiConfig config;

      setUp(() {
        config = const ApiConfig(networkMode: NetworkMode.mainnet);
      });

      test('dfxApiHost returns api.dfx.swiss', () {
        expect(config.dfxApiHost, equals('api.dfx.swiss'));
      });

      test('dfxAppHost returns app.dfx.swiss', () {
        expect(config.dfxAppHost, equals('app.dfx.swiss'));
      });

      test('realUnitPriceUrl contains api.dfx.swiss', () {
        expect(config.realUnitPriceUrl, contains('api.dfx.swiss'));
      });

      test('realUnitAccountHistoryUrl contains api.dfx.swiss', () {
        final url = config.realUnitAccountHistoryUrl('0x456');
        expect(url, contains('api.dfx.swiss'));
        expect(url, contains('0x456'));
      });
    });
  });

  group('NetworkMode', () {
    test('testnet isTestnet returns true', () {
      expect(NetworkMode.testnet.isTestnet, isTrue);
    });

    test('mainnet isTestnet returns false', () {
      expect(NetworkMode.mainnet.isTestnet, isFalse);
    });
  });
}
