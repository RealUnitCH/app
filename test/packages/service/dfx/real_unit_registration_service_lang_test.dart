import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mocktail/mocktail.dart';
import 'package:realunit_wallet/packages/config/api_config.dart';
import 'package:realunit_wallet/packages/config/network_mode.dart';
import 'package:realunit_wallet/packages/repository/cache_repository.dart';
import 'package:realunit_wallet/packages/service/app_store.dart';
import 'package:realunit_wallet/packages/service/dfx/models/country/country.dart';
import 'package:realunit_wallet/packages/service/dfx/models/registration/registration.dart';
import 'package:realunit_wallet/packages/service/dfx/models/registration/registration_user_type.dart';
import 'package:realunit_wallet/packages/service/dfx/real_unit_registration_service.dart';
import 'package:realunit_wallet/packages/service/session_cache.dart';
import 'package:realunit_wallet/packages/service/wallet_service.dart';
import 'package:realunit_wallet/packages/wallet/wallet.dart';
import 'package:realunit_wallet/packages/wallet/wallet_account.dart';
import 'package:web3dart/web3dart.dart';

class _MockAppStore extends Mock implements AppStore {}

class _MockWallet extends Mock implements AWallet {}

class _MockAccount extends Mock implements AWalletAccount {}

class _MockCacheRepository extends Mock implements CacheRepository {}

class _MockWalletService extends Mock implements WalletService {}

const _testPrivateKeyHex = 'fb1ace12f9801e85f3db1b3935dd47d9f064f98152466f47c701b5e12680e612';

final _privKey = EthPrivateKey.fromHex(_testPrivateKeyHex);

/// Audit #657 P9 M2: the registration language was hardcoded to `DE`
/// regardless of the user's app language. `completeRegistration` must accept
/// the caller's language via an optional named `lang` parameter and send it
/// uppercased on the wire; omitting it keeps the previous `DE` behaviour so
/// existing call sites stay valid.
void main() {
  late _MockAppStore appStore;
  late _MockWallet wallet;
  late _MockAccount account;
  late _MockWalletService walletService;
  late SessionCache session;

  setUp(() {
    appStore = _MockAppStore();
    wallet = _MockWallet();
    account = _MockAccount();
    walletService = _MockWalletService();
    session = SessionCache(_MockCacheRepository());
    session.setAuthToken('jwt-1');

    when(() => appStore.apiConfig).thenReturn(const ApiConfig(networkMode: NetworkMode.mainnet));
    when(() => appStore.sessionCache).thenReturn(session);
    when(() => appStore.wallet).thenReturn(wallet);
    when(() => wallet.primaryAccount).thenReturn(account);
    when(() => account.primaryAddress).thenReturn(_privKey);
    when(() => walletService.ensureCurrentWalletUnlocked()).thenAnswer((_) async {});
    when(() => walletService.lockCurrentWallet()).thenAnswer((_) async {});
  });

  RealUnitRegistrationService build(http.Client client) {
    when(() => appStore.httpClient).thenReturn(client);
    return RealUnitRegistrationService(appStore, walletService);
  }

  Registration buildRegistration() => const Registration(
    type: RegistrationUserType.human,
    email: 'a@b.com',
    firstName: 'Ada',
    lastName: 'Lovelace',
    phoneNumber: '+41 79 000 00 00',
    birthday: '1815-12-10',
    nationality: Country(
      id: 41,
      symbol: 'CH',
      name: 'Switzerland',
      kycAllowed: true,
    ),
    addressStreet: 'Bahnhofstrasse',
    addressStreetNumber: '1',
    addressPostalCode: '8000',
    addressCity: 'Zurich',
    addressCountry: Country(
      id: 41,
      symbol: 'CH',
      name: 'Switzerland',
      kycAllowed: true,
    ),
    swissTaxResidence: true,
  );

  Future<Map<String, dynamic>> sentBody(
    Future<void> Function(RealUnitRegistrationService service) act,
  ) async {
    Map<String, dynamic>? body;
    final client = MockClient((request) async {
      body = jsonDecode(request.body) as Map<String, dynamic>;
      return http.Response(jsonEncode({'status': 'completed'}), 201);
    });
    await act(build(client));
    expect(body, isNotNull);
    return body!;
  }

  group('completeRegistration registration language (audit #657 P9 M2)', () {
    test('sends the caller-provided language uppercased (en → EN)', () async {
      final body = await sentBody(
        (service) => service.completeRegistration(buildRegistration(), lang: 'en'),
      );
      expect(body['lang'], 'EN');
    });

    test('sends the caller-provided language uppercased (de → DE)', () async {
      final body = await sentBody(
        (service) => service.completeRegistration(buildRegistration(), lang: 'de'),
      );
      expect(body['lang'], 'DE');
    });

    test('defaults to DE when no language is provided (backward compat)', () async {
      final body = await sentBody(
        (service) => service.completeRegistration(buildRegistration()),
      );
      expect(body['lang'], 'DE');
    });
  });
}
