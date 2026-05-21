import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:realunit_wallet/packages/config/api_config.dart';
import 'package:realunit_wallet/packages/config/network_mode.dart';
import 'package:realunit_wallet/packages/repository/cache_repository.dart';
import 'package:realunit_wallet/packages/service/app_store.dart';
import 'package:realunit_wallet/packages/service/session_cache.dart';
import 'package:realunit_wallet/packages/wallet/wallet.dart';

class _MockCacheRepository extends Mock implements CacheRepository {}

const _testMnemonic =
    'test test test test test test test test test test test junk';

void main() {
  late SessionCache sessionCache;
  late ApiConfig apiConfig;
  late AppStore store;

  setUp(() {
    sessionCache = SessionCache(_MockCacheRepository());
    apiConfig = const ApiConfig(networkMode: NetworkMode.mainnet);
    store = AppStore(() => apiConfig, sessionCache);
  });

  group('$AppStore', () {
    test('wallet getter throws before a wallet has been set', () {
      expect(() => store.wallet, throwsException);
    });

    test('wallet getter returns the wallet once set', () {
      final wallet = SoftwareWallet(1, 'Main', _testMnemonic);

      store.wallet = wallet;

      expect(store.wallet, same(wallet));
    });

    test('primaryAddress proxies the current account address (hex)', () {
      final wallet = SoftwareWallet(1, 'Main', _testMnemonic);
      store.wallet = wallet;

      // Hardhat account #0 derived from the test mnemonic.
      expect(
        store.primaryAddress.toLowerCase(),
        '0xf39fd6e51aad88f6f4ce6ab8827279cfffb92266',
      );
    });

    test('primaryAddress updates when selectAccount changes the current account', () {
      final wallet = SoftwareWallet(1, 'Main', _testMnemonic);
      store.wallet = wallet;
      final firstAddress = store.primaryAddress;

      wallet.selectAccount(1);

      expect(store.primaryAddress, isNot(firstAddress));
    });

    test('apiConfig re-reads from the getter on every access', () {
      var current = const ApiConfig(networkMode: NetworkMode.mainnet);
      final dynamicStore = AppStore(() => current, sessionCache);

      expect(dynamicStore.apiConfig.networkMode, NetworkMode.mainnet);

      current = const ApiConfig(networkMode: NetworkMode.testnet);

      // The getter must not cache — the network can switch at runtime
      // (testnet / mainnet toggle in settings).
      expect(dynamicStore.apiConfig.networkMode, NetworkMode.testnet);
    });

    test('sessionCache is exposed unchanged', () {
      expect(store.sessionCache, same(sessionCache));
    });

    test('isWalletLoaded is false before any wallet is set', () {
      expect(store.isWalletLoaded, isFalse);
    });

    test('isWalletLoaded flips to true once a wallet is set', () {
      expect(store.isWalletLoaded, isFalse);

      store.wallet = SoftwareWallet(1, 'Main', _testMnemonic);

      expect(store.isWalletLoaded, isTrue);
    });
  });
}
